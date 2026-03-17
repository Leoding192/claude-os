#!/usr/bin/env bash
# sync.sh — copy claude-os config into ~/.claude/
# Run this after any change to agents, skills, or commands.
# Safe to run repeatedly; overwrites existing files.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

log()  { echo "[sync] $*"; }
warn() { echo "[sync] WARN: $*" >&2; }

# ── Agents ────────────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.claude/agents" ]; then
  mkdir -p "$CLAUDE_DIR/agents"
  cp "$REPO_DIR/.claude/agents/"*.md "$CLAUDE_DIR/agents/"
  log "agents → $CLAUDE_DIR/agents/"
else
  warn "No agents directory found — skipping"
fi

# ── Skills ────────────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.claude/skills" ]; then
  mkdir -p "$CLAUDE_DIR/skills"
  # Copy .md skill files (not the codex symlink — that stays repo-local)
  find "$REPO_DIR/.claude/skills" -maxdepth 1 -name "*.md" -exec cp {} "$CLAUDE_DIR/skills/" \;
  log "skills → $CLAUDE_DIR/skills/"
else
  warn "No skills directory found — skipping"
fi

# ── Commands ──────────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.claude/commands" ]; then
  mkdir -p "$CLAUDE_DIR/commands"
  cp "$REPO_DIR/.claude/commands/"*.md "$CLAUDE_DIR/commands/"
  log "commands → $CLAUDE_DIR/commands/"
else
  warn "No commands directory found — skipping"
fi

# ── Session state ─────────────────────────────────────────────────────────────
SESSION="$REPO_DIR/memory/session.md"
TEMPLATE="$REPO_DIR/memory/session.md.template"
if [ ! -f "$SESSION" ] && [ -f "$TEMPLATE" ]; then
  cp "$TEMPLATE" "$SESSION"
  log "memory/session.md initialized from template"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
echo ""
log "Sync complete. Current state:"
for dir in agents skills commands; do
  count=$(find "$CLAUDE_DIR/$dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  log "  ~/.claude/$dir/  ($count files)"
done
