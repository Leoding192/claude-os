#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Claude Capture
# @raycast.mode compact
# @raycast.packageName Claude OS
# @raycast.icon 📝
# @raycast.description Quick-capture a thought or task into session memory
# @raycast.author Leo
# @raycast.authorURL https://github.com/leodingfu
# @raycast.argument1 { "type": "text", "placeholder": "What to capture..." }

set -euo pipefail

CLAUDE_OS_DIR="$HOME/claude-os"
CAPTURE_TEXT="${1:-}"

if [ -z "$CAPTURE_TEXT" ]; then
  echo "Nothing to capture."
  exit 0
fi

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found. Install with: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

cd "$CLAUDE_OS_DIR"
claude -p "/capture \"$CAPTURE_TEXT\""
