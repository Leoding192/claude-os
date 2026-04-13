# Claude OS
Leo's personal Claude Code OS — version-controlled at `~/claude-os/`.
Global identity: @~/.claude/CLAUDE.md

---

## Agents

| Agent | Invoke when |
|---|---|
| `task-planner` | 3+ steps, arch impact, unclear scope |
| `impl-coder` | Plan approved, scope locked |
| `code-reviewer` | Before merging |
| `doc-writer` | Docs missing or outdated |
| `research-analyst` | Tech research, framework comparison |
| `learn-tutor` | "教我" / "解释" / "我不懂" |
| `cal-manager` | Calendar, events, reminders |
| `mail-writer` | Email — read, draft, reply, send |
| `news-curator` | AI/数据/金融 news, `/morning` |

---

## Commands

| Command | Purpose |
|---|---|
| `/plan <task>` | Decompose → wait for approval before implementing |
| `/task <intent>` | State-tracked: PLANNING → EXECUTING → COMPLETED |
| `/review [target]` | Code review |
| `/adversarial-review` | Claude + Codex blind, side-by-side |
| `/remember <thing>` | Persist to decisions.md |
| `/night` | End-of-day memory update |
| `/brief` | Calendar + email summary |
| `/morning` | News digest |

---

## Hard Rules

- **Never commit to main** — feature branches only
- **Never touch `.env` / secrets** — without explicit ask
- **Confirm before:** irreversible ops, schema changes, git push
- **Changes >50 lines** → show plan first, wait for go-ahead
- **Non-trivial task (3+ steps)** → `/plan` first, wait for go-ahead
- **Skills** → explicit invocation only, never auto-trigger

---

## Agent 调用规则

- 日程 → `cal-manager`
- 邮件 → `mail-writer`
- 资讯 → `news-curator`
- 调研 → `research-analyst`
- 学习 → `learn-tutor`
- 实现 → `impl-coder`（plan 确认后）
- 审查 → `code-reviewer`（merge 前）

---

## Memory 写入规则

只在 `/remember` 或"记住"信号时写入 L2/L3，**不自动提升**。