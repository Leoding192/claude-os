#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Claude Brief
# @raycast.mode fullOutput
# @raycast.packageName Claude OS
# @raycast.icon 📅
# @raycast.description Daily brief: calendar events + email summary
# @raycast.author Leo
# @raycast.authorURL https://github.com/leodingfu

set -euo pipefail

CLAUDE_OS_DIR="$HOME/claude-os"

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

cd "$CLAUDE_OS_DIR"
claude -p "/brief"
