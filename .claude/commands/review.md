Review code changes using a selected engine.

## Steps

1. Determine the review target:
   - If $ARGUMENTS is provided, use it as the target (file path, commit, or diff range)
   - Otherwise, run `git diff HEAD` to get uncommitted changes
   - If the diff is empty, respond: "没有未提交的变更，没有可以审查的内容。" and stop.

2. Ask the user: "用哪个引擎审查？\n- **Claude Code** — 用 code-reviewer agent 直接审查\n- **Codex** — 调用 Codex 独立审查（更客观，消耗 OpenAI token）"

3. Wait for the user's choice, then execute:

   **If Claude Code:**
   Use the code-reviewer agent. Review the target thoroughly and produce the output format below.

   **If Codex:**
   Run the following command and read the output file:
   ```bash
   ~/claude-os/.agents/skills/codex/scripts/ask_codex.sh \
     "Review the following code changes for correctness, security, edge cases, and maintainability. Be critical and specific. Cite file and line for every issue. Suggest a fix for each one." \
     --read-only \
     --reasoning high \
     --file <target file if applicable>
   ```
   Then present Codex's findings using the output format below.

## Output Format

### Verdict
`APPROVE` / `APPROVE WITH NOTES` / `REQUEST CHANGES`

### Critical (must fix before merge)
- issue — file:line — explanation — suggested fix

### Major (should fix)
- issue — file:line — explanation — suggested fix

### Minor (consider fixing)
- issue — file:line — explanation

### Nits (optional)
- style / preference items

### Strengths
(skip if nothing notable)

### Open Questions
(anything needing author context before a final call)

## Rules
- Do not soften real problems
- Every Critical and Major issue must include a suggested fix
- If using Codex, present its findings as-is — do not filter or reinterpret
