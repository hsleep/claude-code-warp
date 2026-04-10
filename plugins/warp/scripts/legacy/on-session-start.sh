#!/bin/bash
# Hook script for Claude Code SessionStart event
# Shows welcome message and Warp detection status

# Check if running in Warp terminal (directly or via tmux inside Warp)
IS_WARP=false
if [ "$TERM_PROGRAM" = "WarpTerminal" ]; then
    IS_WARP=true
elif [ -n "$TMUX" ]; then
    # Inside tmux: check the outer terminal's TERM_PROGRAM from tmux environment
    OUTER_TERM=$(tmux show-environment -g TERM_PROGRAM 2>/dev/null | sed 's/TERM_PROGRAM=//')
    if [ "$OUTER_TERM" = "WarpTerminal" ]; then
        IS_WARP=true
    fi
fi

if $IS_WARP; then
    cat << 'EOF'
{
  "systemMessage": "🔔 Warp plugin active. You'll receive native Warp notifications when tasks complete or input is needed."
}
EOF
else
    # Not running in Warp - suggest installing
    cat << 'EOF'
{
  "systemMessage": "ℹ️ Warp plugin installed but you're not running in Warp terminal. Install Warp (https://warp.dev) to get native notifications when Claude completes tasks or needs input."
}
EOF
fi
