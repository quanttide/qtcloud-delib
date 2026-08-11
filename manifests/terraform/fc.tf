# FC 默认角色：允许 FC 服务挂载弹性网卡访问 VPC（应用级）
resource "alicloud_ram_role" "fc" {
  role_name                   = "${local.app_name_prefix}-fc"
  assume_role_policy_document = <<EOF
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["fc.aliyuncs.com"]
      }
    }
  ],
  "Version": "1"
}
EOF
  description                 = "Function Compute 默认角色（qtcloud-delib）"
}

resource "alicloud_ram_role_policy_attachment" "fc_vpc" {
  policy_name = "AliyunECSNetworkInterfaceManagementAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc.role_name
}

# 函数计算（FC 3.0）：custom-container 容器镜像，VPC 内网访问 RDS（应用级）
resource "alicloud_fcv3_function" "this" {
  function_name     = local.app_name_prefix
  description       = "qtcloud-delib 决议 API"
  runtime           = "custom-container"
  handler           = "index.handler" # custom-container 必填占位，实际由容器监听端口决定
  cpu               = 0.5
  memory_size       = var.fc_memory
  disk_size         = 512 # FC 3.0 必填（MB）
  timeout           = var.fc_timeout
  internet_access   = true
  role              = alicloud_ram_role.fc.arn
  resource_group_id = data.terraform_remote_state.platform.outputs.resource_group_id

  vpc_config {
    vpc_id            = data.terraform_remote_state.platform.outputs.vpc_id
    vswitch_ids       = [data.terraform_remote_state.platform.outputs.vswitch_id]
    security_group_id = data.terraform_remote_state.platform.outputs.security_group_id
  }

  custom_container_config {
    image = var.image
    port  = 8080
  }

  # 对齐 provider 运行时约定：DB_DRIVER=postgres + DATABASE_URL（见 internal/app/app.go）
  # 注意：密码会以明文落入 tfstate。规划经 FC 配置中心/密钥管理注入（见 README 待办），
  # 当前平台密钥管理未就绪，先沿用环境变量方式（与 qtcloud-pay 一致）
  environment_variables = {
    DB_DRIVER    = "postgres"
    DATABASE_URL = "postgres://${alicloud_db_account.this.account_name}:${var.db_password}@${data.terraform_remote_state.platform.outputs.rds_connection_string}:${data.terraform_remote_state.platform.outputs.rds_port}/${alicloud_db_database.this.data_base_name}?sslmode=disable"
    JWT_PUBLIC_KEY = "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFuYlk5MWNDdzVtd05KMFZINnErZgpVdjFocEIyZzUwczZHVGJyM1pkYTdES3dkdFhrcUlTUCt2bll2SGJwYU5kUFdvUVR2UjZXOHVYQVZ4VjhuMEVPCnhTMUt3TGVTN2xKRHZ6MitVR3VDYXRVbC81OCtGUnFPS2tITFFGcWtzM0xaUW1YMlg0dUFsMDM0djAxMVBrWEgKVFlxNHlVMTRqYnhWdnpzbDhjaGpKemRNYlgyRGVnN3U4VDBNdm5naFhmWWMvMnJkUTV5SjBMUUlwb3o1VjlEawpnMHNwcWtMMnRxZ2FwNHFBRU93YW5QeGxXS3JSTkhZQ3VSNUVZNFNGVS9ScjgwRkVkWmFJMVUvTzAvVURVdmYvClJ5VGFjeGpQUTdackN5Z25aWTk3Z0drbUR6eEFOWjMzT0w1KzhhRGw4V1Bha0Rza0xLYkNjVytKMEZkeUU1NjAKQlFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg=="
  }

  tags = {
    project     = var.project
    environment = var.environment
  }
}

# HTTP 触发器：使服务可直接访问（后续由系统级 API 网关统一接入，此触发器保留为直连通道）
resource "alicloud_fcv3_trigger" "http" {
  function_name = alicloud_fcv3_function.this.function_name
  trigger_name  = "http"
  trigger_type  = "http"
  qualifier     = "LATEST"
  trigger_config = jsonencode({
    authType = "anonymous"
    methods  = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
  })
}
