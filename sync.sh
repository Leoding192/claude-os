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
  # Copy flat .md skill files
  find "$REPO_DIR/.claude/skills" -maxdepth 1 -name "*.md" -exec cp {} "$CLAUDE_DIR/skills/" \;
  # Copy directory-based skills (subdirs containing SKILL.md), excluding ms-office skills that stay repo-local
  for skill_dir in "$REPO_DIR/.claude/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Skip: codex (has scripts/ with binaries), docx/pdf/pptx/xlsx (ms-office, repo-local)
    case "$skill_name" in
      codex|docx|pdf|pptx|xlsx) continue ;;
    esac
    if [ -f "$skill_dir/SKILL.md" ]; then
      mkdir -p "$CLAUDE_DIR/skills/$skill_name"
      cp "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
    fi
  done
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

# ── Settings (hooks) — merge into ~/.claude/settings.json ────────────────────
# Strategy: take the "hooks" key from repo settings.json and merge it into the
# global ~/.claude/settings.json, preserving all other keys (mcpServers, etc.)
REPO_SETTINGS="$REPO_DIR/.claude/settings.json"
GLOBAL_SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$REPO_SETTINGS" ]; then
  python3 - "$REPO_SETTINGS" "$GLOBAL_SETTINGS" <<'PYEOF'
import json, os, sys

repo    = sys.argv[1]
global_ = sys.argv[2]

with open(repo) as f:
    repo_cfg = json.load(f)

# Load existing global config (if any)
if os.path.exists(global_):
    with open(global_) as f:
        global_cfg = json.load(f)
else:
    global_cfg = {}

# Merge: repo hooks overwrite, all other global keys are preserved
if "hooks" in repo_cfg:
    global_cfg["hooks"] = repo_cfg["hooks"]

with open(global_, "w") as f:
    json.dump(global_cfg, f, indent=2)
    f.write("\n")

print(f"[sync] settings hooks → {global_}")
PYEOF
  log "settings.json hooks merged into $GLOBAL_SETTINGS"
else
  warn "No settings.json found in repo — skipping hook sync"
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
