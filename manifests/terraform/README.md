# qtcloud-delib 部署选型（IaC）

对齐 qtcloud-pay 的部署决策（系统级资源由 quanttide-platform 管理），作为 Terraform 基础设施代码的设计依据。

## 部署选型

| 维度 | 选型 | 说明 |
|------|------|------|
| 数据库 | 阿里云 RDS Serverless（PostgreSQL） | 与 provider 技术方案一致（开发 SQLite / 生产 PostgreSQL，GORM 方言切换）；Serverless 免运维、按需扩缩 |
| 服务计算 | FaaS（函数计算 FC 3.0）+ custom-container | Dockerfile 构建镜像，双通道发布（Docker Hub 对外分发 + 阿里云 ACR 同地域直拉）；服务无需常驻、按调用计费 |
| 存储与网络 | 随计算/数据库一并解决 | VPC 内网互通（RDS ↔ FC） |
| API 网关 | **预留（系统层面统一规划）** | 统一 `api.quanttide.com`，路径按应用名（如 `/qtcloud-delib`）；不在本应用 IaC 范围内，由系统级网关统一接入 |

## 本 IaC 范围

- **系统级共享**（quanttide 体系统一管理，`quanttide-<env>` 命名）：VPC / 交换机 / 安全组、RDS 实例
- **应用级**（`qtcloud-delib-<env>` 命名）：数据库与账号（`qtcloud_delib`，DBOwner）、FC 函数与默认角色
- **静态网站**（studio 客户端）：OSS 桶 `qtcloud-delib-studio`（静态托管 + 公共读，`studio.tf`）；CDN 域名 `delib.cloud.quanttide.com` 与 DNS/证书在控制台配置（无组织级 CDN IaC 先例，对齐 qtdata-studio 模式，见 quanttide-platform `docs/dev-guide/iac/websites.md`）
- **不含** API 网关、域名、DNS（系统层面预留）

## studio 静态网站部署

- 基础设施：`terraform apply`（`studio.tf`：桶 + 静态托管 + 公共读；注意首次需关闭该桶"阻止公共访问"，见 issue 记录）
- 构建上传：`.github/workflows/deploy-studio.yml`（Release `studio/*` 触发 → flutter build web → ossutil cp → 刷新 CDN）
- 证书：acme.sh 泛域名证书（`scripts/deploy-studio-cert.py` 绑定 CDN，续期后重跑）

## 使用
## 安全说明

- **鉴权**：决议 API 维持无认证（已确认决策），生产接入 API 网关时再评估
- **密钥**：`db_password` 通过 `TF_VAR_db_password` 或 terraform.tfvars 注入，**不入库**（tfvars.example 只给占位值）；当前 FC 环境变量携带明文密码并落入 tfstate，后续迁移密钥管理（FC 配置中心/云 Secret Manager）

## 待办

- [x] 按此方案设计 Terraform（IaC）：VPC + RDS Serverless + FC 服务（对齐 qtcloud-pay）
- [x] state 迁移到 OSS 远端后端（`quanttide-terraform-state`，init 需带 `-backend-config`）
- [x] Dockerfile 已就绪（多阶段构建 + 非 root）；镜像发布 `quanttide/qtcloud-delib-provider`，deploy-provider workflow（`.github/workflows/`）已就绪：tag `provider/*` 触发，双通道发布（Docker Hub + ACR）后 Terraform apply
- [ ] 环境划分（dev / prod）与配置管理（`DB_DRIVER` / `DATABASE_URL` 等，对齐 provider 技术方案）
- [ ] 密码经密钥管理注入（FC 配置中心/Secret Manager），避免明文落 tfstate
- [ ] API 网关统一接入 `api.quanttide.com/qtcloud-delib`（系统层面预留，另行规划）

## 使用

```sh
terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-delib/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
