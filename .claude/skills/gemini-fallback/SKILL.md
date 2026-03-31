---
name: gemini-fallback
description: 当 Claude Pro quota 不足、或需要 web search、或需要访问 Reddit 等 Claude 无法抓取的网站时，使用 Gemini CLI。触发词："用 gemini"、"gemini 帮我"、"quota 快用完了"、"免费搜一下"。
---

# Gemini Fallback

## 使用场景

1. Claude Pro 5小时窗口 quota 接近耗尽（< 20%）— 用 `ccusage blocks --live --plan pro` 监控
2. 需要访问 Reddit、部分无法 WebFetch 的站点
3. 需要免费 web search（Gemini 内置 Google Search）
4. Deep research 任务（Gemini 支持 deep research 模式）

## 安装（首次使用）

```bash
# 安装 Gemini CLI
npm install -g @google/gemini-cli

# 登录（需要浏览器 OAuth）
gemini auth login

# 安装 quota 监控工具
sudo npm install -g ccusage
```

验证：
```bash
gemini --version
ccusage --version
```

## 调用方式

### 简单问答

```bash
gemini -p "你的问题"
```

### 带 web search（Reddit / 实时信息）

```bash
gemini -p "搜索最新信息: 你的问题"
```

### 文件分析

```bash
gemini -p "分析以下代码:" < /path/to/file.py
```

### 异步长任务（不占用当前 session）

```bash
tmux new-window -n gemini-task
tmux send-keys -t gemini-task "gemini -p '$TASK' > ~/gemini_result.txt && echo '=== DONE ===' >> ~/gemini_result.txt" Enter
echo "任务已异步提交，完成后查看 ~/gemini_result.txt"
```

## Quota 监控

```bash
# 实时查看 Claude Pro 用量（另开一个终端窗口常驻）
ccusage blocks --live --plan pro
```

切换阈值建议：
- quota < 20% → 切换到此 skill
- quota 耗尽 → 直接用 `gemini -p "问题"` 处理非关键任务

## 触发词

- "用 gemini"
- "gemini 帮我"
- "quota 快用完了"
- "免费搜一下"
- "/gemini-fallback <任务>"

## 注意

- Gemini CLI 使用 Google OAuth，包含在 Google 账号免费额度
- 代码质量低于 Claude Sonnet，重要任务仍用 Claude
- 不支持直接操作本地文件系统（需要手动传内容）
- Gemini 当前未安装：`npm install -g @google/gemini-cli && gemini auth login`
