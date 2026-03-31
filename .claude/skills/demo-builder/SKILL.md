---
name: demo-builder
description: 快速构建 web demo 页面。支持三种工作流：(1) Figma 设计稿 → 代码；(2) 从零描述快速出 demo；(3) 现有页面截图 → Figma。触发词：demo、figma 转代码、做个原型、网页 demo、出个页面。
---

# Demo Builder

## 工作流 A：Figma → Code

1. 在 Figma 右键 frame → "Copy link to selection"
2. 发送给 Claude Code：

```
用 demo-builder，把这个 Figma 设计转成 HTML+Tailwind demo:
[Figma 链接]
保存到: ~/Desktop/demos/[项目名]/index.html
```

Claude 通过 Figma MCP 读取设计数据（图层、颜色、字体、间距），生成匹配的代码。

**Figma MCP 状态**：已在 `.mcp.json` 配置（`https://api.figma.com/mcp`）。
首次使用需手动 OAuth：在 Claude Code 里输入 `/mcp` → 选择 Figma → 浏览器完成授权。
注意：Figma 免费计划每月 6 次 MCP tool call，Pro plan 无限制。

## 工作流 B：零起点快速 Demo（面试 / 展示用）

```
用 demo-builder，做一个 [功能描述] 的网页 demo：
- 技术栈: React + Tailwind（或 纯 HTML+CSS+JS）
- 风格: 现代简洁，Linear/Vercel 的设计语言
- 功能: [列出核心交互]
- 保存到: ~/Desktop/demos/[项目名]/index.html
```

## 工作流 C：Code → Figma（推回设计稿）

```
把 ~/Desktop/demos/[项目名]/index.html 的 UI 转成 Figma frame
```

## Token 节省提示

Demo 任务较重，建议在新 session 里做：
1. 先 /compact 或 /clear 当前 context
2. 新开 session 专门做 demo 任务
3. 复杂 demo 拆成多步：先出结构，再加样式，再加交互

## 输出规范

- 默认保存到 `~/Desktop/demos/[项目名]/`
- 单文件 demo 用 `index.html`（内联 CSS+JS）
- 多页 demo 用 `src/` 结构 + vite 启动

## 触发词

- "demo"
- "figma 转代码"
- "做个原型"
- "网页 demo"
- "出个页面"
- "/demo-builder <描述>"
