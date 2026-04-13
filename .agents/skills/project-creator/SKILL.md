---
name: project-creator
description: Sets up a new Claude Code project from scratch: creates the directory, initializes git, creates a feature branch, runs /init to scaffold CLAUDE.md, then guides the user through editing it with project-specific rules, key paths, and todos. Use this whenever the user says "新建项目", "创建项目", "new project", "start a project", "set up a new repo", or wants to bootstrap a Claude Code-compatible project. Also use it when a project directory exists but has no CLAUDE.md yet.
---

# Project Creator

Bootstraps a new Claude Code project with the right structure so every future session starts with full context.

## Why this matters

A well-written CLAUDE.md is the difference between CC being helpful from message 1 vs. needing 10 messages of re-explaining. The goal is to front-load everything CC needs: what the project is, what rules apply, what files matter, what's next.

## The workflow

### Step 1 — Ask for the basics (if not already given)

Before touching the filesystem, collect:
- **Project name** (will become the directory name under `~/projects/`)
- **What it's for** (1 sentence)
- **Tech stack** (Python / TypeScript / etc.)
- **Any deadline or special constraints?**

If the user already gave this info, skip the questions and proceed.

**If there's a deadline, ask ≤3 questions max, then use sensible defaults for everything else.** Time-boxed projects lose more to back-and-forth than to imperfect defaults. State what defaults you're using so the user can correct if needed.

---

### Step 2 — Create the directory and git repo

```bash
mkdir ~/projects/<project-name>
cd ~/projects/<project-name>
git init
git checkout -b main
git checkout -b setup/init
```

Always start on a feature branch — never work directly on main.

---

### Step 3 — Run /init (if the directory has existing code)

If the directory already has source files, a `package.json`, or a `pyproject.toml`, run `/init` to scaffold a CLAUDE.md draft:

> "I'll run `/init` now to scan the directory and generate a CLAUDE.md draft. It'll be a starting point — we'll customize it right after."

**Skip `/init` if the directory is empty** — the output would just be noise. Write the CLAUDE.md directly in Step 4 instead.

---

### Step 4 — Edit CLAUDE.md to match the project

The generated draft will be generic. Replace or augment it with this structure:

```markdown
# <Project Name>

## 项目信息
- 背景 / 目标 / deadline
- 技术栈：...
- GitHub：... (if applicable)

## 项目特有规则
- Any domain-specific constraints (e.g., "含'作业'关键词时只做要求的")
- Data privacy rules
- Evaluation constraints (e.g., "评估集 held-out only")

## 关键路径 & 数据
| 文件 | 说明 |
|------|------|
| ...  | ...  |

## 待办事项
- [ ] First task
- [ ] Second task
```

**Do NOT add `@~/claude-os/CLAUDE.md`** — the global `~/.claude/CLAUDE.md` already imports it. Adding it again is redundant and wastes context.

Ask the user to fill in anything you don't know (deadline, key file paths, special rules). Don't invent content.

---

### Step 5 — Python project? Set up the environment

If the tech stack is Python:

```bash
cd ~/projects/<project-name>
python -m venv .venv
echo ".venv/" >> .gitignore
echo "__pycache__/" >> .gitignore
```

Tell the user to activate with `source .venv/bin/activate` before installing packages.

---

### Step 6 — Commit and merge

```bash
git add CLAUDE.md .gitignore
git commit -m "chore: init project with CLAUDE.md"
git checkout main
git merge setup/init
```

---

## Output to the user

When done, output a **standardized summary card** in this exact format:

```
项目：<name>
路径：~/projects/<name>
Stack：<stack>
入口：<main entry file, e.g. src/main.py or src/index.ts>
测试：<test command, e.g. pytest or npm test>
下一步：<first todo item>
```

Keep it to this card only — the user can open the file if they want details.

---

## Edge cases

- **Directory already exists**: Ask before overwriting anything. Only add CLAUDE.md if missing.
- **Already on a project with no CLAUDE.md**: Skip Steps 1–2, go straight to Step 4.
- **Monorepo / nested project**: Put CLAUDE.md at the subproject root, not the repo root (unless the user prefers otherwise).
- **Non-standard location** (not `~/projects/`): Follow the user's path, don't force the convention.
