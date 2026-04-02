# Automation Risk Model & Permission Tiers

## Quick Reference: Permission Tiers

| Tier | Examples | Behavior |
|------|----------|----------|
| **🟢 Auto** | Read files, read email, search, git read | Execute silently — no confirmation |
| **🟡 Confirm** | Write/delete files, send email, git push, modify calendar | Surface action summary → require explicit "yes" |
| **🔴 Blocked** | Push to main, touch .env/secrets, write prod config | Hard block — never execute |

All capabilities catalogued in [capability-registry.md](capability-registry.md).

---

## Risk Scoring Algorithm

**When to apply:** Before invoking any capability that isn't already registered as Auto.

### Formula

```
risk_score = max(blast_radius, reversibility) * 0.5 
           + confidence_uncertainty * 0.3 
           + external_side_effect * 0.2

Execution path:
- 0.0–0.3 → Auto (silent)
- 0.4–0.6 → Confirm (surface + "yes")
- 0.7–1.0 → Escalate (ask intent first, do not attempt)
```

### Variables

| Variable | Range | Example |
|----------|-------|---------|
| **blast_radius** | 0–1 | Affects one file (0.1) vs entire repo (1.0) |
| **reversibility** | 0–1 | Edit → undo (0.2) vs git push (0.9) |
| **confidence_uncertainty** | 0–1 | Clear user intent (0.0) vs inferred intent (0.7–1.0) |
| **external_side_effect** | 0–1 | Local-only (0.0) vs Slack post (0.8) |

### Examples

#### Example 1: Write a local Python file
```
- blast_radius = 0.2 (affects one file)
- reversibility = 0.3 (undo is possible)
- confidence = 0.0 (explicit user request)
- external = 0.0 (local only)

risk = max(0.2, 0.3) * 0.5 + 0.0 * 0.3 + 0.0 * 0.2 = 0.15
→ 🟢 AUTO (silent execution)
```

#### Example 2: Push to main
```
- blast_radius = 1.0 (entire codebase)
- reversibility = 0.9 (force-revert needed)
- confidence = 0.2 (user said "push")
- external = 0.8 (visible to 50+ people)

risk = max(1.0, 0.9) * 0.5 + 0.2 * 0.3 + 0.8 * 0.2 = 0.71
→ 🔴 ESCALATE (ask intent, do not execute)
```

#### Example 3: Delete a file (user asks explicitly)
```
- blast_radius = 0.5 (local codebase)
- reversibility = 0.8 (git has history, but...)
- confidence = 0.0 (explicit request)
- external = 0.0 (local)

risk = max(0.5, 0.8) * 0.5 + 0.0 * 0.3 + 0.0 * 0.2 = 0.40
→ 🟡 CONFIRM (show summary, require "yes")
```

---

## Floor Rules

- If registered tier is **Blocked** → hard block regardless of score
- Execution path = max(computed_score, registered_tier_floor)
- If intent is inferred (not explicit) → add confidence_uncertainty = 0.5–1.0

---

## Confirm-Tier Logging

All Confirm-tier operations are automatically logged to `logs/audit.jsonl` via PostToolUse hook.

```json
{
  "timestamp": "2026-04-02T10:30:45Z",
  "tool": "Write",
  "action": "Created /Users/dingfuying/new-file.py",
  "result": "success",
  "confirmed_by_user": true
}
```

---

## See Also
- [capability-registry.md](capability-registry.md) — look up any capability before executing
- [Orchestration Rules](runtime-state-model.md#orchestration-rules) — multi-step task coordination
