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
**Quick:** Only write to L1–L3 on explicit `/remember` or "记住" signal. Never auto-promote.

See full spec: [docs/memory-schema.md](docs/memory-schema.md) — L1–L4 layer definitions, write rules, decay policy

## Orchestration Rules

Before starting any multi-step task:
1. Use `/task` command to track state (PLANNING → EXECUTING → COMPLETED)
2. Produce a plan, wait for user approval before executing
3. Never chain >3 tool calls without surfacing status
4. On unrecoverable error: surface clearly, do not retry silently

## Risk Model & Permission Tiers

**Quick:** Auto / Confirm / Blocked — see [docs/risk-model.md](docs/risk-model.md) for scoring formula, permission tiers, and audit logging

## Commands & Skills

See [docs/commands-ref.md](docs/commands-ref.md) for complete reference:
- Work planning: `/plan`, `/task`
- Code quality: `/review`, `/adversarial-review`, `/simplify`
- Memory: `/remember`, `/capture`, `/consolidate`
- Communication: `/brief`, `/draft-email`
- Writing: `/write`
- Explicit skills: `codex`, `gemini-fallback`, `demo-builder`, `research-analyst`, etc.

## Extending
- New agent → `.claude/agents/<name>.md` with frontmatter `description`
- New hook → `.claude/settings.json`
- New command → `.claude/commands/<name>.md`
- New skill → `npx skills add <repo>`
- New MCP → `.mcp.json`
- New capability → `docs/capability-registry.md` (register before implementing)

---

## Agent 调用规则
- 日程管理：使用 cal-manager agent，不要用内置 scheduler
- 邮件操作：使用 mail-writer agent，不要用内置 mailer
- 资讯搜索：使用 news-curator agent（Phase 3 添加）
- 对话总结：使用 session-summarizer agent（Phase 3 添加）
- 技术调研：使用 research-analyst agent（Phase 3 添加）
- 学习辅导：使用 learn-tutor agent（Phase 3 添加）
