# Claude OS

Leo's personal Claude Code configuration layer —
agents, hooks, memory, and rules, version-controlled.

## Structure
```
claude-os/
├── CLAUDE.md                  ← you are here
├── .mcp.json                  ← MCP servers
├── .claude/
│   ├── settings.json          ← hooks
│   ├── agents/                ← planner / coder / reviewer / documenter
│   ├── commands/              ← slash commands
│   ├── hooks/                 ← external hook scripts
│   └── skills/                ← reusable workflows
└── memory/
    └── context.md             ← read this first every session
```

## Agents
| Agent | Invoke when |
|---|---|
| `planner` | 3+ steps, arch impact, unclear scope |
| `coder` | Plan approved, scope locked |
| `reviewer` | Before merging |
| `documenter` | Docs missing or outdated |

## Hooks (settings.json)
| Event | Behavior |
|---|---|
| `PreToolUse` | Block edits on main/master |
| `PostToolUse` | Auto-format (prettier/black/gofmt) |
| `UserPromptSubmit` | Inject memory/context.md |
| `Stop` | Remind to update context.md |

## Extending
- New agent → `.claude/agents/<name>.md` with frontmatter `description`
- New hook → `.claude/settings.json`
- New command → `.claude/commands/<name>.md`
- New MCP → `.mcp.json`