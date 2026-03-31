Dual-engine code review: Claude code-reviewer agent + Codex, side-by-side with agreement/disagreement analysis.

## Usage
/adversarial-review [target]

- No argument → `git diff HEAD` (uncommitted changes)
- File path → review that file's current diff
- Commit hash or range → review that commit

## Steps

1. **Determine target** (same logic as /review):
   - Use `$ARGUMENTS` if provided
   - Otherwise `git diff HEAD`
   - If diff is empty: "No changes to review." and stop

2. **Diff pre-check** — count diff lines:
   ```bash
   git diff HEAD | wc -l
   ```
   - If < 20 lines → run Claude code-reviewer only, append note: "Diff too small for dual-engine (<20 lines). Running Claude only."
   - If ≥ 20 lines → proceed with dual-engine

3. **Claude review** — invoke the code-reviewer agent on the diff. Capture full output as CLAUDE_REVIEW.

4. **Codex review** — run Codex independently (blind — do not show CLAUDE_REVIEW to Codex):
   ```bash
   # 使用 codex-bridge 确定性调用（比 ask_codex.sh 更可靠：直接 codex exec，无 agent loop，无 LLM 触发不稳定问题）
   RESULT_FILE="/tmp/codex_adversarial_$(date +%s).txt"
   git diff HEAD | codex exec \
     "You are doing a blind code review. Review the following diff for correctness, security vulnerabilities, edge cases, performance issues, and maintainability problems. Be specific and critical. Cite file:line for every issue. Suggest a concrete fix for each issue found." \
     --read-only > "$RESULT_FILE" 2>&1
   cat "$RESULT_FILE"
   ```
   Capture output as CODEX_REVIEW.
   Fallback (if codex exec fails): use `~/.claude/skills/codex/scripts/ask_codex.sh` with `--read-only --reasoning high`.

5. **Compare** — identify overlapping issues:
   - **AGREED**: issues where both engines flag the same file:line or same logical problem
   - **CLAUDE_ONLY**: issues flagged only by Claude
   - **CODEX_ONLY**: issues flagged only by Codex

6. **Output unified report** (format below)

## Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Adversarial Review
 Target: <target>  |  Diff: <N> lines
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Verdict: APPROVE / APPROVE WITH NOTES / REQUEST CHANGES
(use the stricter of the two verdicts)

---

### ✅ Both engines agree — high confidence
- <issue description> — <file:line>
  Fix: <suggested fix>

### 🔵 Claude only
- <issue> — <file:line>

### 🟠 Codex only
- <issue> — <file:line>

---

### Summary
| Engine | Issues | Critical | Overlap |
|---|---|---|---|
| Claude | N | N | N% |
| Codex  | N | N | — |
```

## Rules

- Never show Claude's review output to Codex before Codex runs (blind review is the point)
- The final verdict is the stricter of the two: if either engine says REQUEST CHANGES, the verdict is REQUEST CHANGES
- Do not filter or reinterpret Codex output — present it as-is
- Overlap % = (agreed issues) / (total unique issues) × 100
- If Codex is unavailable (ask_codex.sh not found): fall back to Claude-only review and note the fallback
