# 决议领域（resolution）

决议是议事产出的核心载体：决策记录。本模块提供决议的存储、服务与 HTTP 端点。

## 模型

```go
type Resolution struct {
    ID       string // UUID，主键
    Name     string // 决议标识（slug，取自文件名），唯一索引
    Title    string // 概括"决定了什么"
    Content  string // 决议陈述（纯文本，预留结构化扩展）
    Category string // 决议分类（治理、审计、档案、技术等）
}
```

结构从实际议事档案标本（`quanttide-profile-of-deliberation`）中长出，不预设执行字段。

## 存储

Repository 接口（`repository.go`），方法以 `*gorm.DB` 为首参、事务由调用方编排：

```go
type Repository interface {
    List(db *gorm.DB) ([]Resolution, error)          // 按 name 排序
    Get(db *gorm.DB, id string) (*Resolution, error) // 不存在返回 gorm.ErrRecordNotFound
    GetByName(db *gorm.DB, name string) (*Resolution, error)
    Create(db *gorm.DB, r *Resolution) error
}
```

GORM 实现位于 `gorm/`（开发 SQLite / 生产 PostgreSQL，方言由 `app.Open` 启动时选择，迁移用 AutoMigrate）。`internal/store` 保留内存实现作为测试替身。

## 服务

`Service` 是业务规则的唯一入口：

- `Create`：`name` / `title` 必填（去空格校验）；`ID` 为空时生成 UUID；写入失败（如 name 冲突）向上返回错误
- `List`：按 name 排序的决议清单

## HTTP 端点

| 方法 | 路径 | 说明 | 成功响应 |
|------|------|------|----------|
| GET | `/resolutions` | 决议清单 | `200 {"resolutions": [...]}` |
| POST | `/resolutions` | 创建决议 | `201` 创建的决议 |

错误统一为 `{"error": "..."}`：入参不合法 `400`，服务端错误 `500`。

路由经 `Handler.Register(mux)` 注册，由 `app.BuildMux` 统一装配。

## 种子数据

`seed` 子包从云端 GitHub（raw）拉取 profile 决议标本（`resolutions/*.json`）幂等导入：按 `name` 已存在则同步更新（title/content/category，ID 不变），不存在则新增。数据源默认：

- 清单：GitHub contents API（`quanttide-profile-of-deliberation/resolutions` 目录）
- 内容：`raw.githubusercontent.com` 对应目录的 JSON 文件

不使用本地子模块路径，避免运行时依赖子模块 checkout 状态。
