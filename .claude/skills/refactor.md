---
name: refactor
description: Reusable refactor workflow. Restructure existing code for clarity, maintainability, or performance without changing observable behavior.
---

# Refactor Workflow

## Steps

1. **Define the goal** — what specific problem does this refactor solve? (readability, duplication, coupling, performance, testability)
2. **Establish a safety net** — confirm existing tests cover the code being changed; if not, write characterization tests first
3. **Read the code in full** — understand what it does before touching anything
4. **Identify the scope** — list every file that will change; flag anything that feels out of scope
5. **Show the plan** — describe the structural change before implementing; wait for go-ahead
6. **Refactor in small steps** — one logical change at a time, not everything at once
7. **Verify at each step** — run tests after each meaningful change, not just at the end
8. **Final check** — confirm behavior is identical, tests pass, and the code is cleaner than before
9. **Produce output** — structured report below

## Output Format

### Goal
What problem this refactor solves and why it matters now.

### Scope
- Files changed
- Files explicitly not touched
- Behavior preserved (what stayed the same)

### What Changed
For each meaningful structural change:
- **Before** — describe or quote the old shape
- **After** — describe or quote the new shape
- **Why** — what problem this addresses

### Verification
- test results before and after
- linter / type-checker output
- any manual checks performed

### Remaining Risks
- anything fragile, untested, or worth a follow-up review

## Rules
- Never change behavior under the guise of refactoring
- If there are no tests, write them before you start
- Stop and re-plan if scope grows unexpectedly — do not absorb extra changes silently
- Prefer many small commits over one large refactor commit
- If the refactor reveals a bug, fix it in a separate commit with a clear note
