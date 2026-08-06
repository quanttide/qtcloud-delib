# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

## [0.1.0-alpha.1] - 2026-08-06

### Added
- 生产化改造（对齐 qtcloud-pay provider 架构）：
  - 数据层：GORM + Repository 模式（开发 SQLite / 生产 PostgreSQL 方言切换），`internal/store` 保留为测试替身
  - 决议领域分包：`internal/resolution`（model / repository / service / transport + `gorm/`），删除 `internal/api` 混合结构
  - `app.Open` / `OpenDB` / `BuildMux` 装配，cmd/server 优雅关闭
  - 容器化：Dockerfile（多阶段 + 非 root）、docker-compose、Makefile、.dockerignore/.gitignore
  - IaC：`manifests/terraform`（阿里云 FC 3.0 + RDS Serverless，系统级资源引用 quanttide-platform）
  - 工程配套：docs（index/resolution）、go.mod replace 引用 quanttide-delib-toolkit、AGENTS.md/CONTRIBUTING.md、种子数据导入（云端 GitHub raw，幂等）
  - CI：`ci.yml`（test/vet/fmt/lint + terraform fmt/validate）+ `deploy-provider.yml`（tag 触发：镜像 Docker Hub + ACR 双通道 + Terraform apply）

## [0.1.0] - 2026-08-04

### Added
- 初始化 provider 模块（cmd/server、internal/api、model、store、app）
- 决议模型与决议 HTTP 端点（GET/POST /resolutions）
