#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/notify-warp.sh"

PAYLOAD_FULL='{"type":"agent-turn-complete","thread-id":"thr_123","turn-id":"turn_123","cwd":"/tmp/project","input-messages":["Implement JWT refresh token rotation and verify with curl"],"last-assistant-message":"Done. Added endpoint, rotation logic, and verified success + revoked token behavior."}'
PAYLOAD_RESPONSE_ONLY='{"type":"agent-turn-complete","input-messages":[],"last-assistant-message":"Completed successfully."}'
PAYLOAD_OTHER='{"type":"other-event","message":"hello"}'

echo "== full payload =="
TERM_PROGRAM=WarpTerminal WARP_NOTIFY_DRY_RUN=1 "$SCRIPT" "$PAYLOAD_FULL" 2>&1

echo "== response only =="
TERM_PROGRAM=WarpTerminal WARP_NOTIFY_DRY_RUN=1 "$SCRIPT" "$PAYLOAD_RESPONSE_ONLY" 2>&1

echo "== other event fallback =="
TERM_PROGRAM=WarpTerminal WARP_NOTIFY_DRY_RUN=1 "$SCRIPT" "$PAYLOAD_OTHER" 2>&1

echo "== non-warp should noop =="
TERM_PROGRAM=iTerm2 WARP_NOTIFY_DRY_RUN=1 "$SCRIPT" "$PAYLOAD_FULL" 2>&1
echo "All tests passed"
