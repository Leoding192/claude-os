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

echo "✅ Sync complete"
echo ""
echo "Documentation synced:"
ls -lh "$TARGET_DIR/docs"/*.md
echo ""
echo "Compressed config at ~/.claude/CLAUDE.md:"
wc -l "$TARGET_DIR/CLAUDE.md"
