# provider ROADMAP

按版本组织，只列直接需要落实到代码的事项。权威路线图见[域级路线图](../../../data/roadmap/)。

## v0.1.0 决议领域 MVP（已交付 2026-08-04）

- 决议领域模型 `Resolution`（id UUID / name slug / title / content / category）
- HTTP 端点：`GET /resolutions`、`POST /resolutions`
- 分层骨架：`cmd/server` + `internal/{api,app,model,store}`
- 存储：内存实现（`Storer` 接口 + `MemoryStore`），可替换

## 生产化改造（计划）

对齐 `qtcloud-pay` provider 架构（GORM 方言切换、领域分包、容器化、IaC）。

### P0 数据层：PostgreSQL（GORM）

| # | 优先级 | 任务 | 落点 | 状态 |
|---|--------|------|------|------|
| D1 | P0 | 引入 GORM + postgres/sqlite 驱动（开发 SQLite / 生产 PostgreSQL 方言切换） | `go.mod`：`gorm.io/gorm`、`gorm.io/driver/postgres`、`gorm.io/driver/sqlite` | 未开始 |
| D2 | P0 | `model.Resolution` 补 gorm tag（primaryKey、comment 等） | `internal/resolution/model.go` | 未开始 |
| D3 | P0 | 存储重构为 Repository 模式：接口 + gorm 实现（方法以 `*gorm.DB` 为首参，事务由调用方编排） | `internal/resolution/repository.go`、`internal/resolution/gorm/resolution_repo.go`；删除 `internal/store` | 未开始 |
| D4 | P0 | `app.Open(driver, dsn)`：方言切换 + `AutoMigrate` + SQLite 单连接限制；`OpenDB()` 读 `DB_DRIVER` / `DATABASE_URL` / `DB_SQLITE_DSN` | `internal/app/app.go` | 未开始 |

### P1 分层重构：按领域分包

| # | 优先级 | 任务 | 落点 | 状态 |
|---|--------|------|------|------|
| L1 | P1 | 决议领域分包：model / repository / service / transport（`Register(mux)` 注册） | `internal/resolution/`；删除 `internal/api` 混合结构，响应工具移 `internal/httpserver/response.go` | 未开始 |
| L2 | P1 | `app.BuildMux(db)` 依赖注入，cmd/server 与集成测试共用装配 | `internal/app/app.go`、`cmd/server/main.go` | 未开始 |
| L3 | P1 | service 层业务逻辑与单测（对齐 pay `service_test.go` 模式） | `internal/resolution/service.go` | 未开始 |

### P1 容器化

| # | 优先级 | 任务 | 落点 | 状态 |
|---|--------|------|------|------|
| C1 | P1 | Dockerfile：多阶段构建（golang:1.26-alpine + gcc/musl-dev，sqlite CGO）+ alpine 运行 + 非 root + EXPOSE 8080 | `src/provider/Dockerfile` | 未开始 |
| C2 | P1 | docker-compose.yml：本地一键起（sqlite 挂载 ./data；或 postgres 服务） | `src/provider/docker-compose.yml` | 未开始 |
| C3 | P1 | .dockerignore、provider 级 .gitignore（bin/、data/） | `src/provider/.dockerignore`、`.gitignore` | 未开始 |
| C4 | P1 | Makefile：build / run / test / vet / lint / docker-build / docker-up / docker-down / clean | `src/provider/Makefile` | 未开始 |

### P2 IaC：manifests/terraform（阿里云 FC + RDS Serverless）

| # | 优先级 | 任务 | 落点 | 状态 |
|---|--------|------|------|------|
| T1 | P2 | 部署选型文档：RDS Serverless（PostgreSQL）+ FC 3.0 custom-container（VPC 内网）+ API 网关系统级预留 | `manifests/terraform/README.md` | 未开始 |
| T2 | P2 | Terraform 基础：versions / providers（OSS 远端 state）/ locals / variables / tfvars(.example) | `manifests/terraform/*.tf` | 未开始 |
| T3 | P2 | 应用数据库与账号（`qtcloud_delib`，DBOwner） | `manifests/terraform/rds.tf` | 未开始 |
| T4 | P2 | FC 函数 + HTTP 触发器 + 环境变量（`DB_DRIVER=postgres` / `DATABASE_URL`，密码经密钥管理注入） | `manifests/terraform/fc.tf` | 未开始 |

### P3 工程配套

| # | 优先级 | 任务 | 落点 | 状态 |
|---|--------|------|------|------|
| E1 | P3 | 决议领域 API 文档 | `src/provider/docs/index.md`、`docs/resolution.md` | 未开始 |
| E2 | P3 | go.mod 通过 replace 引用 `quanttide-delib-toolkit`（对齐 pay） | `src/provider/go.mod` | 未开始 |
| E3 | P3 | AGENTS.md / CONTRIBUTING.md（对齐 pay 工程约定） | `src/provider/` | 未开始 |

## 待定决策

- **鉴权方案**：决议 API 当前无认证；生产前须确定应用层鉴权（对齐 pay F1：网关接入前先应用层鉴权），影响 BuildMux 挂载中间件
- **迁移路径**：MemoryStore → GORM 切换时，`internal/store` 是删除还是保留为测试替身（决定 D3 删留）
- **决议数据来源**：profile 决议标本（`data/profile/resolutions/*.json`）是否作为 provider 种子数据导入（决定是否加 seed 逻辑）
