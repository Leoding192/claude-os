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

---

## OS 2.0 升级记录（2026-04-09）

### Agents：从 6 → 10

| 新增 Agent | 模型 | 用途 |
|---|---|---|
| `news-curator` | Haiku 4.5 | AI/数据/金融资讯搜索，/morning 命令触发 |
| `session-summarizer` | Haiku 4.5 | 对话总结，/night 命令触发 |
| `research-analyst` | Sonnet 4.6 | 技术调研、竞品分析、论文阅读 |
| `learn-tutor` | Sonnet 4.6 | Python/SQL/LLM 学习辅导，~/learn-ai/ 下触发 |

**模型路由原则确立：** Opus 4.6 → 深度推理（task-planner/code-reviewer）；Sonnet 4.6 → 实现/研究；Haiku 4.5 → 轻量 IO（cal/mail/news/summarizer）

### Hooks：扩展到 6 种事件类型

| 新增 Hook | 作用 |
|---|---|
| `SessionStart` | 注入日期 + session.md + git log，确保每次对话有上下文 |
| `PreCompact` | 压缩前重新注入 session 上下文，防止长对话丢失状态 |
| `Stop×4` | session更新提醒 + task跟踪 + remember提醒 + auto-memory.py |
| `PostToolUse` audit | Confirm-tier Bash 操作写入 audit.jsonl |

### Plugins：新增 3 个

- `claude-hud@claude-hud` — 状态栏实时显示 token/成本/模型
- `telegram@claude-plugins-official` — Telegram 消息收发
- `codex@openai-codex` — OpenAI Codex CLI 集成

### Skills：从 5 → 26+

- 新增 **21 个 impeccable UI 设计技能**（pbakaus/impeccable）：adapt/animate/audit/colorize/critique/delight/distill/frontend-design 等
- 文件技能保留：docx/pdf/pptx/xlsx/codex

### MCP：6 个服务

`github`（npx）/ `gmail`（Claude.ai 内置）/ `figma`（Remote HTTP）/ `filesystem`（npx）/ `apple-calendar`（AppleScript）/ `notifications`（osascript）

### 自动化：auto-memory.py

Stop hook 在每次对话结束时：① 更新 session.md 的 Active Project + Last Session；② 扫描 JSONL 提取含决策关键词的文本追加到 decisions.md；③ 写运行日志到 logs/memory-auto.log

## 2026-04-12 自动提取（JSONL）
- [2026-04-12][dingfuying] 探索完毕。发现 3 个与描述不符的现实，在出 plan 前必须先和你对齐。先把它们列给你看，再根据你的答复决定 plan 细节。  **发现的 3 个偏差：**  1. **`~/.claude/me

## 2026-04-13 自动提取（JSONL）
- [2026-04-13][dingfuying] `~/.claude` 不是 git repo，只有 `~/claude-os` 是。确认一下：你说的 `claude/claude.md` 的变更，是指 `~/claude-os/CLAUDE.md
