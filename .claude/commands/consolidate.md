Consolidate stale L3 memory entries into the archive layer.

## Usage
/consolidate

## When to Run
- L3 total entries exceed 200
- Quarterly memory review
- When `memory/decisions.md` feels bloated or outdated

## Steps

1. Read all L3 files:
   - `memory/decisions.md`
   - `memory/people/*.md` (if exists)
   - `memory/writing.md` (if exists)

2. Identify stale entries. An entry is stale if:
   - It has been superseded by a newer decision
   - It references a project that is no longer active
   - It has not been referenced or updated in 90+ days (use entry date to judge)
   - User explicitly flags it as outdated

3. For each stale entry:
   - Determine archive month: `YYYY-MM` of today
   - Append it to `memory/archive/YYYY-MM/<source-filename>` (create if needed)
   - Remove it from the source L3 file

4. Add a consolidation note at the top of `memory/decisions.md`:
   ```markdown
   ## Consolidated <YYYY-MM-DD>
   Archived N entries to memory/archive/<YYYY-MM>/. Active entries: M.
   ```

5. Report to user:
   - N entries archived
   - M entries retained
   - Files affected
   - No entries were deleted — all archived entries remain readable at `memory/archive/`

## Safety Rules
- Never delete entries during consolidation — only move to archive
- Never archive entries from the current month
- Never auto-run without explicit `/consolidate` invocation
- After archiving, run a quick sanity check: are any active decisions referencing the archived content?
