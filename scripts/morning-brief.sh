#!/usr/bin/env bash
# morning-brief.sh — runs /brief non-interactively and saves output
# Called by launchd every morning at the configured time.

set -euo pipefail

CLAUDE_BIN="/Users/dingfuying/.local/bin/claude"
CLAUDE_OS_DIR="$HOME/claude-os"
DATE=$(date +%Y-%m-%d)
LOG_DIR="$CLAUDE_OS_DIR/logs/briefs"
OUTPUT="$LOG_DIR/$DATE.md"

mkdir -p "$LOG_DIR"

notify() {
  osascript -e "display notification \"$1\" with title \"Claude OS\" subtitle \"Morning Brief\"" 2>/dev/null || true
}

if [ ! -x "$CLAUDE_BIN" ]; then
  notify "Brief failed — claude binary not found at $CLAUDE_BIN"
  echo "[morning-brief] ERROR: claude not found at $CLAUDE_BIN" >&2
  exit 1
fi

# Run /brief non-interactively from claude-os directory
cd "$CLAUDE_OS_DIR"
if "$CLAUDE_BIN" -p "/brief" > "$OUTPUT" 2>&1; then
  notify "Brief ready — logs/briefs/$DATE.md"
  echo "[morning-brief] Brief saved to $OUTPUT"
else
  notify "Brief failed — check logs/briefs/$DATE.md"
  echo "[morning-brief] ERROR: claude exited with error. See $OUTPUT" >&2
  exit 1
fi
