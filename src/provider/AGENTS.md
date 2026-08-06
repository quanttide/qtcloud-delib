# AGENTS（qtcloud-delib · src/provider）

面向在 provider（Go 模块）内工作的编码 agent 的指令。**动手前先读「关键文件」**；上级纪律见仓库根 [AGENTS.md](../../../AGENTS.md) 与 [CONTRIBUTING.md](../../../CONTRIBUTING.md)。

## 本 scope 是什么

量潮议事云服务端（Go）：决议领域（模型/存储/服务/传输）。`internal/` 按业务域分模块，`internal/resolution` 是唯一业务域，存储走 Repository + GORM 双引擎（开发 SQLite / 生产 PostgreSQL）。

## 关键文件（按优先级阅读）

| 文件 | 作用 | 何时必读 |
|------|------|----------|
| `README.md` | 结构、API、运行方式 | 每次工作前 |
| `CONTRIBUTING.md` | 核心设计思路、模块分层 | 每次改代码前 |
| `ROADMAP.md` | 生产化改造计划（数据层/分包/容器化/IaC/工程配套） | 改代码前核对相关条目 |
| `docs/index.md` | 文档导航与模块总览 | 定位模块文档 |
| `docs/resolution.md` | 决议领域设计 | 改 resolution 模块前 |
| `Makefile` | `make build/test/vet/lint/run/clean/docker-*` | 构建测试时 |
| `CHANGELOG.md` | 版本变更记录 | 提交前核对 |
| `cmd/server/main.go` | 依赖组装、方言选择、AutoMigrate | 新增模块时 |
| `manifests/terraform/` | 部署 IaC（app 级，对齐 qtcloud-pay） | 部署相关改动时 |
| `.github/workflows/` | CI（ci.yml 测试/静态检查 + deploy-provider.yml 部署） | 流水线改动时 |
| 工具库 `packages/quanttide-delib-toolkit/packages/go/pkg` | 决议标本模型（seed 解析用） | 涉及标本数据时 |

## 契约纪律（最高优先级）

1. **模型单一事实源**：`internal/resolution/model.go` 是运行时模型（含 gorm tag）；工具库 `pkg` 是标本/契约模型（无存储关注点）。领域模型不搬进工具库，工具库不引存储
2. **存储只走 Repository**：读写经 `internal/resolution` 的 Repository 接口 + `gorm/` 实现；`internal/store` 仅保留为测试替身，不再演进为生产存储
3. **事务由 service 编排**：repository 方法一律以 `*gorm.DB` 为首参，不在 repository 内开事务
4. **ID 语义**：决议 ID 为 UUID（服务端生成）；`name`（slug）为业务唯一键，种子幂等按 name 判断

## 已知状态（动手前核对 ROADMAP）

- P0 数据层（GORM/repository/app.Open）✅ 已完成
- P1 分包与容器化 ✅ 已完成；P2 IaC 已完成（本地仅 fmt/validate，plan/apply 需云凭证）
- P3 工程配套：文档/工具库引用/AGENTS/种子 ✅ 已完成
- CI：ci.yml（test/vet/fmt/lint + terraform 校验）+ deploy-provider.yml（tag 触发双通道镜像 + apply）✅ 已完成
  - 注意：replace 依赖域级工具库，ci.yml 按域仓库布局 checkout（apps/qtcloud-delib + packages/quanttide-delib-toolkit）；镜像构建只编 ./cmd/server 无需工具库
- 待定：鉴权（决议 API 无认证，生产接 API 网关时评估）；RDS 密码密钥管理注入（当前明文落 tfstate，见 README 待办）

## 验证

```bash
go test ./... && go vet ./... && gofmt -l .   # 模块根运行
terraform fmt -check manifests/terraform      # IaC 改动后（app 级目录）
```

提交前核对：ROADMAP 相关条目状态、CHANGELOG 是否需更新、测试通过。
