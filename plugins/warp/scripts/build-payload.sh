#!/bin/bash
# Builds a structured JSON notification payload for warp://cli-agent.
#
# Usage: source this file, then call build_payload with event-specific fields.
#
# Example:
#   source "$(dirname "${BASH_SOURCE[0]}")/build-payload.sh"
#   BODY=$(build_payload "$INPUT" "stop" \
#       --arg query "$QUERY" \
#       --arg response "$RESPONSE" \
#       --arg transcript_path "$TRANSCRIPT_PATH")
#
# The function extracts common fields (session_id, cwd, project) from the
# hook's stdin JSON (passed as $1), then merges any extra jq args you pass.

build_payload() {
    local input="$1"
    local event="$2"
    shift 2

    # Extract common fields from the hook input
    local session_id cwd project
    session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
    cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null)
    project=""
    if [ -n "$cwd" ]; then
        project=$(basename "$cwd")
    fi

    # Build the payload: common fields + any extra args passed by the caller.
    # Extra args should be jq flag pairs like: --arg key "value" or --argjson key '{"a":1}'
    jq -nc \
        --arg agent "claude" \
        --arg event "$event" \
        --arg session_id "$session_id" \
        --arg cwd "$cwd" \
        --arg project "$project" \
        "$@" \
        '{v:1, agent:$agent, event:$event, session_id:$session_id, cwd:$cwd, project:$project} + $ARGS.named'
}
