# Claude OS 架构审查报告
日期：2026-03-27

## 一句话结论

Claude OS 整体架构设计合理、层次清晰，但存在两类核心问题：CLAUDE.md 中多个关键文档引用（capability-registry、runtime-state-model 等）的规范定义了但 agents 并未实际执行；L2/L3/L4 memory 层基本为空壳，与设计意图脱节。（settings.json 双份已验证为非缺陷，见 §3。）

---

## 模块审查

### 1. Agents（`~/.claude/agents/`）

#### 现状

共 10 个 agent，覆盖任务规划、代码、文档、日程、邮件、资讯、学习辅导、调研、对话总结。

| Agent | model | 输出分级 | memory 维护 | 备注 |
|---|---|---|---|---|
| cal-manager | sonnet | 有（表格中标注 Confirm tier） | 无 | 内置 AppleScript 示例 |
| code-reviewer | opus | 有（APPROVE/APPROVE WITH NOTES/REQUEST CHANGES） | 有 | 质量最高 |
| doc-writer | sonnet | 无明确分级 | 无 | 缺少风险感知 |
| impl-coder | sonnet | 无明确分级 | 无 | 有 Verification 章节作为补偿 |
| learn-tutor | sonnet | 无明确分级 | 有 | 纯教学场景，风险低 |
| mail-writer | sonnet | 有（Confirm/Auto 表格） | 无 | 有但格式混杂 |
| news-curator | sonnet | 无明确分级 | 有 | 纯读取，风险低 |
| research-analyst | sonnet | 无明确分级 | 有 | 纯读取，风险低 |
| session-summarizer | sonnet | 无明确分级 | 有 | 纯读写 memory，风险低 |
| task-planner | opus | 无明确分级 | 有 | 不执行操作，风险低 |

**问题**

1. **输出分级覆盖不完整。** `doc-writer` 和 `impl-coder` 是最容易写错文件的两个 agent，但两者都没有明确标注 Confirm/Auto/Escalate 分级。`impl-coder` 有 Write 工具权限，在没有分级约束的情况下可能静默修改不该改的文件。

2. **model 分配基本合理，但有一处可优化。** `task-planner` 使用 opus（正确，规划场景需要推理质量）；`code-reviewer` 使用 opus（正确）。其余均为 sonnet。`impl-coder` 是否值得提升到 opus 取决于代码复杂度，当前 sonnet 配置属于合理的成本/质量权衡。

3. **memory 维护不统一。** `cal-manager`、`doc-writer`、`impl-coder`、`mail-writer` 没有任何 Memory Maintenance 指令。这意味着这四个 agent 用完即忘，无法积累上下文（如 cal-manager 无法记住常用日历名、doc-writer 无法记住文档风格偏好）。

4. **cal-manager 的 AppleScript 模板冗余。** agent prompt 中内嵌了完整的 AppleScript 代码块（约 40 行），这些模板几乎不会变化，但每次调用都消耗 token。更好的方式是在 agent 外部维护脚本文件，prompt 只保留调用路径。

5. **morning/night 命令与 session-summarizer/news-curator agents 存在功能重叠但设计不对称。** `morning.md` 命令明确标注"直接执行，不调用 subagent"并有更严格的搜索次数限制（≤4次）；`news-curator` agent 则允许 3-5 次搜索。两者的输出格式相似但不完全一致，存在行为不一致风险。

**建议**

- 给 `doc-writer` 和 `impl-coder` 添加能力风险标注（至少在 Rules 中明确"文件写入前需确认路径"）
- 给 `cal-manager`、`mail-writer`、`doc-writer`、`impl-coder` 补充 Memory Maintenance 章节
- 将 `cal-manager` 中的 AppleScript 示例移至 `~/claude-os/docs/` 或外部脚本，prompt 仅保留引用路径
- 统一 `morning.md` 和 `news-curator` 的搜索上限和输出格式，或明确说明两者的差异定位

---

### 2. Commands（`~/claude-os/.claude/commands/`）

#### 现状

共 13 个命令，覆盖任务规划、代码审查、邮件、写作、memory 管理等核心场景。

