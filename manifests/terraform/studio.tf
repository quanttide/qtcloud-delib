# studio 客户端静态网站托管（IaC）
#
# 桶 qtcloud-delib-studio：命名对齐站点规范 {repo}-{type}（如 qtdata-studio / qtweb-site）。
# 部署流水线：.github/workflows/deploy-studio.yml（Release 触发 → flutter build web → ossutil cp → 刷新 CDN）。
# CDN 域名 delib.cloud.quanttide.com 与泛域名证书（*.quanttide.com）在控制台配置
# （暂无组织级 CDN IaC 先例，托管规范见 quanttide-platform docs/dev-guide/iac/websites.md）。

resource "alicloud_oss_bucket" "studio" {
  bucket = "qtcloud-delib-studio"

  # 静态网站托管（Flutter Web 产物，入口 index.html）
  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# 与 qtdata-studio 一致：先公共读上线；配好 CDN 回源鉴权后可改回 private
resource "alicloud_oss_bucket_acl" "studio" {
  bucket = alicloud_oss_bucket.studio.bucket
  acl    = "public-read"
}
