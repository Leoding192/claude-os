# Memory Architecture (L1–L4)

## Overview

| Layer | Location | Injected? | Scope | Retention |
|-------|----------|-----------|-------|-----------|
| **L1** | `memory/session.md` | ✅ Every session | Current work (≤50 lines) | This session only |
| **L2** | `memory/projects/<name>.md` | ❌ On demand | Per-project decisions & context | Per project |
| **L3** | `memory/decisions.md`, `memory/people/`, `memory/writing.md` | ❌ On demand | Durable decisions, lessons, style | Until archived |
| **L4** | `memory/archive/YYYY-MM/` | ❌ Never | Stale L3 entries | 2 years retention |

---

## Layer Definitions

### L1: Session State
**File:** `memory/session.md`  
**Auto-injected:** Yes, every session  
**Max size:** 50 lines  
**Content:** Current work state only

```markdown
# Session State
- In Progress
- Blocked / Waiting On
- Next Up
- Captures
- Recent Git Activity
```

**Rules:**
- Never manually sync — it's auto-injected
- Clear at end of long sessions
- Keep prose minimal (bullets only)

---

### L2: Project Context
**Location:** `memory/projects/<project-name>.md`  
**Auto-injected:** No, use `/remember` to write  
**Scope:** One project per file  
**Content:** 
- Current goals & deadlines
- Architecture decisions (why we chose X over Y)
- Known tradeoffs
- Integration points with other systems
- Team members involved

---

### L3: Durable Decisions & Lessons
**Locations:** 
- `memory/decisions.md` — core lessons, rules that apply across projects
- `memory/people/<name>.md` — working preferences & communication style
- `memory/writing.md` — writing voice, tone, format preferences

**Auto-injected:** No, but loaded when needed  
**Content:** Things you've learned that should persist across sessions

**decisions.md structure:**
```markdown
---
name: Rule Name
description: One-line hook for relevance
type: feedback | user | project | reference
---

## Rule
[What to do / not do]

**Why:** [Context/incident that led to this]
**How to apply:** [When/where this matters]
```

---

### L4: Archive
**Location:** `memory/archive/YYYY-MM/`  
**Content:** Stale L3 entries, consolidated via `/consolidate` command  
**Retention:** 2 years

---

## Write Rules

✅ **DO**
- Write to L1 (session.md) automatically every session
- Write to L2/L3 **only on explicit `/remember` or "记住" signal**
- Use `/consolidate` periodically to archive stale L3 entries
- Include frontmatter (name, description, type) in L2/L3 files

❌ **DON'T**
- Auto-promote L1 → L2/L3 without user signal
- Create duplicate memories without checking first
- Save code patterns, file paths, architecture (already in codebase)
- Save git history or recent commits (use git log)
- Save ephemeral task details or debugging recipes

---

## Memory Decay & Updates

Memory becomes stale when:
- A decision changes (update the file, don't create a new one)
- A lesson proves wrong (delete and note why in Git commit)
- Context fundamentally changes (move to archive, start fresh)

**Before acting on a memory:** Verify it's still accurate by checking the current codebase or file state.

---

## See Also
- `/remember <thing>` — save to L3
- `/consolidate` — archive stale entries
- `/capture "<text>"` — quick note to L1
