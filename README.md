Codex turn-complete notifications in Warp, with zero runtime dependencies beyond optional `jq` for richer message formatting.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yigitkonur/hooks-codex-notify-warp/main/scripts/install.sh) --write-config --force-write
```

[![bash](https://img.shields.io/badge/bash-pure_shell-93450a.svg?style=flat-square)](https://www.gnu.org/software/bash/)
[![platform](https://img.shields.io/badge/platform-macOS_|_Linux-93450a.svg?style=flat-square)](#)
[![license](https://img.shields.io/badge/license-MIT-grey.svg?style=flat-square)](https://opensource.org/licenses/MIT)

---

## the problem

Codex can run a `notify` command after each completed turn, but it doesn't ship a Warp-native notifier out of the box. this repo wires Codex `notify` payloads into Warp's OSC 777 notifications so you get native alerts while context-switching.

## install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yigitkonur/hooks-codex-notify-warp/main/scripts/install.sh) --write-config --force-write
```

or clone first:

```bash
git clone https://github.com/yigitkonur/hooks-codex-notify-warp.git /tmp/hooks-codex-notify-warp \
  && bash /tmp/hooks-codex-notify-warp/scripts/install.sh --write-config --force-write \
  && rm -rf /tmp/hooks-codex-notify-warp
```

`jq` is optional. with `jq`, notifications include prompt/response summaries. without `jq`, fallback body is `Task completed`.

## what it installs

```
~/.codex/hooks/notify-warp.sh      — active Codex notify hook
~/.codex/config.toml               — notify = ["~/.codex/hooks/notify-warp.sh"]
```

installer behavior:
- creates `~/.codex/hooks/notify-warp.sh`
- optionally writes/updates `notify = [...]` in `~/.codex/config.toml`
- creates timestamped config backup before modification

## how it works (in depth)

the hook receives the final argv argument from Codex `notify` (JSON payload), then:

1. exits fast unless terminal is Warp (`TERM_PROGRAM=WarpTerminal`) or `WARP_NOTIFY_FORCE=1`
2. parses payload when `jq` exists
3. extracts:
   - `type` (expects `agent-turn-complete`)
   - `input-messages[0]`
   - `last-assistant-message`
4. builds concise body:
   - `"<prompt>" → <response>` when both exist
   - response-only when prompt missing
   - fallback `Task completed`
5. sends OSC 777 sequence to tty:
   - `\033]777;notify;<title>;<body>\007`

Warp receives OSC 777 and shows a native notification (Warp center + system notification behavior per Warp settings).

## verify

```bash
./scripts/test.sh
```

you should see dry-run title/body output for multiple payload shapes.

for a real Warp check:

```bash
TERM_PROGRAM=WarpTerminal /Users/$USER/.codex/hooks/notify-warp.sh '{"type":"agent-turn-complete","input-messages":["ping"],"last-assistant-message":"pong"}'
```

## runtime knobs

- `WARP_NOTIFY_DRY_RUN=1` → print title/body, no OSC emit
- `WARP_NOTIFY_FORCE=1` → allow run outside Warp (useful for CI tests)
- `WARP_NOTIFY_TITLE="Codex"` → override notification title
- `RAW_BASE=...` (install-time) → custom raw URL source for `notify-warp.sh`

## uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yigitkonur/hooks-codex-notify-warp/main/scripts/uninstall.sh)
```

or from clone:

```bash
./scripts/uninstall.sh
```

## how it differs from Claude Code's Warp plugin

this hook was inspired by [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp), but Codex and Claude Code deliver hook payloads differently:

| | Claude Code | Codex CLI |
|---|---|---|
| payload delivery | **stdin** (JSON) | **argv[1]** (JSON string) |
| payload shape | `.transcript_path` -> JSONL file | `.input-messages[]`, `.last-assistant-message` inline |
| stdout safety | OK | **never write to stdout** (corrupts TUI) |
| config | plugin system | top-level `notify` in config.toml |
| TTY access | `/dev/tty` direct | `/dev/tty` direct (the `tty` command fails in child processes) |

## limitations

- Codex `notify` is post-turn; this does not provide real-time approval-prompt events.
- no payload parsing without `jq` (intentional graceful fallback).
- if no tty is attached, hook exits quietly.

## references / sources

- Codex config docs (`notify`): https://github.com/openai/codex/blob/main/docs/config.md
- Codex config implementation notes (notify payload behavior): https://github.com/openai/codex/blob/main/codex-rs/core/src/config/mod.rs
- Codex hooks/legacy notify payload shape: https://github.com/openai/codex/blob/main/codex-rs/hooks/src/user_notification.rs
- Warp pluggable notifications (OSC 777): https://docs.warp.dev/features/notifications
- Warp Claude reference plugin patterns: https://github.com/warpdotdev/claude-code-warp

## license

MIT
