#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_SCRIPT="$REPO_DIR/scripts/notify-warp.sh"
RAW_BASE_DEFAULT="https://raw.githubusercontent.com/yigitkonur/hooks-codex-notify-warp/main"
RAW_BASE="${RAW_BASE:-$RAW_BASE_DEFAULT}"
TARGET_DIR="${HOME}/.codex/hooks"
TARGET_SCRIPT="$TARGET_DIR/notify-warp.sh"
CONFIG_FILE="${HOME}/.codex/config.toml"

WRITE_CONFIG=0
FORCE_WRITE=0

for arg in "$@"; do
  case "$arg" in
    --write-config) WRITE_CONFIG=1 ;;
    --force-write) FORCE_WRITE=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$TARGET_DIR"
if [ -f "$SOURCE_SCRIPT" ]; then
  cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
else
  echo "Local notify script not found; downloading from $RAW_BASE/scripts/notify-warp.sh"
  curl -fsSL "$RAW_BASE/scripts/notify-warp.sh" -o "$TARGET_SCRIPT"
fi
chmod +x "$TARGET_SCRIPT"

echo "Installed: $TARGET_SCRIPT"

desired_line="notify = [\"$TARGET_SCRIPT\"]"

echo ""
echo "Add this to $CONFIG_FILE:"
echo "$desired_line"

if [ "$WRITE_CONFIG" -eq 1 ]; then
  mkdir -p "$(dirname "$CONFIG_FILE")"
  if [ ! -f "$CONFIG_FILE" ]; then
    printf '%s\n' "$desired_line" > "$CONFIG_FILE"
    echo "Created config with notify line."
    exit 0
  fi

  backup="$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CONFIG_FILE" "$backup"
  echo "Backup: $backup"

  if grep -qE '^notify\s*=' "$CONFIG_FILE"; then
    if [ "$FORCE_WRITE" -eq 1 ]; then
      # Replace first notify line only.
      awk -v repl="$desired_line" '
        BEGIN { done=0 }
        {
          if (!done && $0 ~ /^notify[[:space:]]*=/) {
            print repl
            done=1
          } else {
            print $0
          }
        }
      ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      echo "Updated existing notify line."
    else
      echo "notify key already exists; not modifying (use --force-write to replace)."
    fi
  else
    # IMPORTANT: notify MUST be a top-level key, not inside any [section].
    # Codex silently ignores it if nested. Prepend before first section header.
    awk -v line="$desired_line" '
      BEGIN { inserted=0 }
      /^\[/ && !inserted {
        print line
        print ""
        inserted=1
      }
      { print }
      END { if (!inserted) print line }
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "Inserted notify line at top level (before first [section])."
  fi
fi
