---
name: debug
description: Reusable debugging workflow. Given a bug report, error, or unexpected behavior, systematically find and fix the root cause.
---

# Debug Workflow

## Steps

1. **Reproduce** — confirm you understand the failure condition: what input, what output, what was expected
2. **Collect evidence** — gather all available signal before forming hypotheses:
   - error message and full stack trace
   - relevant logs
   - recent changes (`git log`, `git diff`)
   - related test failures
3. **Narrow the blast radius** — identify which module, function, or layer owns the failure
4. **Form hypotheses** — list 2–3 plausible root causes, ranked by likelihood
5. **Test hypotheses** — eliminate candidates using the fastest available check (read code, run test, add log)
6. **Identify root cause** — confirm the actual cause, not just a symptom
7. **Fix** — make the smallest change that addresses the root cause
8. **Verify** — confirm the fix resolves the failure and does not introduce regression
9. **Produce output** — structured report below

## Output Format

### Failure Summary
One sentence: what failed, under what condition.

### Root Cause
Exact location (file:line) and explanation of why it fails.

### Evidence
- what you checked and what it told you
- what you ruled out and why

### Fix Applied
- what changed and why this resolves the root cause (not just the symptom)

### Verification
- how you confirmed the fix works
- any regression risk remaining

### Follow-ups
- anything worth addressing later (related fragility, missing test coverage, etc.)

## Rules
- Never patch a symptom if the root cause is findable
- Do not stop at the first plausible cause — confirm it
- If you cannot reproduce the failure, say so before guessing
- If the fix feels hacky, note it and explain why a cleaner fix wasn't taken
