#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
TASKS_DIR="${HOME}/claude-os/logs"
mkdir -p "$TASKS_DIR"

case "$ACTION" in
  create)
    TASK_ID="task-$(date +%Y%m%d-%H%M%S)-$(python3 -c 'import uuid; print(str(uuid.uuid4())[:8])')"
    STATUS="PLANNING"
    TITLE="${2:-unnamed task}"
    CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    cat > "${TASKS_DIR}/current-task.json" <<EOF
{
  "task_id": "${TASK_ID}",
  "intent": "${TITLE}",
  "agent": "task-planner",
  "capability_ids": [],
  "risk_score": 0.0,
  "state": "${STATUS}",
  "confirmation_required_for": null,
  "steps_total": 0,
  "steps_done": 0,
  "created_at": "${CREATED_AT}",
  "updated_at": "${CREATED_AT}"
}
EOF
    echo "Created: ${TASK_ID}"
    ;;

  complete)
    TASK_ID="${2:-}"
    FILE="${TASKS_DIR}/current-task.json"
    [ -f "$FILE" ] || { echo "Task not found: $TASK_ID"; exit 1; }
    python3 << PYEOF
import json
import datetime
with open('${FILE}') as f:
    d = json.load(f)
d['state'] = 'COMPLETED'
d['completed_at'] = datetime.datetime.utcnow().isoformat() + 'Z'
with open('${FILE}', 'w') as f:
    json.dump(d, f, indent=2)
print('Completed:', d['task_id'])
PYEOF
    ;;

  list)
    find "$TASKS_DIR" -name "current-task.json" -exec python3 -c "
import json
import sys
d = json.load(open(sys.argv[1]))
print(f\"{d['state']:15} {d['task_id']} — {d['intent']}\")
" {} \; 2>/dev/null | sort || echo "No active tasks"
    ;;

  archive)
    ARCHIVE_DIR="${TASKS_DIR}/archive"
    mkdir -p "$ARCHIVE_DIR"
    TASK_ID="${2:-}"
    FILE="${TASKS_DIR}/current-task.json"
    if [ -f "$FILE" ]; then
      mv "$FILE" "$ARCHIVE_DIR/task-$(date +%Y%m%d-%H%M%S).json"
      echo "Archived: $TASK_ID"
    fi
    ;;

  *)
    echo "Usage: task-manager.sh [create|complete|list|archive] [args]"
    exit 1
    ;;
esac
