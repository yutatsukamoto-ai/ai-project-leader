#!/usr/bin/env bash
# 後方互換ラッパー。実体は build.sh に統合済み（2026-06-15）。
#   bash _tools/sync.sh check  →  build.sh --check
#   bash _tools/sync.sh sync   →  build.sh --sync
#   bash _tools/sync.sh        →  build.sh --check（引数なしはcheck）
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${1:-check}"
case "$MODE" in
  check) exec bash "$HERE/build.sh" --check ;;
  sync)  exec bash "$HERE/build.sh" --sync ;;
  *)     echo "usage: bash _tools/sync.sh [check|sync]" >&2; exit 2 ;;
esac
