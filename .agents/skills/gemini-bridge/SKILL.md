---
name: gemini-bridge
version: "1.0.0"
description: >
  Call Google Gemini CLI for one-shot, non-interactive queries.
  Use when: cross-model validation, large-context tasks (>100K tokens),
  comparing Claude output against Gemini, or as quota fallback.
  Trigger phrases: "ask gemini", "gemini opinion", "cross-check with gemini",
  "gemini-bridge", "second opinion from gemini".
  Do NOT use for: multi-turn conversation, tasks needing tool calls.
requires:
  - gemini CLI installed (verify: which gemini && gemini --version)
---

# Gemini Bridge Skill

## Usage
Ask Gemini a one-shot question and return its response directly.

## Workflow

### Step 1 – Verify gemini is available
```bash
which gemini || { echo "ERROR: gemini CLI not installed"; exit 1; }
gemini --version
```

### Step 2 – Call gemini non-interactively
```bash
# One-shot query (mirror of codex-bridge pattern)
echo "<YOUR_PROMPT>" | gemini --model gemini-2.0-flash --no-interactive
```

For file context:
```bash
gemini --model gemini-2.0-flash --no-interactive \
  --file <path> \
  --prompt "<YOUR_PROMPT>"
```

### Step 3 – Large context (Gemini's strength)
```bash
# Pass large file/context that exceeds Claude's practical window
cat <large_file> | gemini --model gemini-2.5-pro --no-interactive \
  --prompt "Summarize the key decisions in this codebase"
```

## Model selection
| Task | Model flag |
|------|-----------|
| Fast / cheap | `--model gemini-2.0-flash` |
| Large context / deep analysis | `--model gemini-2.5-pro` |
| Code review | `--model gemini-2.5-pro` |

## Error handling
- If gemini returns non-zero exit: print stderr and abort, do not retry silently
- If quota exceeded: report "Gemini quota exceeded" and stop
- Never pipe gemini output back into itself
