# Recovery Model

Defines what happens after an unintended or regretted execution, and what recovery options are available.

---

## Recovery Classes

Each capability in the registry has a reversibility class. That class determines the recovery path.

| Class | Definition | System response |
|---|---|---|
| **Reversible** | The action can be undone automatically with no data loss | Offer `/undo-last`; system executes the reversal automatically |
| **Compensatable** | Cannot be undone, but a corrective action mitigates harm | Log the event; surface corrective options to user; user decides |
| **Irreversible** | Cannot be undone and no corrective action fully restores prior state | Pre-execution escalation required; Blocked tier enforced; audit log mandatory |
| **—** | Read-only; no state mutation | N/A |

---

## Undo Stack

Maintained in-session for **Reversible**-class actions only.

| Property | Value |
|---|---|
| Max depth | 10 actions |
| Scope | Current session only (cleared on session end) |
| Storage | In-context only (not persisted to disk) |
| Command | `/undo-last` |

### `/undo-last` Behaviour

1. Pop the most recent Reversible action from the undo stack.
2. Determine the reversal operation (see table below).
3. Display: `Undoing: <action summary> → <reversal operation>`
4. Require explicit "yes" before executing the reversal (reversal is itself a Confirm-tier action).
5. Execute reversal; log to `logs/audit.jsonl` with `action: "undo"`.

### Reversal Operations by Capability

| capability_id | Reversal operation |
|---|---|
| `write_file` | `git checkout -- <file>` (restore last committed version) |
| `delete_file` | `git checkout -- <file>` (restore from git) |
| `git_commit` | `git reset HEAD~1 --soft` (unstage, keep working tree) |
| `create_calendar_event` | Delete the created event via Calendar MCP |
| `update_calendar_event` | Restore original values via Calendar MCP |
| `write_clipboard` | Restore prior clipboard content (if captured before write) |
| `write_keychain` | Delete the added Keychain entry |
| `draft_email` | Delete the draft via Gmail MCP |

---

## Post-Incident Protocol (Compensatable and Irreversible)

When a Compensatable or Irreversible action completes unexpectedly:

1. **Audit log entry** written immediately to `logs/audit.jsonl` with `{ timestamp, capability_id, action, target, result, confirmed_by_user }`.
2. **User notification**: surface what happened, what cannot be undone, and available compensatory actions.
3. **User decides**: system does not auto-compensate. Present options; wait for explicit instruction.

### Compensatory Actions by Capability

| capability_id | Compensatory action |
|---|---|
| `send_email` | Draft and send a follow-up or correction email |
| `git_push` | Ask user whether to `git revert` or force-push correction branch |
| `delete_calendar_event` | Re-create the event manually with original details if known |

---

## Audit Log Format

All Confirm-tier and Blocked-attempt events are logged to `~/claude-os/logs/audit.jsonl`.

```json
{
  "timestamp": "ISO8601Z",
  "session_id": "string | null",
  "tool": "Bash | Gmail MCP | ...",
  "capability_id": "string",
  "action": "string — human-readable description",
  "target": "string — file path, email address, doc id, etc.",
  "result": "success | blocked | cancelled | error",
  "confirmed_by_user": true,
  "undo_available": true
}
```

Rotation: monthly. Retained: 90 days.

---

## Relationship to Other Models

- **Capability Registry** (`docs/capability-registry.md`): source of truth for reversibility class per capability.
- **Automation Risk Model** (`docs/automation-risk-model.md`): Irreversible capabilities with score ≥ 0.7 must be escalated before execution — prevention is the first line of recovery.
- **Runtime State Model** (`docs/runtime-state-model.md`): the `AWAITING_CONFIRMATION` state is the checkpoint where the user can prevent an action before it reaches the recovery domain.
