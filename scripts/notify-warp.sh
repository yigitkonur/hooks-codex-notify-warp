#!/usr/bin/env bash
# Codex notify hook -> Warp notification (OSC 777)
# Expected invocation by Codex:
#   notify = ["/absolute/path/to/notify-warp.sh"]
# Codex appends a JSON payload as the final argv argument.

set -u

TITLE_DEFAULT="Codex"
MSG_DEFAULT="Task completed"

truncate_text() {
  local text="$1"
  local max_len="$2"
  if [ "${#text}" -gt "$max_len" ]; then
    printf '%s' "${text:0:$((max_len-3))}..."
  else
    printf '%s' "$text"
  fi
}

is_warp_terminal() {
  [ "${TERM_PROGRAM:-}" = "WarpTerminal" ]
}

send_warp_notification() {
  local title="$1"
  local body="$2"

  if [ "${WARP_NOTIFY_DRY_RUN:-0}" = "1" ]; then
    # Write to stderr — stdout corrupts Codex TUI
    printf 'DRY_RUN title=%s\n' "$title" >&2
    printf 'DRY_RUN body=%s\n' "$body" >&2
    return 0
  fi

  # Write directly to /dev/tty — the `tty` command fails in Codex's
  # fire-and-forget child processes (stdin not connected), but /dev/tty
  # always refers to the controlling terminal.
  # OSC 777: \033]777;notify;<title>;<body>\007
  printf '\033]777;notify;%s;%s\007' "$title" "$body" > /dev/tty 2>/dev/null || true
}

build_message_from_payload() {
  local payload="$1"

  if [ -z "$payload" ]; then
    printf '%s' "$MSG_DEFAULT"
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf '%s' "$MSG_DEFAULT"
    return 0
  fi

  local event_type prompt response msg
  event_type="$(printf '%s' "$payload" | jq -r '.type // empty' 2>/dev/null || true)"

  # Codex legacy notify payload is expected to be: type=agent-turn-complete
  if [ "$event_type" != "agent-turn-complete" ]; then
    printf '%s' "$MSG_DEFAULT"
    return 0
  fi

  prompt="$(printf '%s' "$payload" | jq -r '.["input-messages"][0] // empty' 2>/dev/null || true)"
  response="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // empty' 2>/dev/null || true)"

  prompt="${prompt//$'\n'/ }"
  response="${response//$'\n'/ }"

  if [ -n "$prompt" ] && [ -n "$response" ]; then
    prompt="$(truncate_text "$prompt" 60)"
    response="$(truncate_text "$response" 140)"
    msg="\"$prompt\" → $response"
  elif [ -n "$response" ]; then
    msg="$(truncate_text "$response" 180)"
  elif [ -n "$prompt" ]; then
    msg="$(truncate_text "$prompt" 180)"
  else
    msg="$MSG_DEFAULT"
  fi

  printf '%s' "$msg"
}

main() {
  # Codex appends one JSON argument; use final arg defensively.
  local payload="${*: -1}"

  if ! is_warp_terminal && [ "${WARP_NOTIFY_FORCE:-0}" != "1" ]; then
    exit 0
  fi

  local title message
  title="${WARP_NOTIFY_TITLE:-$TITLE_DEFAULT}"
  message="$(build_message_from_payload "$payload")"

  send_warp_notification "$title" "$message"
}

main "$@"
