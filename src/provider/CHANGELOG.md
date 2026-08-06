# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

## [0.1.0-beta.1] - 2026-08-06

### Added
- 唯一键冲突映射 `409 Conflict`：重复 `name` 创建返回 `name already exists`（此前为 500）

## [0.1.0-alpha.5] - 2026-08-06

### Changed
- 种子导入幂等增强：已存在按 name 同步更新（title/content/category，ID 不变），本地重复导入可同步云端标本演进

### Removed
- 生产种子导入自动化（POST /seed 端点、SEED_TOKEN、流水线 Seed 步骤）——生产数据在部署成功后手动上传，seed 仅用于本地开发（cmd/seed）
- deploy workflow 的 workflow_dispatch 手动触发入口（仅保留 tag 触发）

## [0.1.0-alpha.4] - 2026-08-06

### Fixed
- deploy 首次部署：RDS 唤醒不再依赖本地 state，按命名（`quanttide-<env>`）查询平台共享实例并触发启动（实例已存在，无需创建）

## [0.1.0-alpha.3] - 2026-08-06

### Fixed
- deploy 首次部署：本地 state 无 platform 记录时跳过 RDS 唤醒（此前 INSTANCE_ID 为空导致 StartDBInstance 报 MissingParameter，apply 无法执行）

## [0.1.0-alpha.2] - 2026-08-06

### Fixed
- CI 与镜像构建链路：`quanttide-delib-toolkit` 云端补齐 `packages/go`（此前未推送，replace 目录不存在）；镜像构建上下文改为域根布局（app + toolkit 同 context，`go mod download` 可解析 replace）
- golangci-lint 升级 v2.12.2（v1.64.x 二进制用 go1.24 构建，拒绝 go.mod 的 go 1.26），修复 errcheck 告警

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
