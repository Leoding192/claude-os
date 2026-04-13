---
name: install-skill
description: Install a new skill or agent into claude-os and sync it globally to Claude Code. Use this whenever Leo says "安装 skill"、"下载 skill"、"add a skill"、"install agent"、"把 X 同步到全局"、or "install X skill from GitHub". Handles GitHub download, correct symlink creation (avoiding the relative-path trap), and lock file update.
---

# Install Skill — claude-os 安装 & 全局同步

## 背景知识（必读）

**目录结构：**
```
~/claude-os/
  .agents/skills/<name>/     ← 真实文件存放处
  .claude/skills/<name>      ← symlink（相对路径），claude-os context 发现用
~/.claude/skills/<name>      ← symlink（绝对路径），Claude Code 全局发现用
```

**关键陷阱：**
- `~/.claude/skills/` 里的 symlink **必须用绝对路径**
- 相对路径 `../../.agents/skills/<name>` 从 `~/.claude/skills/` 往上两级是 `~/`，那里没有 `.agents/` → 死链
- `~/claude-os/.claude/skills/` 里可以用相对路径（`../../.agents/skills/<name>` → 解析到 `~/claude-os/.agents/skills/<name>` ✓）

---

## Step 1：确认来源

询问或从用户输入提取：
- **GitHub 路径**：`owner/repo` 或 `owner/repo/subdir`（如 `anthropics/skills/skill-creator`）
- **Skill 名称**：通常是最后一段路径，或 SKILL.md 里的 `name` 字段

如果是 Agent（而非 Skill），安装路径不同——见文末。

---

## Step 2：下载文件

```python
import urllib.request, json, os

def download_dir(api_url, local_path):
    os.makedirs(local_path, exist_ok=True)
    with urllib.request.urlopen(api_url) as r:
        items = json.load(r)
    for item in items:
        if item['type'] == 'file':
            dest = os.path.join(local_path, item['name'])
            urllib.request.urlretrieve(item['download_url'], dest)
            print(f"  {item['name']}")
        elif item['type'] == 'dir':
            download_dir(item['url'], os.path.join(local_path, item['name']))

# 示例：anthropics/skills/skill-creator
# owner = "anthropics", repo = "skills", subdir = "skills/skill-creator"
api_url = "https://api.github.com/repos/{owner}/{repo}/contents/{subdir}"
local_path = f"/Users/dingfuying/claude-os/.agents/skills/{skill_name}"
download_dir(api_url, local_path)
```

验证 SKILL.md 存在：
```bash
ls /Users/dingfuying/claude-os/.agents/skills/<name>/SKILL.md
```

---

## Step 3：创建 Symlinks

### claude-os 内部（相对路径）
```bash
ln -s ../../.agents/skills/<name> /Users/dingfuying/claude-os/.claude/skills/<name>
```

### 全局（绝对路径，关键！）
```bash
ln -s /Users/dingfuying/claude-os/.agents/skills/<name> /Users/dingfuying/.claude/skills/<name>
```

**不要用相对路径 `../../.agents/skills/<name>` 给 `~/.claude/skills/`**，这是今天踩过的坑。

---

## Step 4：验证

```bash
# 两个链接都要验证
python3 -c "
import os
for p in [
    '/Users/dingfuying/claude-os/.claude/skills/<name>',
    '/Users/dingfuying/.claude/skills/<name>',
]:
    exists = os.path.exists(p)
    real = os.path.realpath(p)
    print(f'{\"OK\" if exists else \"DEAD\"} {p} -> {real}')
"
```

期望结果：两个都显示 `OK`，`realpath` 都指向 `~/claude-os/.agents/skills/<name>`。

---

## Step 5：更新 skills-lock.json（如果在 feature branch）

`~/claude-os/skills-lock.json` 记录安装来源。由于 claude-os 通常在 `main` 分支而 hook 会阻止直接编辑，**只在 feature branch 时更新**：

```bash
git -C ~/claude-os branch --show-current
# 如果不是 main/master，才编辑 skills-lock.json
```

要添加的条目：
```json
"<name>": {
  "source": "<owner>/<repo>",
  "sourceType": "github",
  "computedHash": ""
}
```

如果在 main 分支，跳过此步，告知用户 skills-lock.json 未更新（不影响功能）。

---

## Step 6：告知用户

安装完成后输出：
```
✓ 文件位置：~/claude-os/.agents/skills/<name>/
✓ claude-os symlink：~/claude-os/.claude/skills/<name>  (相对路径)
✓ 全局 symlink：~/.claude/skills/<name>  (绝对路径)
⚠ 需要重启 Claude Code session 后 /<name> 才生效
```

---

## 本地 Skill（无 GitHub 来源）

如果 skill 文件直接写在 `~/claude-os/.claude/skills/<name>/`（没有放到 `.agents/skills/`），全局 symlink 指向这里：

```bash
ln -s /Users/dingfuying/claude-os/.claude/skills/<name> /Users/dingfuying/.claude/skills/<name>
```

验证：
```bash
python3 -c "import os; p='/Users/dingfuying/.claude/skills/<name>'; print('OK' if os.path.exists(p) else 'DEAD', '->', os.path.realpath(p))"
```

---

## 安装 Agent（而非 Skill）

Agent 不用 `.agents/skills/`，直接放到：
```bash
# 文件复制/下载到
/Users/dingfuying/.claude/agents/<agent-name>.md

# 同时在 claude-os 保留一份
/Users/dingfuying/claude-os/.claude/agents/<agent-name>.md
```

Agent 无需 symlink，Claude Code 直接从 `~/.claude/agents/` 加载。

---

## 常见来源

| 来源 | GitHub 路径 |
|---|---|
| anthropics 官方 skills | `anthropics/skills/<name>` |
| codex skill | `oil-oil/codex` |
| 自定义 skill | 本地目录，手动 cp 到 `.agents/skills/` |
