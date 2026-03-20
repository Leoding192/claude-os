# Runtime State Model

Defines how claude-os tracks task execution state within and across sessions.

---

## Constraints

Claude Code is conversation-based, not a persistent process. The state model works within these limits:

- **In-session state**: tracked in `logs/current-task.json` (overwritten each active task)
- **Cross-session persistence**: terminal states appended to `logs/tasks.jsonl`
- **Enforcement**: a mix of Claude behavioral rules (CLAUDE.md) and hooks (settings.json)

---

## State Machine

```
IDLE
  │
  ▼
PLANNING ─────────────────────────────────────────── CANCELLED
  │  (task-planner produces step list, user approves)      ▲
  ▼                                                       │
EXECUTING ──► AWAITING_CONFIRMATION ──► (user rejects) ──┘
  │                  │
  │           (user confirms)
  │                  │
  ▼                  ▼
COMPLETED ◄───── EXECUTING (continues)

FAILED (any unrecoverable error at any stage)
```

### Transitions

| From | To | Trigger |
|---|---|---|
| IDLE | PLANNING | User invokes `/task` or non-trivial task detected |
| PLANNING | EXECUTING | User approves the plan |
| PLANNING | CANCELLED | User rejects the plan |
| EXECUTING | AWAITING_CONFIRMATION | Confirm-tier capability reached |
| AWAITING_CONFIRMATION | EXECUTING | User confirms |
| AWAITING_CONFIRMATION | CANCELLED | User rejects |
| EXECUTING | COMPLETED | All steps done |
| EXECUTING | FAILED | Unrecoverable error |
| EXECUTING | CANCELLED | User explicitly cancels |

### Invariants

1. At most one task is in EXECUTING state per session.
2. A task in AWAITING_CONFIRMATION may only proceed on explicit user "yes".
3. COMPLETED and CANCELLED are terminal — no further transitions.
4. A task may not invoke an unregistered capability (see capability-registry.md).

---

## File Schemas

### `logs/current-task.json` (active session only)

```json
{
  "task_id": "uuid",
  "intent": "string — what the user asked for",
  "agent": "string — which agent is handling this",
  "capability_ids": ["string"],
  "risk_score": 0.0,
  "state": "PLANNING | EXECUTING | AWAITING_CONFIRMATION",
  "confirmation_required_for": "capability_id | null",
  "steps_total": 0,
  "steps_done": 0,
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

### `logs/tasks.jsonl` (append-only, cross-session history)

```json
{
  "task_id": "uuid",
  "intent": "string",
  "agent": "string",
  "capability_ids": ["string"],
  "risk_score": 0.0,
  "final_state": "COMPLETED | FAILED | CANCELLED",
  "steps_total": 0,
  "steps_done": 0,
  "created_at": "ISO8601",
  "completed_at": "ISO8601",
  "result_summary": "string | null",
  "error": "string | null"
}
```

---

## Orchestration Rules (enforced via CLAUDE.md)

1. Before starting any multi-step task: write `current-task.json` with state PLANNING.
2. Before any Confirm-tier capability: set state to AWAITING_CONFIRMATION, surface action to user.
3. On task completion: append to `tasks.jsonl`, delete `current-task.json`.
4. On session end with an incomplete task: write CANCELLED state to `tasks.jsonl` (via Stop hook).
5. On unrecoverable error: set state FAILED, surface the error, do not retry silently.

---

## Implementation Notes

The state model is **behaviorally enforced** for planning/execution states (Claude follows the rules in CLAUDE.md) and **technically enforced** for:
- Confirm-tier blocking (Stop hook detects incomplete tasks)
- Cross-session persistence (tasks.jsonl append)
- Current task visibility (current-task.json readable by hooks)

Full technical enforcement of all state transitions requires the Automation Risk Model (next layer) which computes risk scores per capability invocation.
