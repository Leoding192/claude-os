# Automation Risk Model

Defines how claude-os scores risk per capability invocation and selects an execution path.

---

## Purpose

Not all actions carry equal risk. This model computes a numeric risk score at invocation time — before any action is taken — and routes to the appropriate execution path (auto, confirm, or escalate). This is distinct from the Permission Tier system, which sets a static floor per capability. The risk model can only raise the required approval level, never lower it below the registered tier.

---

## Risk Dimensions

Each dimension is scored 0.0 (low) to 1.0 (high).

| Dimension | 0.0 — Low | 0.5 — Medium | 1.0 — High |
|---|---|---|---|
| **blast_radius** | Affects local context only | Affects one external record | Affects multiple records or systems |
| **reversibility** | Reversible (auto-undo exists) | Compensatable (corrective action mitigates) | Irreversible (no full recovery) |
| **confidence** | Intent is unambiguous | Some interpretation required | Intent unclear or inferred |
| **external_side_effect** | No external system touched | One system, read-only | One or more systems, write |

---

## Risk Formula

```
risk_score = max(blast_radius, reversibility) * 0.5
           + confidence_uncertainty * 0.3
           + external_side_effect * 0.2
```

- `max(blast_radius, reversibility)` — the dominant danger dimension drives the base score
- `confidence_uncertainty` — uncertainty about intent amplifies risk
- `external_side_effect` — external writes add residual weight

Score range: 0.0 – 1.0

---

## Execution Path Selection

| Score | Path | Behaviour |
|---|---|---|
| 0.0 – 0.3 | **Auto** | Execute silently; no user prompt |
| 0.4 – 0.6 | **Confirm** | Surface action summary (capability_id, target, effect); require explicit "yes" |
| 0.7 – 1.0 | **Escalate** | Do not attempt; surface the intent and ask user to confirm or rephrase |
| Blocked tier | **Hard block** | Refuse regardless of score; exit 2 |

**Floor rule:** If a capability's registered tier is Confirm, the execution path is at minimum Confirm — even if the computed score is 0.0–0.3.

---

## Pre-computed Scores (Reference)

These scores assume a typical invocation with unambiguous user intent (confidence = 0.0). Adjust upward when intent is inferred or the blast radius is wider than the default case.

| capability_id | blast_radius | reversibility | ext_side_effect | risk_score | default path |
|---|---|---|---|---|---|
| `read_file` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `search_files` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `git_read` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_email` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `search_email` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_calendar` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_feishu_message` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_feishu_doc` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_clipboard` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_env_var` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `read_keychain` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `run_codex_readonly` | 0.0 | 0.0 | 0.0 | 0.00 | Auto |
| `send_notification` | 0.0 | 0.0 | 0.5 | 0.10 | Auto |
| `draft_email` | 0.0 | 0.0 | 0.5 | 0.10 | Auto |
| `git_commit` | 0.0 | 0.5 | 0.0 | 0.25 | Auto |
| `run_codex` | 0.5 | 0.5 | 0.0 | 0.25 | Auto (floor: Auto) |
| `write_file` | 0.5 | 0.5 | 0.0 | 0.25 | Confirm (floor: Confirm) |
| `write_clipboard` | 0.0 | 0.5 | 0.0 | 0.25 | Confirm (floor: Confirm) |
| `create_calendar_event` | 0.5 | 0.5 | 1.0 | 0.45 | Confirm |
| `update_calendar_event` | 0.5 | 0.5 | 1.0 | 0.45 | Confirm |
| `create_feishu_doc` | 0.5 | 0.5 | 1.0 | 0.45 | Confirm |
| `write_keychain` | 0.5 | 0.5 | 0.0 | 0.25 | Confirm (floor: Confirm) |
| `git_push` | 0.5 | 0.5 | 1.0 | 0.45 | Confirm |
| `delete_file` | 1.0 | 0.5 | 0.0 | 0.50 | Confirm |
| `send_email` | 1.0 | 1.0 | 1.0 | 0.70 | Confirm → Escalate if intent unclear |
| `send_feishu_message` | 1.0 | 1.0 | 1.0 | 0.70 | Confirm → Escalate if intent unclear |
| `write_feishu_doc` | 1.0 | 1.0 | 1.0 | 0.70 | Confirm → Escalate if intent unclear |
| `delete_calendar_event` | 1.0 | 1.0 | 1.0 | 0.70 | Confirm → Escalate if intent unclear |
| `git_reset_hard` | 1.0 | 1.0 | 0.0 | 0.50 | Confirm |
| `git_push_main` | — | — | — | — | **Blocked** |
| `write_env_file` | — | — | — | — | **Blocked** |
| `read_prod_config` | — | — | — | — | **Blocked** |
| `write_prod_config` | — | — | — | — | **Blocked** |

---

## Confidence Adjustment

When Claude infers intent rather than receiving an explicit instruction, add to the risk score:

| Confidence level | confidence_uncertainty | Additional score |
|---|---|---|
| Explicit instruction | 0.0 | +0.00 |
| Paraphrase / implied | 0.5 | +0.15 |
| Inferred / ambiguous | 1.0 | +0.30 |

**Example:** `send_email` with ambiguous intent → 0.70 + 0.30 = 1.00 → Escalate.

---

## Applying the Model

When Claude is about to invoke a capability:

1. Look up the `capability_id` in the registry. If not found → hard block.
2. Check the registered tier. If Blocked → hard block.
3. Estimate blast_radius, reversibility, confidence_uncertainty, external_side_effect for this specific invocation.
4. Compute `risk_score`.
5. Apply the floor rule: path = max(computed_path, registered_tier_floor).
6. Execute the chosen path (auto / confirm / escalate).
7. Record `capability_id` and `risk_score` in `current-task.json` under `capability_ids`.

---

## Relationship to Other Models

- **Capability Registry** (`docs/capability-registry.md`): defines the static tier floor and reversibility class. The risk model operates on top of this.
- **Runtime State Model** (`docs/runtime-state-model.md`): the Confirm path triggers an `AWAITING_CONFIRMATION` state transition.
- **Recovery Model** (`docs/recovery-model.md`): reversibility class (from the registry) determines recovery options after execution.
