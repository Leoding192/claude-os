---
name: brief
description: Generate Leo's daily brief: calendar events + email summary + optional priorities. Triggered by "brief", "daily brief", "今日简报".
---

Generate Leo's daily brief: calendar events + email summary + optional priorities.

## Usage
/brief [date]

- No argument → today
- `tomorrow` or a date like `2026-03-17` → that day's calendar

## Steps

1. **Calendar** — invoke scheduler agent:
   - Read all events for the target date
   - Flag conflicts (overlapping times)
   - Highlight events starting within the next 2 hours (if today)

2. **Email** — invoke mailer agent:
   - `gmail_search_messages` query: `is:unread newer_than:1d`
   - Group: Action Required / FYI / Newsletters
   - Cap at 10 items; show count for the rest

3. **Compose output** — combine both into the format below

4. **Notify** (optional):
   ```bash
   osascript -e 'display notification "Brief ready" with title "Claude OS" subtitle "Check your terminal"'
   ```

## Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Daily Brief — <Weekday>, <Date>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 CALENDAR  (<N> events)

  <HH:MM> – <HH:MM>  <Title>
                     <Location if set>
  <HH:MM> – <HH:MM>  <Title>
  ⚠️  CONFLICT: <title A> overlaps <title B>

📧 EMAIL  (<N> unread)

  Action Required
    • <Sender> — <Subject>
      <1-line summary>

  FYI
    • <Sender> — <Subject>

  Newsletters / Automated: <N> skipped

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If calendar is empty: "📅 No events scheduled."
If inbox is clean: "📧 Inbox clear."

## Latency Target
End-to-end < 15 seconds. If either source is slow, output available data and note what's pending.

## Error Handling
- Calendar unavailable → skip section, note "Calendar unavailable — is Calendar.app running?"
- Gmail MCP unavailable → skip section, note "Gmail unavailable — check MCP connection"
- Never fail silently; always report what was skipped and why
