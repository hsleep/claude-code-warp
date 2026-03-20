#!/bin/bash
# Hook script for Claude Code SessionStart event
# Shows welcome message, Warp detection status, and emits plugin version

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/build-payload.sh"

# Read hook input from stdin
INPUT=$(cat)

# Read plugin version from plugin.json
PLUGIN_VERSION=$(jq -r '.version // "unknown"' "$SCRIPT_DIR/../.claude-plugin/plugin.json" 2>/dev/null)

# Emit structured notification with plugin version so Warp can track it
BODY=$(build_payload "$INPUT" "session_start" \
    --arg plugin_version "$PLUGIN_VERSION")
"$SCRIPT_DIR/warp-notify.sh" "warp://cli-agent" "$BODY"
