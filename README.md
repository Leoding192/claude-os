# Claude OS

Leo's personal AI operating system — a version-controlled configuration layer for Claude Code on macOS.

Not a coding tool. A personal assistant OS built on top of Claude Code CLI.

---

## Quick Start

```bash
# Fresh machine
git clone <this-repo> ~/claude-os
cd ~/claude-os
bash install.sh

# After any config change
bash sync.sh

# Start a session in any project
cd ~/your-project && claude
```

---

## What's Inside

```
claude-os/
├── install.sh                 ← fresh machine bootstrap
├── sync.sh                    ← sync config to ~/.claude/
├── CLAUDE.md                  ← project-level rules (loaded in claude-os sessions)
├── .mcp.json                  ← MCP server config (GitHub, Feishu, Filesystem)
├── .claude/
│   ├── settings.json          ← hooks
│   ├── agents/                ← planner / coder / reviewer / documenter
│   ├── commands/              ← /plan  /review  /remember
│   ├── skills/                ← review / debug / refactor workflows + codex
│   └── hooks/                 ← (reserved for external hook scripts)
├── .agents/skills/codex/      ← OpenAI Codex skill (via npx skills add)
└── memory/
    ├── session.md             ← injected every session (current work only)
    └── decisions.md           ← long-term decisions & lessons
```

---

## Commands (available in any session after `sync.sh`)

| Command | What it does |
|---|---|
| `/plan <task>` | Decompose task → reviewable plan → implement on approval |
| `/review [target]` | Code review with engine choice: Claude Code or Codex |
| `/remember <thing>` | Persist a decision or lesson to `memory/decisions.md` |

---

## Agents (auto-invoked by Claude Code based on task type)

| Agent | Role |
|---|---|
| `planner` | Decomposes complex tasks into executable, checkable plans |
| `coder` | Implements scoped tasks — only after a plan is approved |
| `reviewer` | Structured code review with Critical / Major / Minor severity |
| `documenter` | Writes and updates technical documentation |

---

## Hooks (active in every session)

| Event | Behaviour |
|---|---|
| Before any edit | Block if on `main` or `master` branch |
| After any edit | Auto-format (prettier / black / gofmt); warn if formatter missing |
| Session start | Inject `memory/session.md` into context |
| Session end | Remind to update `memory/session.md` |

---

## Secrets

Tokens are stored in macOS Keychain, never in files.

```bash
bash install.sh                  # first-time setup, prompts for all secrets
bash install.sh --rotate-secrets # re-enter any token
```

Services stored:
- `claude-os.github` → `GITHUB_PERSONAL_ACCESS_TOKEN`
- `claude-os.feishu` → `FEISHU_APP_ID`, `FEISHU_APP_SECRET`

---

## Extending

| What | How |
|---|---|
| New agent | `.claude/agents/<name>.md` with frontmatter `description` field |
| New command | `.claude/commands/<name>.md` |
| New skill workflow | `.claude/skills/<name>.md` |
| New MCP server | `.mcp.json` + add secret to `install.sh` |
| New hook | `.claude/settings.json` |

After any addition: run `bash sync.sh`.

---

## Roadmap

See [`docs/`](docs/) for the full system design spec (capability registry, runtime state model, recovery model, memory schema, metrics).

Current layer: **Layer 1 — Sync & Portability** ✅
Next: **Layer 2 — macOS System Integration** (Calendar, Mail, Notifications)
