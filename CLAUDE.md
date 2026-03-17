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
│   ├── agents/                ← planner / coder / reviewer / documenter
│   ├── commands/              ← slash commands: /plan /review /remember
│   ├── hooks/                 ← external hook scripts (future)
│   └── skills/                ← symlinks into .agents/skills/
├── .agents/
│   └── skills/
│       └── codex/             ← Codex CLI skill (via `npx skills add`)
└── memory/
    ├── session.md             ← injected every session (current work only)
    └── decisions.md          ← long-term decisions & lessons (read on demand)
```

## Agents
| Agent | Invoke when |
|---|---|
| `planner` | 3+ steps, arch impact, unclear scope |
| `coder` | Plan approved, scope locked |
| `reviewer` | Before merging |
| `documenter` | Docs missing or outdated |

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

## Memory
| File | Injected? | Purpose |
|---|---|---|
| `memory/session.md` | ✅ Every session | Current in-progress work, blockers, next steps |
| `memory/decisions.md` | ❌ On demand | Settled decisions, lessons learned, patterns |

## Security & Governance

### Permission Tiers
| Tier | Examples | Behaviour |
|---|---|---|
| **Auto** | Read files, read email, search, git read, run codex | Execute silently |
| **Confirm** | Write/delete files, send email, send Feishu message, git push, modify calendar | Show action summary → require explicit "yes" |
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
