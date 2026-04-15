# Claude-OS Memory Policy

This document defines the rules and responsibilities for managing memory files in this OS.

---

## Core Principles

1. **Explicit writes only:** No automatic extraction, parsing, or decision-mining from sessions
2. **User control:** Every long-term memory write requires explicit user action (`/remember` or `/night` confirmation)
3. **Selective injection:** SessionStart injects only marked CLAUDE.md sections + project context + state
4. **Audit trail:** All memory updates are timestamped and reviewable

---

## Memory Layers

### Long-Term Memory (LTM)

**Files:**
- `~/.claude/CLAUDE.md` — Identity, rules, preferences (policy anchor, not injected in full)
- `~/.claude/projects/*/memory/decisions.md` — Project-scoped decisions (manual writes only, never auto-extracted)
- `~/.claude/decisions.md` — Global decisions (optional, if used)

**Rules:**
- Write via `/remember` command only (requires explicit user action)
- No auto-extraction from session logs
- Decisions are durable and survive session boundaries
- Never injected at SessionStart; read when relevant
- Max 100–120 lines; archive old entries quarterly

### Mid-Term Memory (MTM)

**Files per project:**
- `<project>/.claude/project.context.md` — Stable project background (≤80 lines)
- `<project>/.claude/project.state.md` — Current progress, blockers, next steps (≤40 lines)
- `<project>/.claude/activity.log.md` — Rolling operational log, last 30 entries (non-injected)

**Rules:**
- **context.md:** Write manually when project background changes; never auto-generated
- **state.md:** Update manually at session start/end, or via `/night` (with confirmation)
- **activity.log.md:** Append new entries via `/night` or manually; oldest entries auto-pruned
- Only context.md + state.md are injected at SessionStart
- activity.log.md is reference only; never injected

### Short-Term Memory (STM)

**File:**
- `~/.claude/session.md` or project-scoped `<project>/.claude/session.md` — Working board (≤20 lines)

**Rules:**
- Auto-cleared at Stop hook (incomplete tasks carried forward)
- Injected at SessionStart in full
- Ephemeral; not meant for durable records

---

## Write Operations

### `/remember <decision>`

**Purpose:** Explicitly log a decision or lesson to long-term memory.

**Behavior:**
1. User invokes: `/remember I chose X over Y because Z`
2. System formats: `[2026-04-15] Chose X over Y. Reason: Z. Implication: ...`
3. System shows preview
4. System asks: "Save to decisions.md?" (Confirm/Revise/Skip)
5. On confirm: appends to `~/.claude/projects/*/memory/decisions.md` with timestamp

**Examples:**
- `/remember Decided to use format="json" in Ollama to prevent explanation text appended to output`
- `/remember Lesson: auto-extraction from session.md was noisy and wasteful; manual decisions are better`
- `/remember We chose 50/30/20 weight split for tier synthesis based on mentor feedback`

### `/night`

**Purpose:** Summarize the day, propose decisions + state updates, update project metadata.

**Behavior:**
1. User invokes: `/night` (at session end, or whenever)
2. System:
   - Reads current `project.state.md`
   - Reads `session.md`
   - Reads recent `activity.log.md` entries
   - Calls Claude to summarize + propose candidates
3. Claude generates:
   ```
   ## Session Summary
   - Completed X
   - Debugged Y
   - Learned Z
   
   ## Proposed Decisions (If Any)
   - [ ] Decided to...
   - [ ] Chose X because...
   
   ## Proposed State Updates
   Last Worked On: [ISO timestamp]
   Active Task: [next task from your plan]
   Blockers: [updated blockers]
   ```
4. User reviews and selects:
   - "✅ Update project.state.md" → writes new state (Last Worked On, Active Task, Blockers)
   - "📌 Add decisions" → `/remember` for each proposed decision (explicit approval per decision)
   - "📝 Update activity.log" → append 1-2 summary lines to activity.log.md
   - "❌ Skip all" → don't save anything

