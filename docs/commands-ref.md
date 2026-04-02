# Complete Commands Reference

All commands are slash-commands or invoke via skill tool. Prefix with `/`.

---

## Work Planning & Execution

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/plan <task>` | Decompose multi-step task into reviewed plan before implementing | Unclear scope, 3+ steps, architecture impact |
| `/task <intent>` | Start state-tracked task (PLANNING → EXECUTING → COMPLETED) | Need to persist progress within session |

---

## Code Review & Quality

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/review [target]` | Review file, diff, or recent changes — prompts for engine (Claude Code or Codex) | Before merging, code quality check |
| `/adversarial-review [target]` | Dual-engine: Claude + Codex blind review, side-by-side comparison | High-stakes code, architectural decisions |
| `/simplify [target]` | Review code for reuse, quality, efficiency — auto-fix issues found | After implementation, before commit |

---

## Memory & Documentation

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/remember <thing>` | Persist decision or lesson to `memory/decisions.md` | Lesson learned, rule to preserve across sessions |
| `/capture "<text>"` | Quick-capture thought/task into session memory (`memory/session.md`) | During work, quick note without leaving flow |
| `/consolidate` | Archive stale L3 memory entries to `memory/archive/` | Periodic cleanup (recommended monthly) |

---

## Communication & Calendar

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/brief [date]` | Daily brief: calendar events + email summary | Morning routine (also auto-runs 08:30 via launchd) |
| `/draft-email <desc>` | Draft email with Leo's writing preferences applied | Composing important email |

---

## Writing Pipeline

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/write <topic>` | Structured writing: Claude drafts → Codex blind review → Claude revises | Documents, blog posts, formal writing |

---

## Configuration & System

| Command | Purpose | Triggers |
|---------|---------|----------|
| `/undo-last` | Undo the most recent Reversible-class action from session | Mistake, need to roll back |

---

## Explicit Skill Invocation

These are **not slash-commands** — invoke via Skill tool when user explicitly requests Codex, Gemini, etc.

| Skill | Purpose | Triggers |
|--------|---------|----------|
| `codex` | Delegate coding task to Codex CLI for execution | User says "用 codex", "let codex", "ask codex to" |
| `codex-bridge` | Non-interactive Codex execution (review, refactor, blind test) | User says "codex bridge", "deterministic codex call" |
| `codex:rescue` | Deep investigation + explicit fix request via Codex | Stuck, need second opinion, diagnosis |
| `gemini-fallback` | Use Gemini for web search when Claude quota exhausted | User says "用 gemini", "free search" |
| `demo-builder` | Rapid web demo from Figma design, description, or screenshot | User says "demo", "figma转代码", "出个页面" |
| `research-analyst` | Technology research, competitive analysis, framework comparison | User asks for tech research, vendor comparison |
| `news-curator` | AI/data/finance news search and organization | User asks for industry news, trends, `/morning` |
| `session-summarizer` | Summarize current Claude Code session, extract decisions | User asks for recap, `/night` |
| `learn-tutor` | Tutoring for Python, SQL, LLM development | User learning in ~/learn-ai/, homework help |

---

## Invocation Rules

✅ **DO**
- Invoke `/plan`, `/remember`, `/task` proactively when scope is unclear
- Invoke `/review` before any merge
- Invoke skill-based commands **only when user explicitly asks**

❌ **DON'T**
- Auto-trigger `/write`, Codex review, or other skills without explicit user signal
- Chain more than 3 tool calls without surfacing status
- Skip review on large changes (>50 lines)

---

## See Also
- [memory-schema.md](memory-schema.md) — memory layer definitions
- [risk-model.md](risk-model.md) — permission tiers and decision framework
