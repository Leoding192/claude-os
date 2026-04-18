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
├── install.sh                 ← fresh machine bootstrap (includes Raycast setup)
├── sync.sh                    ← sync config to ~/.claude/
├── CLAUDE.md                  ← project-level rules (loaded in claude-os sessions)
├── .mcp.json                  ← MCP server config (GitHub, Gmail, Filesystem)
├── .claude/
│   ├── settings.json          ← hooks
│   ├── agents/                ← task-planner / impl-coder / code-reviewer / doc-writer / cal-manager / mail-writer
│   ├── commands/              ← /plan /review /remember /brief /draft-email /capture /task /consolidate
│   ├── skills/                ← review / debug / refactor workflows + codex
│   └── hooks/                 ← (reserved for external hook scripts)
├── .agents/skills/codex/      ← OpenAI Codex skill (via npx skills add)
├── raycast/                   ← Raycast script commands (add this dir in Raycast settings)
│   ├── claude-brief.sh        ← "Claude Brief" — daily calendar + email summary
│   ├── claude-capture.sh      ← "Claude Capture" — quick-capture with text input
│   └── claude-ask.sh          ← "Claude Ask" — open Claude session in Terminal
├── docs/                      ← system design specs
│   ├── capability-registry.md
│   ├── runtime-state-model.md
│   ├── automation-risk-model.md
│   ├── recovery-model.md
│   └── memory-schema.md
└── memory/
    ├── session.md             ← L1: injected every session (≤50 lines)
    ├── decisions.md           ← L3: long-term decisions & lessons
    ├── projects/              ← L2: per-project context
    ├── people/                ← L3: collaborator context
    └── archive/               ← L4: archived stale entries (2yr retention)
```

---

## Entry Points

| Entry | How | Best for |
|---|---|---|
| **Terminal** | `cd ~/claude-os && claude` | Deep work, coding, planning |
| **Raycast** | `Cmd+Shift+B` → Brief, `Cmd+Shift+Space` → Capture | Quick actions without opening Terminal |
| **Raycast "Claude Ask"** | Type a prompt in Raycast | One-off questions, opens Terminal |

### Raycast Setup
1. Open Raycast → Settings → Extensions → Script Commands
2. Click `+` → Add Script Directory → select `~/claude-os/raycast`
3. Assign shortcuts in Raycast for each command

---

## Commands (available in any session after `sync.sh`)

| Command | What it does |
|---|---|
| `/plan <task>` | Decompose task → reviewable plan → implement on approval |
| `/review [target]` | Code review with engine choice: Claude Code or Codex |
| `/remember <thing>` | Persist a decision or lesson to `memory/decisions.md` |
| `/brief [date]` | Daily brief: calendar events + email summary |
| `/draft-email <desc>` | Draft an email with writing preferences applied |
| `/capture "<text>"` | Quick-capture a thought or task into session memory |
| `/task <intent>` | Start a state-tracked task with full PLANNING → EXECUTING lifecycle |
| `/consolidate` | Archive stale L3 memory entries |

---

## Agents (auto-invoked by Claude Code based on task type)

| Agent | Role |
|---|---|
| `task-planner` | Decomposes complex tasks into executable, checkable plans |
| `impl-coder` | Implements scoped tasks — only after a plan is approved |
| `code-reviewer` | Structured code review with Critical / Major / Minor severity |
| `doc-writer` | Writes and updates technical documentation |
| `cal-manager` | Reads and manages Apple Calendar via AppleScript |
| `mail-writer` | Reads, drafts, and sends email via Gmail MCP |

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

See [`docs/`](docs/) for the full system design spec.

| Layer | Status | Description |
|---|---|---|
| Layer 1 — Sync & Portability | ✅ | `install.sh`, `sync.sh`, README |
| Capability Registry | ✅ | All capabilities catalogued with tier + reversibility |
| Security & Governance | ✅ | Permission tiers, Keychain, audit log |
| Runtime State Model | ✅ | PLANNING → EXECUTING → COMPLETED state machine |
| Automation Risk Model | ✅ | Risk scoring + execution path selection |
| Recovery Model | ✅ | Undo stack, post-incident protocol |
| Memory Schema (L0–L4) | ✅ | Layered memory with write policy + `/consolidate` |
| Layer 2 — macOS Integration | ✅ | Calendar (AppleScript), Gmail MCP, Notifications |
| Unified Entry | ✅ | Raycast scripts + keyboard shortcuts |
| Layer 4 — Proactive Execution | ✅ | `/brief` launchd schedule (08:30), `/adversarial-review`, `/write` pipeline |
| Layer 5 — Knowledge System | ⬜ | `memory/projects/`, `memory/people/`, `/consolidate` active |
