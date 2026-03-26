Writing pipeline: Claude drafts → (optional) Codex blind review → Claude revises → final output.

## Usage
/write <topic or brief description> [--no-review]

Examples:
- `/write essay on the ethics of AI autonomy, 800 words, academic tone`
- `/write weekly team update memo, key points: shipped auth feature, delayed API migration`
- `/write cover letter for product manager role at Anthropic`
- `/write short announcement --no-review`

## Steps

1. **Gather context** — if $ARGUMENTS is sparse, ask for:
   - Topic / title (required)
   - Format: essay / memo / report / letter / other
   - Target length: word count or page count
   - Tone: academic / professional / casual / technical
   - Key points to include or constraints (if any)

2. **Load writing preferences** — read `memory/writing.md` if it exists. Apply preferences silently.

3. **Draft** — Claude writes the full piece. Show the draft with a header:
   ```
   ── Draft ──────────────────────────────
   [full draft content]
   ── End Draft ──────────────────────────
   ```

4. **Codex blind review** — skip if `--no-review` flag is present OR the piece is < 200 words.
   Otherwise run:
   ```bash
   ~/claude-os/.agents/skills/codex/scripts/ask_codex.sh \
     "Review the following writing for: (1) clarity and flow, (2) argument strength and logical structure, (3) factual or logical errors, (4) tone consistency, (5) any awkward phrasing. Be specific. Quote the problematic text and suggest a concrete improvement for each issue." \
     --read-only \
     --reasoning high
   ```
   Show Codex feedback in full:
   ```
   ── Codex Review ───────────────────────
   [codex output]
   ── End Review ─────────────────────────
   ```

5. **Revise** — if Codex ran and found issues, produce a revised version. Show:
   ```
   ── Revised ────────────────────────────
   [revised content]
   ── End Revised ────────────────────────

   Changes made:
   • <what changed> — <why>
   • ...
   ```
   If Codex was skipped or found no issues, output the draft as final.

6. **Output options** — ask: "Save to file, copy to clipboard, or done?"
   - Save: write to `~/Desktop/<title>.<ext>` (Confirm tier — show path before writing)
   - Clipboard: `echo "<content>" | pbcopy` (Auto)
   - Done: stop

## Rules

- Codex review is **optional**: skip when `--no-review` is passed or piece < 200 words
- Show Codex feedback in full before producing the revised version
- If Codex finds no significant issues: note "Codex: no issues found" and output draft as final
- Always apply `memory/writing.md` preferences if the file exists
- If Codex is unavailable (ask_codex.sh missing): note the fallback and output draft directly
- File saves to Desktop require explicit "yes" (Confirm tier, `write_file` capability)
