# Decisions & Lessons

> Long-term memory. Not injected automatically — read when relevant.
> Add entries here to avoid re-litigating settled questions.

---

## Decisions

| Decision | Rationale | Date |
|---|---|---|
| Used `.agents/skills/` as canonical skill location | `npx skills` installs here; `.claude/skills/` is a symlink | 2026-03-14 |
| Codex skill invoked via repo-local script path | Global `~/.claude/skills/` not used; skill lives in project | 2026-03-14 |

---

## Lessons Learned

| Lesson | Context |
|---|---|
| `settings.jsonclaude` naming bug | VS Code created empty file when original was deleted; always verify filenames after rename |
| Hook paths must be repo-relative | Hardcoded `~/claude-os` breaks if repo is cloned elsewhere |
