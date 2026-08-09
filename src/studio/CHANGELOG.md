# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

## [0.1.0-beta.2] - 2026-08-06

### Changed
- **前后端解耦**：客户端内置 profile 决议标本（assets/data/*.json），离线可用，
  不依赖服务端 API（ResolutionStore 抽象 + AssetResolutionStore 实现；
  服务端对接代码 ResolutionApi 保留，未来恢复即切换注入）
- 移除新建决议入口（本地标本只读）
- 部署流水线移除 API 地址注入，前端独立迭代发布

## [0.1.0-beta.1] - 2026-08-06

首个 beta：功能与 alpha.2 一致（侧边导航 / Markdown 渲染 / 生产 API 注入），
标记功能稳定，进入内测阶段。

## [0.1.0-alpha.2] - 2026-08-06

### Added
- 侧边导航框架（NavigationRail：议题 / 决议 + 内容区），替代首页宫格深推；议题页占位（服务端议题 API 待接入）
- 决议详情 Markdown 渲染（flutter_markdown_plus，种子标本陈述为 Markdown 格式）
- 决议列表元信息展示（分类 Chip + slug）
- 应用标题统一为「量潮议事云」（Linux 窗口 / Web / Android / iOS）

### Changed
- API 地址经 `--dart-define=QTCLOUD_DELIB_API_BASE_URL` 注入，部署流水线读 repo 级变量
- 部署触发改为推送 `studio/*` tag（对齐 provider 模式）

## [0.1.0-alpha.1] - 2026-08-06

### Added
- 初始化 studio 模块（Flutter 客户端，量潮议事云入口）
- 决议管理：决议清单（title/content 摘要）与详情右侧弹窗
- 对接 provider（Go 服务端）：
  - `ResolutionApi` 客户端（GET/POST `/resolutions`），baseUrl 平台自适应（Android 模拟器 `10.0.2.2`，其余 `localhost`，`--dart-define=DELIB_API_BASE_URL` 可覆盖）
  - 决议模型 JSON 序列化（fromJson/toJson）
  - 决议列表服务端加载：加载中 / 失败重试 / 空状态 / 下拉刷新
  - 新建决议（表单校验 + slug 自动生成）
- 平台网络配置：Android INTERNET 权限与明文 HTTP、iOS 本地网络许可
- 测试：API 层单元测试（MockClient）、Widget 测试（替身 API）
