# 贡献指南 · qtcloud-delib provider

量潮议事云提供商服务（`src/provider`，Go 模块）的贡献指南。生产化改造对齐 `qtcloud-pay` provider 架构：GORM 方言切换、领域分包、容器化、IaC。

设计文档导航见 [docs/index.md](docs/index.md)，决议领域设计见 [docs/resolution.md](docs/resolution.md)。

## 核心设计思路

贡献者先理解设计意图，再写代码——以下约束是所有改动的公约数。

### 1. 领域分包

`internal/` 按业务域分模块（当前唯一业务域为 `resolution`），每模块按 `model / repository / service / transport + gorm/` 组织：

```
internal/resolution/
├── model.go               ← 领域模型（含 gorm tag）
├── repository.go          ← 存储接口（方法以 *gorm.DB 为首参）
├── service.go             ← 业务规则（UUID 生成、校验、用例编排）
├── transport.go           ← HTTP handler（Handler.Register(mux) 注册路由）
├── gorm/                  ← Repository 的 GORM 实现（方言切换）
└── seed/                  ← 种子数据导入（云端 GitHub raw，幂等）
```

### 2. 存储双引擎

开发环境 SQLite、生产环境 PostgreSQL，由 GORM 方言切换（`DB_DRIVER` / `DATABASE_URL` / `DB_SQLITE_DSN`）统一调度。**repository 只写一套 GORM 实现**，方言差异由 `app.Open` 启动时选择；迁移用 GORM AutoMigrate；SQLite 单写者限制单连接。

### 3. 事务由编排方开启

repository 方法一律以 `*gorm.DB` 为首参，事务由 service（编排方）开启，实现方不感知。种子导入为单条幂等写入，暂不开事务。

### 4. ID 与业务键分离

决议 `ID` 为服务端生成的 UUID（主键）；`name`（slug）为业务唯一键（uniqueIndex），种子幂等、去重均按 name。

### 5. 模型职责不混层

`internal/resolution/model.go` 是运行时模型（含存储 tag）；工具库 `quanttide-delib-toolkit/packages/go/pkg` 是标本/契约模型。两者字段相同但职责不同：工具库模型不引 gorm，运行时模型不承诺跨仓库稳定。

### 6. 种子数据云端拉取

种子数据（profile 决议标本）从云端 GitHub（raw）拉取，**不依赖本地子模块路径**。`internal/resolution/seed` 幂等导入：按 name 跳过已存在。

## 项目结构

```
src/provider/
├── cmd/
│   ├── server/             ← 组装依赖，启动服务（优雅关闭）
│   └── seed/               ← 种子数据导入入口
├── internal/
│   ├── resolution/         ← 决议领域（model/repository/service/transport + gorm/ + seed/）
│   ├── httpserver/         ← 统一 JSON 响应工具
│   ├── app/                ← 装配：Open/OpenDB/BuildMux
│   └── store/              ← 测试替身（内存 ResolutionRepo，不演进为生产存储）
├── docs/                   ← 设计文档（index.md 导航 + resolution.md）
├── manifests/terraform/    ← 部署 IaC（app 级，对齐 qtcloud-pay）
├── .github/workflows/       ← CI（ci.yml 测试 + deploy-provider.yml 部署）
├── go.mod / go.sum
├── Makefile
├── Dockerfile / docker-compose.yml
├── CHANGELOG.md
└── README.md
```

## 配置

配置通过环境变量注入，由 `cmd/server/main.go` 加载：

| 变量 | 用途 |
|------|------|
| `DB_DRIVER` / `DATABASE_URL` / `DB_SQLITE_DSN` | 存储方言：开发默认 SQLite（`qtcloud-delib.db`），生产 `postgres` + 连接串 |
| `LISTEN_ADDR` | HTTP 监听地址（默认 `:8080`） |

## 运行测试

```bash
# Go 单元测试（模块根）
go test ./...

# 静态检查
go vet ./...
gofmt -l .        # 应无输出
golangci-lint run ./...   # 需安装 golangci-lint

# 本地运行与容器
make run
make docker-up
```

## 提交规范

- 提交信息格式：`feat(provider): ...` / `fix(provider): ...` / `docs(provider): ...` / `refactor(provider): ...` / `chore(provider): ...`
- 提交前：`go test ./...`、`go vet ./...`、gofmt 无差异；核对 ROADMAP 相关条目状态与 CHANGELOG
- 本地双绿（test + vet/fmt + golangci-lint）约等于 CI 绿；CI 失败后先查是 fmt 差异还是逻辑错误
- 分层提交：子模块内提交推送 → 回到父仓库更新指针 → 提交推送（子模块独立维护，禁止在父仓库直接改子模块文件）
