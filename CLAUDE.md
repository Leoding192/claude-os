# Claude OS

Leo's personal Claude Code configuration layer —
agents, hooks, memory, and rules, version-controlled.

## Structure
```
claude-os/
├── CLAUDE.md                  ← you are here
├── .mcp.json                  ← MCP servers
├── skills-lock.json           ← installed skill versions (auto-generated)
├── .gitignore
├── .claude/
│   ├── settings.json          ← hooks
│   ├── agents/                ← task-planner / impl-coder / code-reviewer / doc-writer / cal-manager / mail-writer
│   ├── commands/              ← slash commands: /plan /review /remember
│   ├── hooks/                 ← external hook scripts (future)
│   └── skills/                ← symlinks into .agents/skills/
├── .agents/
│   └── skills/
│       ├── codex/             ← Codex CLI skill (via `npx skills add`)
│       ├── docx/              ← Word document skill (anthropics/skills)
│       ├── pdf/               ← PDF skill (anthropics/skills)
│       ├── pptx/              ← PowerPoint skill (anthropics/skills)
│       └── xlsx/              ← Excel skill (anthropics/skills)
└── memory/
    ├── session.md             ← injected every session (current work only)
    └── decisions.md          ← long-term decisions & lessons (read on demand)
```

## Agents
| Agent | Invoke when |
|---|---|
| `task-planner` | 3+ steps, arch impact, unclear scope |
| `impl-coder` | Plan approved, scope locked |
| `code-reviewer` | Before merging |
| `doc-writer` | Docs missing or outdated |
| `cal-manager` | Calendar, events, reminders, today's agenda |
| `mail-writer` | Email — read, draft, reply, send |

## Hooks (settings.json)
| Event | Matcher | Behavior |
|---|---|---|
| `PreToolUse` | `Edit\|Write\|MultiEdit\|NotebookEdit` | Block edits on main/master |
| `PostToolUse` | `Edit\|Write\|MultiEdit` | Auto-format; warn if formatter missing |
| `UserPromptSubmit` | — | Inject `memory/session.md` (repo-relative path) |
| `Stop` | — | Remind to update `memory/session.md` |

## Commands
| Command | Purpose |
|---|---|
| `/plan <task>` | Decompose task into a reviewed plan before implementing |
| `/review [target]` | Review file, diff, or recent changes — prompts for engine (Claude Code or Codex) |
| `/remember <thing>` | Persist a decision or lesson to `memory/decisions.md` |
| `/task <intent>` | Start a state-tracked task (PLANNING → EXECUTING → COMPLETED) |
| `/undo-last` | Undo the most recent Reversible-class action |
| `/consolidate` | Archive stale L3 memory entries |
| `/brief [date]` | Daily brief: calendar events + email summary (also runs automatically at 08:30 via launchd) |
| `/draft-email <desc>` | Draft an email with writing preferences applied |
| `/capture "<text>"` | Quick-capture a thought/task into session memory |
| `/adversarial-review [target]` | Dual-engine review: Claude + Codex blind, side-by-side comparison |
| `/write <topic>` | Writing pipeline: draft → Codex blind review → revised output |

## Memory
| Layer | Location | Injected? | Purpose |
|---|---|---|---|
| L1 | `memory/session.md` | ✅ Every session | Current work state (≤50 lines) |
| L2 | `memory/projects/<name>.md` | ❌ On demand | Per-project decisions and context |
| L3 | `memory/decisions.md`, `memory/people/`, `memory/writing.md` | ❌ On demand | Durable decisions, people context, writing style |
| L4 | `memory/archive/YYYY-MM/` | ❌ Never | Archived stale L3 entries (retained 2 years) |

**Write rule:** Only write to L1–L3 on explicit `/remember` or "记住" signal. Never auto-promote.

See full spec: [docs/memory-schema.md](docs/memory-schema.md)

## Orchestration Rules

Before starting any multi-step task:
1. Write `~/claude-os/logs/current-task.json` with state PLANNING (use `/task` command)
2. Produce a plan, wait for user approval before changing state to EXECUTING
3. Before any Confirm-tier capability: set state AWAITING_CONFIRMATION, surface the action, require explicit "yes"
4. On completion: append to `logs/tasks.jsonl`, delete `current-task.json`
5. On session end with incomplete task: Stop hook auto-writes CANCELLED to `tasks.jsonl`
6. Never chain more than 3 tool calls without surfacing status to user
7. On unrecoverable error: set state FAILED, surface clearly, do not retry silently

See full spec: [docs/runtime-state-model.md](docs/runtime-state-model.md)

## Automation Risk Model

Before invoking any capability:
1. Look up `capability_id` in `docs/capability-registry.md` — if not found, hard block
2. If registered tier is **Blocked**, hard block regardless of context
3. Compute `risk_score = max(blast_radius, reversibility) * 0.5 + confidence_uncertainty * 0.3 + external_side_effect * 0.2`
4. Apply floor rule: execution path = max(computed_path, registered_tier_floor)
5. Execute path:
   - Score 0.0–0.3 → **Auto** (silent)
   - Score 0.4–0.6 → **Confirm** (surface summary, require "yes")
   - Score 0.7–1.0 → **Escalate** (do not attempt; ask user to confirm intent first)
6. When intent is inferred rather than explicit, add confidence_uncertainty = 0.5–1.0

See full spec: [docs/automation-risk-model.md](docs/automation-risk-model.md)

## Security & Governance

### Permission Tiers
| Tier | Examples | Behaviour |
|---|---|---|
| **Auto** | Read files, read email, search, git read, run codex | Execute silently |
| **Confirm** | Write/delete files, send email, git push, modify calendar | Show action summary → require explicit "yes" |
| **Blocked** | Push to main, touch .env/secrets, write prod config | Hard block, never execute |

All capabilities are catalogued in [docs/capability-registry.md](docs/capability-registry.md).

### Audit Log
Confirm-tier Bash operations are logged to `logs/audit.jsonl` automatically via PostToolUse hook.
Format: `{ timestamp, tool, action, result, confirmed_by_user }`

## Extending
- New agent → `.claude/agents/<name>.md` with frontmatter `description`
- New hook → `.claude/settings.json`
- New command → `.claude/commands/<name>.md`
- New skill → `npx skills add <repo>`
- New MCP → `.mcp.json`
- New capability → `docs/capability-registry.md` (register before implementing)
