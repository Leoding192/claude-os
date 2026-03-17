Quick-capture a thought, task, or note into the current session state.

## Usage
/capture "<text>"

Examples:
- `/capture "follow up with Alex on Monday about the auth PR"`
- `/capture "bug: login redirect broken on Safari"`
- `/capture "read the new RFC before Thursday's meeting"`

## Steps

1. Parse `$ARGUMENTS` as the capture text.
   - If empty, ask: "What do you want to capture?"

2. Classify the capture (infer from text):
   - **Task** — something to do
   - **Note** — reference info
   - **Bug** — a defect to track
   - **Idea** — exploratory, no commitment

3. Append to `memory/session.md` under the appropriate section:
   - Tasks → `## In Progress` or `## Next Up`
   - Notes/Ideas → add a `## Captures` section if it doesn't exist
   - Bugs → add a `## Bugs` section if it doesn't exist

4. Confirm: `Captured [<type>]: "<text>"`

5. If `memory/session.md` is approaching 50 lines, warn:
   "session.md is getting long (N lines). Consider running /consolidate or moving items to a project memory."

## Format in session.md

```markdown
## Captures
- [type] <text> — <YYYY-MM-DD>
```

## Rules

- Never modify any file other than `memory/session.md`
- Never classify a capture as a decision (that requires `/remember`)
- Keep captured text verbatim — do not paraphrase
