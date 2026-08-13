#!/usr/bin/env bash
# 同步域仓库 profile 决议标本到客户端 assets/data/
#
# 客户端已改为内置标本数据（前后端解耦，离线可用）；profile 数据更新时
# 运行本脚本并提交，再发布新版本即可。
#
# 用法：bash scripts/sync-profile.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 域仓库根：qtcloud-delib/src/studio/scripts → 上溯 5 级（scripts→studio→src→qtcloud-delib→apps→域仓库根）
DOMAIN_ROOT="$(cd "${SCRIPT_DIR}/../../../../../" && pwd)"
SRC="${DOMAIN_ROOT}/data/profile/resolutions"
DEST="${SCRIPT_DIR}/../assets/data"

if [ ! -d "${SRC}" ]; then
  echo "错误：未找到 profile 标本目录 ${SRC}（需先 checkout 域仓库 data/profile 子模块）" >&2
  exit 1
fi

mkdir -p "${DEST}"
cp "${SRC}"/*.json "${DEST}"/

echo "已同步 $(ls "${DEST}"/*.json | wc -l | tr -d ' ') 个标本 → ${DEST}"
