# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

版本遵循语义化版本规范：0.0.x（探索期）→ 0.x.y（验证期）→ x.y.z（正式期）

---

## [Unreleased]

## [0.1.0-alpha.1] - 2026-08-06

### Added
- 初始化 CLI 骨架：`--help` / `--version`
- 对接 provider（Go 服务端）决议 API：
  - `resolutions list`：`GET /resolutions` 决议清单（支持 `--json` 输出）
  - `resolutions create`：`POST /resolutions` 创建决议（name/title 必填，`--content` / `--category` 可选）
  - 服务端地址默认 `http://localhost:8080`，支持 `--server` 或环境变量 `DELIB_API_BASE_URL` 覆盖（与 studio 客户端对齐）
  - 错误透传：服务端 `{"error": "..."}` 信息与 HTTP 状态码，非零退出码
