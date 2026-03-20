Start a tracked task with full state management.

## Usage
/task <intent>

## Steps

1. Generate a task_id (use python3: `import uuid; print(str(uuid.uuid4())[:8])`)

2. Write `~/claude-os/logs/current-task.json` with state PLANNING:
```json
{
  "task_id": "<generated>",
  "intent": "$ARGUMENTS",
  "agent": "task-planner",
  "capability_ids": [],
  "risk_score": 0.0,
  "state": "PLANNING",
  "confirmation_required_for": null,
  "steps_total": 0,
  "steps_done": 0,
  "created_at": "<ISO8601 now>",
  "updated_at": "<ISO8601 now>"
}
```

3. Invoke the task-planner agent to decompose the intent into steps.
   - Count the steps and update `steps_total` in current-task.json
   - Present the plan to the user and wait for approval

4. On approval: update state to EXECUTING in current-task.json. Execute each step:
   - Before any Confirm-tier capability: update state to AWAITING_CONFIRMATION, set `confirmation_required_for`, show action summary, wait for explicit "yes"
   - On confirm: reset state to EXECUTING, increment `steps_done` after each completed step
   - On reject: set state to CANCELLED, append to tasks.jsonl, delete current-task.json, stop

5. On all steps complete:
   - Set final_state to COMPLETED
   - Append completed entry to `~/claude-os/logs/tasks.jsonl`
   - Delete `~/claude-os/logs/current-task.json`
   - Summarise what was done

6. On any unrecoverable error:
   - Set final_state to FAILED, record error
   - Append to tasks.jsonl, delete current-task.json
   - Surface the error clearly, do not retry silently

## Append to tasks.jsonl

```bash
python3 -c "
import json, datetime
entry = {
  'task_id': '<id>',
  'intent': '<intent>',
  'agent': '<agent>',
  'capability_ids': [],
  'risk_score': 0.0,
  'final_state': 'COMPLETED|FAILED|CANCELLED',
  'steps_total': 0,
  'steps_done': 0,
  'created_at': '<ISO8601>',
  'completed_at': datetime.datetime.utcnow().isoformat() + 'Z',
  'result_summary': '<summary>',
  'error': None
}
with open('/Users/dingfuying/claude-os/logs/tasks.jsonl', 'a') as f:
    f.write(json.dumps(entry) + '\n')
"
```
