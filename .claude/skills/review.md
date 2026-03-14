---
name: review
description: Reusable code review workflow. Run against a file, diff, or PR to get structured feedback organized by severity.
---

# Review Workflow

## Steps

1. **Understand scope** — identify what changed and what it is supposed to do
2. **Read the code** — read every changed file in full, not just the diff
3. **Check correctness** — does it do what it claims? trace the logic
4. **Check safety** — auth, input validation, secrets, SQL injection, XSS, OWASP top 10
5. **Check edge cases** — null, empty, large input, concurrency, error paths
6. **Check consistency** — does it match the surrounding codebase patterns?
7. **Check tests** — are there tests? do they cover the real risk?
8. **Produce output** — structured report below

## Output Format

### Verdict
`APPROVE` / `APPROVE WITH NOTES` / `REQUEST CHANGES`

### Critical (must fix before merge)
- issue — file:line — explanation — suggested fix

### Major (should fix soon)
- issue — file:line — explanation — suggested fix

### Minor (consider fixing)
- issue — file:line — explanation

### Strengths
- what was done well (skip if nothing notable)

### Open Questions
- anything needing author context before a final call

## Rules
- Cite file and line for every issue
- Suggest a fix, don't just flag
- Do not invent problems — only flag real ones
- Security issues are always Critical regardless of likelihood
