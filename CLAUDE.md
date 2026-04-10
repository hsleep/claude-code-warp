# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Claude Code plugin repository providing native Warp terminal integration. It is published as a marketplace plugin (`warpdotdev/claude-code-warp`) and installed via Claude Code's plugin system.

## Repository Structure

- `.claude-plugin/marketplace.json` — marketplace manifest listing available plugins
- `plugins/warp/` — the Warp plugin
  - `.claude-plugin/plugin.json` — plugin manifest (name, version, author)
  - `hooks/hooks.json` — hook registrations binding Claude Code events to shell scripts
  - `scripts/` — bash scripts, one per hook event plus a shared utility

## Architecture

The plugin is entirely bash-based with no build step. It works as follows:

1. `hooks/hooks.json` registers three Claude Code hook events: `SessionStart`, `Stop`, and `Notification`. Each maps to a script under `scripts/` using `${CLAUDE_PLUGIN_ROOT}` (resolved at runtime by Claude Code).

2. Hook scripts receive a JSON payload via stdin. They use `jq` to parse it.

3. All notifications are sent via `warp-notify.sh`, which writes an OSC 777 escape sequence (`\033]777;notify;<title>;<body>\007`) directly to `/dev/tty`. Inside tmux, it wraps the sequence in a DCS passthrough (`\033Ptmux;...\033\\`) so it reaches the outer Warp terminal.

4. Warp detection uses `$TERM_PROGRAM=WarpTerminal`. Inside tmux, it falls back to reading `TERM_PROGRAM` from `tmux show-environment -g`.

## Hook Script Behavior

- **`on-session-start.sh`**: Detects if running in Warp (directly or via tmux), outputs a `systemMessage` JSON response shown to the user at session start.
- **`on-stop.sh`**: Reads `transcript_path` from stdin, parses the JSONL transcript to extract the first user prompt and last assistant text response, formats as `"<prompt>" → <response>` (truncated), and calls `warp-notify.sh`.
- **`on-notification.sh`**: Reads `.message` from stdin JSON and calls `warp-notify.sh`.
- **`warp-notify.sh`**: Shared utility — takes `<title>` and `<body>` args, sends the OSC sequence.

## Requirements

- `jq` must be installed (used by hook scripts for JSON parsing)
- Warp terminal for notifications to appear
- No other dependencies; no package manager, no build tools

## Testing Changes

Test scripts manually by simulating the JSON input Claude Code would send:

```bash
# Test on-stop with a mock transcript
echo '{"transcript_path":"/path/to/transcript.jsonl"}' | bash plugins/warp/scripts/on-stop.sh

# Test on-notification
echo '{"message":"Permission needed"}' | bash plugins/warp/scripts/on-notification.sh

# Test warp-notify directly
bash plugins/warp/scripts/warp-notify.sh "Claude Code" "Test message"
```

The transcript format is JSONL where each line is a JSON object with a `type` field (`"user"` or `"assistant"`) and a `message.content` array.