| Command | Steps 明确 | Output 定义 | Edge Case 处理 |
|---|---|---|---|
| /plan | 是（委托 task-planner） | 是 | 无（空输入时无提示） |
| /review | 是 | 是（完整格式） | 是（空 diff、Codex 不可用） |
| /adversarial-review | 是 | 是 | 是（diff < 20 行、Codex 不可用） |
| /task | 是（6步状态机） | 是（JSON schema） | 是（FAILED/CANCELLED） |
| /remember | 是 | 是 | 否（无法处理不匹配类型） |
| /undo-last | 是 | 是 | 是（空栈、用户拒绝） |
| /consolidate | 是 | 是 | 是（不删除、不归档当月） |
| /brief | 是 | 是（固定格式） | 是（Calendar/Gmail 不可用） |
| /draft-email | 是 | 是 | 是（收件人未知时阻止） |
| /write | 是 | 是 | 是（Codex 不可用降级） |
| /capture | 是 | 是 | 是（空输入询问、50行警告） |
| /morning | 是 | 是 | 否（无错误处理） |
| /night | 是 | 是 | 否（无错误处理） |

**问题**

1. **/plan 命令缺少 edge case 处理。** `/plan` 直接将 `$ARGUMENTS` 传给 task-planner，若参数为空，没有任何提示或 fallback，task-planner 将面对空输入。对比 `/capture` 的"If empty, ask: What do you want to capture?"处理更完善。

2. **/morning 和 /night 命令没有错误处理。** 这两个命令在写入 `outbox/daily/` 时，如果目录不存在或写入失败，没有任何 fallback 说明。对比 `/brief` 明确说明"Calendar unavailable → skip section, note why"，差距明显。

3. **/remember 命令功能定义过于宽泛。** 仅分了"decision"和"lesson"两种类型，但实际使用中可能需要存储"规范约定"、"工具使用偏好"等。而且没有说明如果 `decisions.md` 不存在时如何创建。

4. **/undo-last 引用了 `docs/recovery-model.md` 但该文件不在任何 agent 的 tools 列表中。** 命令第4步说"see docs/recovery-model.md for the mapping"，但没有明确谁负责读这个文件，实际执行时大概率会直接跳过。

5. **`/task` 命令中 tasks.jsonl 的路径硬编码为绝对路径。** `tasks.jsonl` append 脚本中写死了 `/Users/dingfuying/claude-os/logs/tasks.jsonl`，这与 decisions.md 中记录的 lesson（"Hook paths must be repo-relative"）直接矛盾。这是一个已知但未修复的技术债。

**建议**

- `/plan` 添加：若 `$ARGUMENTS` 为空，提示"What task do you want to plan?"
- `/morning` 和 `/night` 添加写入失败的 fallback（至少输出到终端）
- `/task` 中的 `tasks.jsonl` 路径改为通过 `git rev-parse --show-toplevel` 动态获取
- `/undo-last` 明确由哪个 agent/工具负责读取 `docs/recovery-model.md`

---

### 3. Hooks（settings.json）

#### 现状

**已验证：双份 settings.json 是非缺陷，架构正确。** `sync.sh` 实现字段级 merge 逻辑：`~/claude-os/.claude/settings.json` 是 hooks 的唯一真相（repo source of truth），`sync.sh` 运行时将其 `hooks` 字段覆盖写入全局 `~/.claude/settings.json`，同时保留全局版中的 `mcpServers`、`statusLine`、`enabledPlugins` 等其他字段。两份文件内容相同是 sync 的预期产物，不是漂移。**修改 hooks 的正确姿势：改 repo 版 → 跑 `./sync.sh`。**

hooks 覆盖情况：

| 事件 | 实际行为 | 评价 |
|---|---|---|
| SessionStart | 注入日期+session.md+recent git log | 有效 |
| PreToolUse [1] | 阻止 main/master 直接 edit | 有效 |
| PreToolUse [2] | 阻止写入 .env/secrets 等敏感路径 | 有效 |
| PostToolUse [Edit/Write] | 自动格式化（prettier/black/gofmt/shfmt） | 有效 |
| PostToolUse [Edit/Write] | 自动运行同名 Jest 测试文件 | 有效但覆盖窄 |
| PostToolUse [Bash] | audit log 记录 Confirm-tier 操作 | 有效但模式匹配粗糙 |
| UserPromptSubmit | 注入 session.md | 有效 |
| Stop [1] | 自动清理并 carry-forward session.md | 有效 |
| Stop [2] | 写 CANCELLED 到 tasks.jsonl | 有效 |
| Stop [3] | 提示 /remember | 有效 |
| PreCompact | 备份 session.md | 有效 |

**问题**

1. **PostToolUse [Bash] 的 audit log 依赖关键词模式匹配，可靠性低。** 当前只匹配 `git push`, `git reset --hard`, `rm -rf`, `send`, `delete` 等固定字符串。这意味着：
   - `osascript` 操作日历（Confirm-tier）不会被记录
   - `gmail_create_draft` 等 MCP 工具调用不是 Bash，不会被记录
   - 某些危险操作（如 `truncate table`）没有匹配规则

