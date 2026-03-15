Invoke the reviewer agent to review the specified file, diff, or recent changes.

Use the reviewer agent. Review target: $ARGUMENTS

If no target is specified, review the most recent uncommitted changes (`git diff HEAD`).

Follow the reviewer output format exactly:
- Verdict: APPROVE / APPROVE WITH NOTES / REQUEST CHANGES
- Issues grouped by: Critical → Major → Minor → Nits
- Each issue must cite file:line and include a suggested fix
- Strengths (if any)
- Open questions

Be direct. Do not soften real problems.
