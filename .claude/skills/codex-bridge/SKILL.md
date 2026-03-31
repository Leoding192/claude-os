---
name: codex-bridge
description: 通过确定性 `codex exec` 非交互模式调用 Codex CLI，适合快速单次 review、重构分析、盲测对比。当用户说"用 codex bridge"、"确定性调用 codex"、"codex 非交互"、"/codex-bridge <任务>"时触发。不适合需要多轮对话或 codebase 级别操作（那种情况用 codex skill）。
---

# Codex Bridge — 确定性非交互调用

## 原理

不通过 `ask_codex.sh` 脚本，直接调用 `codex exec` 非交互模式。
结果捕获到临时文件，Claude Code 读取后整合到回复。
与 `codex` skill 的区别：无 session 管理，无 agent loop，适合一次性分析任务。

## 使用方式

### 单次分析（推荐）

```bash
RESULT_FILE="/tmp/codex_bridge_$(date +%s).txt"
codex exec "Your task description here" --read-only > "$RESULT_FILE" 2>&1
echo "=== Codex Bridge 结果 ==="
cat "$RESULT_FILE"
```

### 代码 review（文件作为 stdin）

```bash
RESULT_FILE="/tmp/codex_review_$(date +%s).txt"
cat /path/to/file.py | codex exec "Review this code for bugs, performance, and style issues. Be concise." --read-only > "$RESULT_FILE" 2>&1
cat "$RESULT_FILE"
```

### 带推理的 diff review

```bash
RESULT_FILE="/tmp/codex_diff_$(date +%s).txt"
git diff HEAD | codex exec "Review this diff for correctness, security issues, and edge cases. Cite file:line for each issue." --read-only > "$RESULT_FILE" 2>&1
cat "$RESULT_FILE"
```

### 盲测对比（adversarial review 用途）

```bash
# 不向 Codex 展示 Claude 的结论 — 保持盲测
RESULT_FILE="/tmp/codex_blind_$(date +%s).txt"
codex exec "$(echo "$DIFF_CONTENT")" --read-only > "$RESULT_FILE" 2>&1
CODEX_REVIEW=$(cat "$RESULT_FILE")
```

## Codex 安装

已安装：`/usr/local/bin/codex` (codex-cli 0.114.0)

如需更新：
```bash
npm install -g @openai/codex
```

## 触发词（必须明确说其中之一）

- "用 codex bridge"
- "codex 非交互模式"
- "确定性调用 codex"
- "/codex-bridge <任务描述>"
- "让 codex 看看"
- "codex review"
- "/multi-review"（此命令也走 codex-bridge 流程）

## 不适合的场景

- 需要 Codex 在 codebase 里自主探索并修改文件 → 改用 `codex` skill
- 需要多轮对话 → 改用 `codex exec resume` 或 `codex` skill
- 需要访问整个项目 → 改用 impl-coder agent