3. **PostToolUse 的 Jest 测试 hook 仅覆盖 `.ts/.tsx/.js/.jsx`，且需要 testfile 与源文件同目录同名。** 这在 Next.js 项目的典型测试结构（`__tests__/` 目录）中不会触发。

4. **`PreCompact` hook 使用硬编码的 `~/claude-os/` 路径**，与上述已记录的 lesson 矛盾，在非 claude-os 目录工作时会误操作或静默失败。

5. **缺少 `NotebookEdit` 在文件保护 hook 中的对称覆盖。** 第一个 PreToolUse hook 匹配 `Edit|Write|MultiEdit|NotebookEdit`（阻止 main 分支），但第二个文件保护 hook 只匹配 `Edit|Write|MultiEdit`，`NotebookEdit` 不受路径保护规则约束。

**建议**

- audit log 改为记录所有 Bash 命令，而不是依赖关键词过滤（用 `confirmed_by_user: false` 标记 Auto-tier）
- `PreCompact` 路径改用动态 git root 探测

---

### 4. Memory（`~/claude-os/memory/`）

#### 现状

| 层 | 文件/目录 | 实际状态 |
|---|---|---|
| L1 session.md | `/memory/session.md` | 有内容，26行，符合≤50行要求 |
| L2 projects/ | `/memory/projects/` | 仅 `.gitkeep`，**完全为空** |
| L3 decisions.md | `/memory/decisions.md` | 有内容，2个决策+2个教训，非常稀疏 |
| L3 writing.md | `/memory/writing.md` | 有内容，仅覆盖作业/学术写作场景 |
| L3 people/ | `/memory/people/` | 仅 `.gitkeep`，**完全为空** |
| L4 archive/ | `/memory/archive/` | 仅 `.gitkeep`，从未使用 |

**问题**

1. **L2 projects/ 完全为空，但 CLAUDE.md 定义了完整的 L2 使用规范。** 6 个 Phase 3 agents（news-curator、session-summarizer、research-analyst、learn-tutor、cal-manager、mail-writer）都有 Memory Maintenance 指令，但实际 agent memory 存储在哪里不明确。CLAUDE.md 说 L2 是"Per-project decisions and context"，但实际上这些 agents 的记忆应该存在 agent 专属 memory（`~/.claude/agent-memory/<name>/`）而非 L2，两套系统存在设计混淆。

2. **decisions.md 极度稀疏，与系统已运行时长不匹配。** 只有 2 个决策、2 个教训，均来自 2026-03-14。这说明 `/remember` 命令几乎没有被实际使用，或用户习惯了直接在会话中解决问题而不持久化。

3. **L3 writing.md 只覆盖了"作业/学术写作"，缺少日常工程写作、邮件、技术文档等场景。** mail-writer 明确引用 `memory/writing.md` 来应用写作偏好，但当前文件内容对邮件场景完全无用（不包含邮件语气、签名、格式偏好）。

4. **L3 people/ 为空，但 mail-writer 和某些工作流依赖联系人上下文。** 如果要给已知联系人发邮件，目前没有任何地方存储其邮件地址、关系、沟通偏好等。

5. **session.md 的 L1 内容精简良好**（26行），但"Next Up"中的两个任务（`/adversarial-review test` 和 `/write test`）看起来是测试条目，应在完成测试后清理。

6. **L4 archive 从未被使用，但这是正常的**——系统相对年轻，L3 内容还不需要归档。问题在于 `/consolidate` 命令的触发条件（"L3 total entries exceed 200"）在当前仅 4 条的情况下完全不可达。

**建议**

- 澄清 agent memory（`~/.claude/agent-memory/<name>/`）与 L2（`memory/projects/`）的边界：前者是 agent 的跨会话积累，后者是项目维度的决策记录，两者不应混用
- 为 `memory/writing.md` 增加邮件和工程写作场景的偏好记录
- 为 `memory/people/` 创建至少一个模板文件，说明结构（如 `alex.md` 示例），降低使用门槛
- 将 session.md 中的测试性 Next Up 条目清理

---

### 5. 整体系统缺口

1. **capability-registry.md 的引用链未闭合。** CLAUDE.md 的"Automation Risk Model"章节要求所有能力必须在 `docs/capability-registry.md` 中注册后才能调用，但没有任何 agent 的 prompt 中有"查询 capability-registry"的步骤。这个风险模型是文档规范而非运行时约束。

