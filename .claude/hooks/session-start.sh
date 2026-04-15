#!/bin/bash
# Check memory file sizes (non-blocking warnings)
bash ~/.claude/hooks/memory-check.sh 2>/dev/null || true
# SessionStart Hook v2 — Selective injection with markers
# Injects: marked CLAUDE.md sections + project context + project state + session.md
# Does NOT inject: activity.log.md, full files

echo '--- SESSION CONTEXT ---'

echo ''
echo '## Current Date'
date '+%Y-%m-%d %A'

echo ''
echo '## Identity & Working Rules'
# Extract only marked sections from CLAUDE.md
awk '/^---INJECT_START---$/{flag=1; next} /^---INJECT_END---$/{flag=0} flag' ~/.claude/CLAUDE.md 2>/dev/null

echo ''
echo '## Project Context'
# Try to detect project and inject context if it exists
project_root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$project_root" ]; then
  project_name=$(basename "$project_root")
  context_file="$project_root/.claude/project.context.md"
  if [ -f "$context_file" ]; then
    echo "### $project_name"
    head -80 "$context_file"
  else
    echo "[No project.context.md found]"
  fi
else
  echo "[Not in a git repository]"
fi

echo ''
echo '## Project State'
# Inject project.state.md if exists
if [ -n "$project_root" ]; then
  state_file="$project_root/.claude/project.state.md"
  if [ -f "$state_file" ]; then
    head -40 "$state_file"
  else
    echo "[No project.state.md found]"
  fi
else
  echo "[Not in a project]"
fi

echo ''
echo '## Session State'
# Inject session.md (shared across projects or project-specific)
session_file="${project_root:-.}/.claude/session.md"
if [ ! -f "$session_file" ] && [ -z "$project_root" ]; then
  session_file=~/.claude/session.md
fi

if [ -f "$session_file" ]; then
  cat "$session_file"
else
  echo "[No session.md found]"
fi

echo ''
echo '## Recent Git Activity'
if [ -n "$project_root" ]; then
  git -C "$project_root" log --oneline -5 2>/dev/null || echo '[No git history]'
else
  echo '[Not in a git repository]'
fi