**Rules:**
- `/night` NEVER auto-writes to decisions.md or project.context.md
- Every durable decision requires explicit user confirmation via `/remember`
- `/night` can only update project.state.md and activity.log.md directly
- If `/night` proposes a decision, user must invoke `/remember` separately to make it durable

**Example workflow:**
```
1. User: /night
2. Claude: "Session summary + proposed decisions"
3. User reviews, confirms: "✅ Update project.state.md"
   → project.state.md updated with new timestamps + active task
4. User sees: "Proposed: Decided to use format=json..."
5. User: /remember Decided to use format="json" to prevent...
   → decision appended to decisions.md
```

---

## File Size Enforcement

**Hard limits (Phase 8 guard rails):**

| File | Max Size | Action if Exceeded |
|------|----------|------------------|
| `project.context.md` | 80 lines | Warning at SessionStart; archive old sections |
| `project.state.md` | 40 lines | Warning; trim to 30-line essentials |
| `session.md` | 20 lines | Stop hook auto-clears; enforced |
| `activity.log.md` | 30 entries | Auto-prune oldest 5; archive to activity.archive.md |
| `decisions.md` | 100–120 lines | Warning; archive entries older than 30 days |

**Archival:**
- Old `activity.log.md` entries → `activity.archive.md`
- Old `decisions.md` entries → `decisions-YYYY-MM.md` (quarterly)
- Old `project.context.md` sections → `project.context-archive.md`

---

## SessionStart Injection Budget

**Target:** ≤400 tokens per session

**Current:**
- CLAUDE.md marked sections: ~100 tokens
- project.context.md (first 80 lines): ~320 tokens
- project.state.md (first 40 lines): ~160 tokens
- session.md (≤20 lines): ~80 tokens
- git log (5 lines): ~30 tokens
- **Subtotal:** ~690 tokens (over budget)

**Tuning options (if exceeds 400):**
1. Reduce CLAUDE.md marked sections (currently: Current Projects + Working Rules)
2. Limit project.context.md to first 50 lines (skip detailed tables)
3. Inject project.state.md only if > 2 active blockers
4. Skip git log if not in repo (already done)

---

## Policy Evolution

**Quarterly review:**
- Check file sizes; archive if needed
- Review decisions.md for patterns (what decisions are recurring?)
- Assess SessionStart token cost; optimize if > 400 tokens
- Update this policy if new patterns emerge

---

## Violation Prevention

### Prevention: Auto-Memory.py (Archived)

This used to auto-extract decisions from session.md every Stop hook. **It is now archived** (`~/claude-os/archive/hooks/auto-memory.py`).

Reasoning:
- Created noise (low-signal extraction via keyword matching)
- Violated principle of explicit writes
- Required manual curation anyway (user had to review + clean up decisions.md)
- Replaced by: explicit `/remember` + optional `/night` summarization

### Prevention: UserPromptSubmit (Removed)

This used to inject session.md on every message. **It is now removed from settings.json**.

Reasoning:
- Wasteful (2000 tokens/day for a 20-line file)
- Created "prompt contamination" (stale session state affecting every prompt)
- Violated principle of selective injection
- Replaced by: SessionStart injection only (once per session)

---

## Summary: Memory Workflow

### At Session Start
- SessionStart injects: CLAUDE.md markers + project context + project state + session board
- You read injected context, understand current state

### During Session
- You work on tasks; session.md captures immediate notes
- No auto-memory or auto-decisions

### At Session End
- Stop hook clears session.md, carries forward incomplete tasks
- (Optional) `/night` summarizes the day; proposes decisions
- You review, confirm `/night` updates (state + activity.log)
- You invoke `/remember` for any durable decisions

### Periodically (Weekly/Monthly)
- Review decisions.md for duplicates or refinements
- Archive old activity.log.md entries
- Check file sizes; enforce limits

---

**Last Updated:** 2026-04-15  
**Policy Version:** 2.0 (Claude-OS Redesign)
