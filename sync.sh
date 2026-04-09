#!/bin/bash
# sync.sh — Sync docs/ from ~/claude-os/ to ~/.claude/
# NOTE: ~/.claude/CLAUDE.md is maintained separately (compressed version)

set -e

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_DIR="$HOME/.claude"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Copy doc references (complete specs for offline access)
echo "📚 Copying docs/ references..."
mkdir -p "$TARGET_DIR/docs"
cp -r "$SOURCE_DIR/docs/" "$TARGET_DIR/docs/"

# Sync skills from .claude/skills/ to ~/.claude/skills/
if [ -d "$SOURCE_DIR/.claude/skills" ]; then
  echo "🧩 Syncing skills..."
  mkdir -p "$TARGET_DIR/skills"
  rsync -a --delete "$SOURCE_DIR/.claude/skills/" "$TARGET_DIR/skills/"
  echo "Skills synced: $(ls "$TARGET_DIR/skills" | wc -l | tr -d ' ') items"
fi

echo "✅ Sync complete"
echo ""
echo "Documentation synced:"
ls -lh "$TARGET_DIR/docs"/*.md
echo ""
echo "Compressed config at ~/.claude/CLAUDE.md:"
wc -l "$TARGET_DIR/CLAUDE.md"
