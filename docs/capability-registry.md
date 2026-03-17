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

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_calendar` | Calendar MCP (scheduler) | Auto | — | /brief, natural language |
| `create_calendar_event` | Calendar MCP (scheduler) | Confirm | Reversible (delete event) | natural language |
| `delete_calendar_event` | Calendar MCP (scheduler) | Confirm | Irreversible | explicit instruction only |
| `update_calendar_event` | Calendar MCP (scheduler) | Confirm | Reversible (restore original) | natural language |

### Feishu / Lark

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `read_feishu_message` | Feishu MCP | Auto | — | natural language |
| `read_feishu_doc` | Feishu MCP | Auto | — | natural language |
| `send_feishu_message` | Feishu MCP | Confirm | Compensatable | explicit instruction only |
| `create_feishu_doc` | Feishu MCP | Confirm | Reversible (delete doc) | explicit instruction |
| `write_feishu_doc` | Feishu MCP | Confirm | Compensatable | explicit instruction only |

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

| capability_id | agent / tool | tier | reversibility | valid entry points |
|---|---|---|---|---|
| `send_notification` | Notifications MCP | Auto | — | any |
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
