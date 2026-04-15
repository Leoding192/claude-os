#!/bin/bash
# Memory enforcement script — checks file size limits and warns if exceeded
# Invoked from SessionStart hook (warnings only, non-blocking)

PROJECT_ROOT=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null)

check_file_lines() {
  local file="$1"
  local limit="$2"
  local name="$3"

  if [ ! -f "$file" ]; then
    return 0
  fi

  local lines=$(wc -l < "$file")
  if [ "$lines" -gt "$limit" ]; then
    echo "[memory-check] ⚠️  WARNING: $name has $lines lines (limit: $limit) — consider archiving old content"
  fi
}

check_entries() {
  local file="$1"
  local limit="$2"
  local name="$3"

  if [ ! -f "$file" ]; then
    return 0
  fi

  local entries=$(grep -c "^\[" "$file" 2>/dev/null || echo 0)
  if [ "$entries" -gt "$limit" ]; then
    echo "[memory-check] ⚠️  WARNING: $name has $entries entries (limit: $limit) — oldest entries should be pruned"
  fi
}

# Check project memory (if in project)
if [ -n "$PROJECT_ROOT" ]; then
  project_name=$(basename "$PROJECT_ROOT")

  check_file_lines "$PROJECT_ROOT/.claude/project.context.md" 80 "project.context.md"
  check_file_lines "$PROJECT_ROOT/.claude/project.state.md" 40 "project.state.md"
  check_file_lines "$PROJECT_ROOT/.claude/session.md" 20 "session.md (project-scoped)"
  check_entries "$PROJECT_ROOT/.claude/activity.log.md" 30 "activity.log.md"
else
  # Global session memory (not in project)
  check_file_lines ~/.claude/session.md 20 "session.md (global)"
fi

# Check global memory (if file exists)
if [ -f ~/.claude/projects/-Users-dingfuying/memory/decisions.md ]; then
  check_file_lines ~/.claude/projects/-Users-dingfuying/memory/decisions.md 120 "decisions.md (global)"
fi
