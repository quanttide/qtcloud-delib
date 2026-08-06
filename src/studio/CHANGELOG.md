# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

---

## [Unreleased]

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
