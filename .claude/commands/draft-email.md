Draft an email using the mail-writer agent, with Leo's writing preferences applied.

## Usage
/draft-email [brief description]

Examples:
- `/draft-email reply to Alex about project timeline`
- `/draft-email cold outreach to potential collaborator`
- `/draft-email follow-up on yesterday's meeting`

## Steps

1. **Gather context** — if the description is ambiguous, ask for:
   - Recipient (name + email if not obvious)
   - Purpose / key points to cover
   - Tone (if not inferable from context)

2. **Check writing preferences** — read `memory/writing.md` if it exists, otherwise use defaults from `memory/session.md`

3. **Draft** — compose the email:
   - Subject: clear and direct, no filler words
   - Body: match the requested tone; concise; one clear ask or CTA if applicable
   - Signature: do not add unless Leo specifies

4. **Create draft via Gmail MCP**:
   ```
   gmail_create_draft(to=<recipient>, subject=<subject>, body=<body>)
   ```

5. **Show full preview**:
   ```
   To: <recipient>
   Subject: <subject>
   ---
   <body>
   ```

6. **Wait for feedback** — options:
   - `send` → Confirm tier: show action summary, require explicit "yes"
   - `edit <instruction>` → revise and show again
   - `discard` → delete the draft

## Rules

- Never auto-send. `send_email` always requires explicit "yes".
- If recipient email is unknown, ask — never guess.
- Keep drafts < 200 words unless the user requests otherwise.
- Apply tone calibration: match the formality level of any existing thread being replied to.
