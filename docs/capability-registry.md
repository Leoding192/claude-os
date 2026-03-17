# Capability Registry

Authoritative catalog of every capability claude-os can invoke.
Each entry defines tier, reversibility class, and valid entry points.

**Rule:** No capability may be invoked unless it appears in this registry.
**Rule:** New capabilities must be registered here before implementation begins.

---

## Tiers

| Tier | Behaviour |
|---|---|
| **Auto** | Execute silently, no user confirmation required |
| **Confirm** | Surface action summary to user, require explicit "yes" before proceeding |
| **Blocked** | Hard block regardless of context; never execute automatically |

## Reversibility Classes

| Class | Definition |
|---|---|
| **Reversible** | Can be undone automatically with no data loss (e.g. git checkout, delete calendar event) |
| **Compensatable** | Cannot be undone, but a corrective action mitigates harm (e.g. send a follow-up email) |
| **Irreversible** | Cannot be undone and no corrective action fully restores prior state |
| **—** | Read-only; no state mutation, recovery not applicable |

---

## Registry

### File System

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_file` | filesystem MCP | Auto | — | any |
| `write_file` | filesystem MCP | Confirm | Reversible (git) | any edit tool |
| `delete_file` | filesystem MCP | Confirm | Reversible (git / Time Machine) | explicit instruction only |
| `search_files` | filesystem MCP | Auto | — | any |

### Git

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `git_read` | Bash (git log/diff/status) | Auto | — | any |
| `git_commit` | Bash (git commit) | Auto | Reversible (git reset) | explicit instruction |
| `git_push` | Bash (git push) | Confirm | Compensatable | explicit instruction |
| `git_push_main` | Bash | Blocked | Irreversible | never |
| `git_reset_hard` | Bash | Confirm | Irreversible | explicit instruction only |

### Email (Gmail)

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_email` | Gmail MCP | Auto | — | /brief, natural language |
| `search_email` | Gmail MCP | Auto | — | /brief, natural language |
| `draft_email` | Gmail MCP (mailer agent) | Auto | Reversible (delete draft) | /draft-email |
| `send_email` | Gmail MCP (mailer agent) | Confirm | Compensatable | explicit instruction only |

### Calendar

Implemented via AppleScript through the Bash tool. Calendar.app must be running.

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_calendar` | scheduler agent (osascript) | Auto | — | /brief, natural language |
| `create_calendar_event` | scheduler agent (osascript) | Confirm | Reversible (delete event) | natural language |
| `delete_calendar_event` | scheduler agent (osascript) | Confirm | Irreversible | explicit instruction only |
| `update_calendar_event` | scheduler agent (osascript) | Confirm | Reversible (restore original) | natural language |


### Clipboard

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_clipboard` | Clipboard MCP | Auto | — | any |
| `write_clipboard` | Clipboard MCP | Confirm | Reversible (prior content lost) | explicit instruction |

### Codex

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `run_codex` | Codex skill (ask_codex.sh) | Auto | Reversible (git) | "用 codex 来..." / "ask codex to..." |
| `run_codex_readonly` | Codex skill --read-only | Auto | — | "用 codex 来分析..." |

### System & Secrets

Notifications via osascript (no MCP server needed).

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `send_notification` | Bash (osascript) | Auto | — | any |
| `read_env_var` | Bash (env) | Auto | — | any |
| `write_env_file` | Bash | Blocked | — | never |
| `read_keychain` | Bash (security) | Auto | — | install.sh / MCP startup only |
| `write_keychain` | Bash (security) | Confirm | Reversible (delete entry) | install.sh --rotate-secrets only |
| `read_prod_config` | any | Blocked | — | never |
| `write_prod_config` | any | Blocked | — | never |

---

## Changelog

| Date | Change |
|---|---|
| 2026-03-16 | Initial registry — Layer 0 + Layer 2–3 planned capabilities |
| 2026-03-16 | Layer 2: Calendar (osascript), Notifications (osascript), Gmail (Claude.ai built-in) — implementation details added |
| 2026-03-17 | Removed Feishu and 163邮箱; email integration is Gmail only (Claude.ai built-in) |
