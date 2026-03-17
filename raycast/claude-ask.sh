#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Claude Ask
# @raycast.mode silent
# @raycast.packageName Claude OS
# @raycast.icon 🤖
# @raycast.description Open a new Claude Code session in Terminal (from claude-os)
# @raycast.author Leo
# @raycast.authorURL https://github.com/leodingfu
# @raycast.argument1 { "type": "text", "placeholder": "Optional: ask something...", "optional": true }

set -euo pipefail

CLAUDE_OS_DIR="$HOME/claude-os"
PROMPT="${1:-}"

if [ -n "$PROMPT" ]; then
  # One-shot with a prompt: open Terminal and run claude non-interactively
  osascript <<EOF
tell application "Terminal"
  activate
  do script "cd '$CLAUDE_OS_DIR' && claude -p '$PROMPT'"
end tell
EOF
else
  # Open an interactive Claude session
  osascript <<EOF
tell application "Terminal"
  activate
  do script "cd '$CLAUDE_OS_DIR' && claude"
end tell
EOF
fi
