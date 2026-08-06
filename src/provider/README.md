# provider · 议事提供者

议事提供者模块，封装量潮议事云核心业务逻辑，支持决议管理，后续扩展议题、会议、档案等资源。

## 包结构

| 包 | 说明 |
|---|------|
| [`cmd/server`](./cmd/server/) | 服务入口：装配数据库、路由与启动（优雅关闭） |
| [`cmd/seed`](./cmd/seed/) | 种子数据导入入口（云端 GitHub 拉取） |
| [`internal/resolution`](./internal/resolution/) | 决议领域：模型、Repository 接口、Service、transport（含 `gorm/` 实现与 `seed/`） |
| [`internal/app`](./internal/app/) | 应用装配：`Open`/`OpenDB`（方言切换 + AutoMigrate）、`BuildMux`（依赖注入） |
| [`internal/httpserver`](./internal/httpserver/) | 统一 JSON 响应工具 |
| [`internal/store`](./internal/store/) | 存储测试替身（MVP 遗留，不演进为生产存储） |

## 决议领域

| 组件 | 说明 |
|------|------|
| 模型 | `Resolution`：`id`（UUID）/ `name`（slug，业务唯一键）/ `title` / `content` / `category` |
| 存储 | Repository 接口 + GORM 实现（开发 SQLite / 生产 PostgreSQL 方言切换） |
| 服务 | `Create`（UUID 生成、name/title 校验）、`List`（按 name 排序） |
| HTTP | `GET /resolutions`、`POST /resolutions`（经 `Handler.Register(mux)` 注册） |

## 运行

```sh
# 本地（SQLite，库文件 qtcloud-delib.db）
make run

# Docker 一键起（SQLite 挂载 ./data）
make docker-up

# 种子数据：导入 profile 决议标本（云端 GitHub 拉取，幂等）
go run ./cmd/seed

# 构建与测试
make build
make test && make vet
```

配置经环境变量注入：`DB_DRIVER`（sqlite/postgres）、`DATABASE_URL`、`DB_SQLITE_DSN`、`LISTEN_ADDR`。

## 模块路径

```
github.com/quanttide/qtcloud-delib-provider
```

工具库经 go.mod `replace` 引用 `quanttide-delib-toolkit`（标本模型，seed 解析用）。

## 部署

生产部署走阿里云 FC 3.0 custom-container + RDS Serverless（PostgreSQL），IaC 见 [`manifests/terraform`](../../../manifests/terraform/)（app 级，对齐 qtcloud-pay）。

CI（`.github/workflows/`）：

- `ci.yml`：push main / PR 触发，provider 单测/静态检查/格式/lint + IaC 校验
- `deploy-provider.yml`：推送 tag `provider/*` 触发——镜像双通道发布（Docker Hub + ACR）后 Terraform apply 部署

## 许可

Apache 2.0 — 见项目根目录 [LICENSE](../../../LICENSE)。
