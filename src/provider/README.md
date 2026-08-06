# provider · 议事提供者

议事提供者模块，封装量潮议事云核心业务逻辑，支持决议管理，后续扩展议题、会议、档案等资源。

## 包结构

| 包 | 说明 |
|---|------|
| [`cmd/server`](./cmd/server/) | 服务入口：装配存储、处理器、路由与启动 |
| [`internal/model`](./internal/model/) | 领域模型：`Resolution` |
| [`internal/api`](./internal/api/)  | HTTP 端点：决议清单、创建决议、统一响应 |
| [`internal/store`](./internal/store/) | 存储抽象：`Storer` 接口与内存实现 |
| [`internal/app`](./internal/app/) | 应用层装配（预留） |

## model — 数据模型

| 类型 | 字段 |
|------|------|
| `Resolution` | `id`, `title`, `description` |

决议是决策记录：`title` 概括"决定了什么"，`description` 展开决议陈述。

## api — HTTP 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/resolutions` | 决议清单 |
| POST | `/resolutions` | 创建决议 |

## Storer 接口

```go
type Storer interface {
    List(collection string) ([]byte, error)
    Create(collection string, data []byte) (string, error)
    Get(collection string, id string) ([]byte, error)
    Update(collection string, id string, data []byte) error
}
```

`ResolutionHandler` 依赖 `Storer` 接口实现持久化，可对接任意存储后端（内存、文件、数据库等）。

## 模块路径

```
github.com/quanttide/qtcloud-delib-provider
```

## 许可

Apache 2.0 — 见项目根目录 [LICENSE](../../../LICENSE)。
