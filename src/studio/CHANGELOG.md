# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

## [0.1.0-rc.1] - 2026-08-11

### Added
- **绑定账号系统**（qtcloud-auth 统一认证）：登录页 + JWT 本地存储 + 请求带 Authorization
- 数据源切换：登录后经网关读后端决议（ApiResolutionStore）；未登录显示登录页
- 恢复新建决议入口（登录态写入后端，只读数据源提示）

### Changed
- 认证服务地址经 `--dart-define=QTCLOUD_AUTH_BASE_URL` 注入（生产=api.quanttide.com 网关）

## [0.1.0-beta.5] - 2026-08-09

### Fixed
- 撤销误发的 beta.4（并行会话基于旧 base 构建，覆盖了缓存策略修复）：
  本版基于最新 main（AssetResolutionStore 前后端解耦 + 入口 no-cache 缓存策略），
  重新部署恢复正确状态

## [0.1.0-beta.3] - 2026-08-09

### Fixed
- 部署缓存策略：入口文件（index.html / bootstrap / service worker / manifest）
  no-cache，仅哈希产物长缓存——修复发布后浏览器/Service Worker 缓存旧入口
  导致看不到新版本的问题

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