2. **`docs/runtime-state-model.md` 定义的任务状态机仅在 `/task` 命令中落地，其他多步命令（如 `/adversarial-review`、`/write`）不走这套状态管理。** 实际上 `/task` 命令使用频率未知，而大多数任务直接由 CLAUDE.md 的 workflow 规则驱动。

3. **outbox 目录存在但无维护机制。** `/morning` 和 `/night` 命令会向 `~/claude-os/outbox/daily/` 写入文件，但没有任何清理、归档、或查询机制。随着时间积累会成为垃圾目录。

4. **Telegram 集成只在 ~/.claude/settings.json 中启用插件，但没有对应的 agent 或命令定义。** 目前 Telegram 消息通过 MCP 工具直接处理，没有专门的 telegram-agent 来过滤或路由消息。

5. **`/morning` 命令设计为"也在 08:30 via launchd 自动运行"，但没有任何 launchd plist 文件或相关自动化脚本在 claude-os 目录中。** 这个功能可能从未实现，仅存在于 CLAUDE.md 文档中。

---

## 优先行动清单（Top 5）

### ~~1. 合并双份 settings.json~~ — 已验证：非缺陷，无需修改

`sync.sh` 已实现字段级 merge，repo 版是 hooks 源头，全局版是 sync 产物。架构正确。

---

### 1. ✅ 给 impl-coder 和 doc-writer 补充风险分级（已完成 2026-03-28）

**问题：** 这两个 agent 有文件写入权限，但没有 Auto/Confirm/Escalate 分级说明，存在静默写入风险。
**行动（已完成）：** 在两个 agent 的 Rules 章节添加了 Risk Tiers 表格：
- 写入新文件 → Confirm（显示路径，等确认）
- 覆盖已有文件 → Confirm
- 删除文件 → Escalate

---

### 2. 补充 memory/writing.md 和 memory/people/ 内容（中优先级、高影响、低风险）

**问题：** mail-writer 依赖 `writing.md`，但文件只覆盖学术场景；`people/` 完全为空导致邮件相关工作流必须每次重新输入联系人信息。
**行动：** 在 `writing.md` 增加邮件和日常工程写作偏好；在 `people/` 创建第一个联系人文件（如常联系的人），建立模式。

---

### 3. ✅ 修复硬编码绝对路径（已完成 2026-03-28）

**问题：** `task.md` 的 append 脚本和 `PreCompact` hook 硬编码 `/Users/dingfuying/claude-os/`，在任何 clone/迁移后会静默失败。
**行动（已完成）：**
- `task.md`：Python 代码改用 `subprocess.run(['git', 'rev-parse', '--show-toplevel'])` 动态获取 root
- `settings.json` PreCompact：改用 `root=$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/claude-os")`

---

### 4. ✅ 给 morning/night/plan 命令添加错误处理和空输入检查（已完成 2026-03-28）

**问题：** `/morning` 和 `/night` 写入 `outbox/daily/` 没有 fallback；`/plan` 空输入时无提示。
**行动（已完成）：**
- `morning.md` Step 4：写入前 `mkdir -p ~/claude-os/outbox/daily/`，写入失败则输出到终端 + warn 提示
- `night.md` Step 3：同上
- `plan.md`：开头添加空输入检查，提示"What task do you want to plan?"
- outbox 清理机制仍待办（`/consolidate` 归档扩展）

---

## 信息源

所有分析基于直接读取以下文件：

- `/Users/dingfuying/.claude/agents/*.md`（10 个 agent）
- `/Users/dingfuying/claude-os/.claude/commands/*.md`（13 个命令）
- `/Users/dingfuying/.claude/settings.json`（全局 hooks）
- `/Users/dingfuying/claude-os/.claude/settings.json`（项目 hooks，与全局版相同）
- `/Users/dingfuying/claude-os/memory/session.md`
- `/Users/dingfuying/claude-os/memory/decisions.md`
- `/Users/dingfuying/claude-os/memory/writing.md`
- `/Users/dingfuying/claude-os/second-brain/profile.md`
- `/Users/dingfuying/claude-os/CLAUDE.md`

## 下一步建议

1. 用 2 小时执行 Top 5 中的第 1、4 项（技术债清除，成本低收益高）
2. 用一个 session 专门补充 memory 内容（writing.md + people/）
3. 建立季度 `/consolidate` 习惯，当 decisions.md 积累到 20+ 条时运行
4. 确认 launchd 自动运行 `/morning` 的状态：如果未实现，从 CLAUDE.md 中删除该说明，避免文档-现实不符
