# Memory Schema

Defines the four-layer memory system, write policy, and retention rules for claude-os.

---

## Layers

| Layer | Location | Injection | Write trigger | Retention |
|---|---|---|---|---|
| **L0 Ephemeral** | Context window only | — | Never written to disk | Session only |
| **L1 Session** | `memory/session.md` | Every prompt (UserPromptSubmit hook) | User-initiated or session-end prompt | Overwritten each session |
| **L2 Project** | `memory/projects/<name>.md` | On demand (`@memory/projects/<name>`) | `/remember` or explicit "记住" | Permanent until archived |
| **L3 Persistent** | `memory/decisions.md`, `memory/people/*.md`, `memory/writing.md` | On demand | `/remember` or explicit "记住" | Permanent; quarterly review |
| **L4 Archived** | `memory/archive/YYYY-MM/` | Never auto-injected | `/consolidate` moves stale L3 entries | Retained 2 years, then deleted |

---

## Write Policy

| Transition | Allowed? | Trigger required |
|---|---|---|
| L0 → L1 | Yes | User-initiated or session-end prompt only |
| L1 → L2/L3 | Yes | Explicit `/remember` or "记住" signal |
| Any layer (auto-promotion) | **No** | System must never promote without user signal |
| Cross-layer reads | Yes | Always allowed |

---

## Hard Limits

| Layer | Limit | Action on breach |
|---|---|---|
| L1 `session.md` | 50 lines max | Warn user; truncate oldest entries |
| L3 total entries | 200 across all files | Require `/consolidate` before adding more |
| L4 retention | 2 years | Delete (automated annually) |

---

## Prohibited Content

At any layer, the following must never be written:
- Raw conversation transcripts
- Credentials, tokens, or API keys
- Other people's private communications (without their consent)
- Speculative content that was not acted upon

---

## L2: Project Memory

Location: `memory/projects/<project-name>.md`

Use for: project-specific decisions, architecture choices, known bugs, stakeholder context.

Format:
```markdown
# <Project Name>

## Decisions
- <date> — <decision> — <rationale>

## Known Issues
- <issue> — <status>

## Context
- <anything that helps Claude understand this project>
```

---

## L3: Persistent Memory

### `memory/decisions.md`

Settled cross-project decisions and lessons learned. Format:
```markdown
## <YYYY-MM-DD> — <Title>
<Decision or lesson>
**Why:** <rationale>
**How to apply:** <when this applies>
```

### `memory/people/<name>.md`

Collaborator context. One file per person. Format:
```markdown
# <Name>
- **Role:** <role>
- **Preferences:** <communication preferences>
- **Context:** <relevant background>
```

### `memory/writing.md`

Leo's writing preferences and style guidelines. Used by the `mailer` agent and any writing tasks.

---

## `/consolidate` Command

See `.claude/commands/consolidate.md` for the full procedure.

Summary:
1. Read all L3 entries
2. Identify stale entries (not referenced in last 90 days, or explicitly superseded)
3. Move stale entries to `memory/archive/YYYY-MM/`
4. Update `memory/decisions.md` with a consolidation note
5. Report: N entries archived, M entries retained

---

## Relationship to Session Injection

The `UserPromptSubmit` hook reads `memory/session.md` and injects it into every prompt. This means:
- Keep L1 short (≤ 50 lines)
- Only current-session state belongs here
- Historical decisions go in L3 (`decisions.md`)
- Project context goes in L2 (`memory/projects/`)
