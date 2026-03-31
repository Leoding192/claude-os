# Decisions & Lessons

> Long-term memory. Not injected automatically — read when relevant.
> Add entries here to avoid re-litigating settled questions.

---

## Decisions

| Decision | Rationale | Date |
|---|---|---|
| Used `.agents/skills/` as canonical skill location | `npx skills` installs here; `.claude/skills/` is a symlink | 2026-03-14 |
| Codex skill invoked via repo-local script path | Global `~/.claude/skills/` not used; skill lives in project | 2026-03-14 |
| hinf5026：Ollama 用直接 client 调用，不用 LangChain | `langchain-community` vs `langchain-ollama` 包路径不一致，混用易出错；直接 `import ollama` 更简单，LangGraph 不依赖 LangChain | 2026-03-28 |
| hinf5026：LLM JSON 输出用 `format="json"` 强制结构化 | 不加 format 参数时 Ollama 模型会在 JSON 外附加解释文字，导致 `json.loads()` 失败 | 2026-03-28 |
| hinf5026：Agent 架构用并行 fan-out + 加权 synthesis | 三个子 Agent（ICD/Medication/Note）并行，Synthesis 加权合并（ICD 50% + Med 30% + Note 20%），比顺序执行快且避免单点误判 | 2026-03-28 |

---

## Lessons Learned

| Lesson | Context |
|---|---|
| `settings.jsonclaude` naming bug | VS Code created empty file when original was deleted; always verify filenames after rename |
| Hook paths must be repo-relative | Hardcoded `~/claude-os` breaks if repo is cloned elsewhere |
