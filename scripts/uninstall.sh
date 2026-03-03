#!/usr/bin/env bash
set -euo pipefail

TARGET_SCRIPT="${HOME}/.codex/hooks/notify-warp.sh"
CONFIG_FILE="${HOME}/.codex/config.toml"

if [ -f "$TARGET_SCRIPT" ]; then
  rm -f "$TARGET_SCRIPT"
  echo "Removed: $TARGET_SCRIPT"
else
  echo "Not found: $TARGET_SCRIPT"
fi

if [ -f "$CONFIG_FILE" ]; then
  backup="$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG_FILE" "$backup"
  sed '/^notify\s*=\s*\[".*notify-warp\.sh"\]/d' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Removed matching notify line from config (backup: $backup)"
fi
