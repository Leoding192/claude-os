Undo the most recent Reversible-class action from the current session.

## Usage
/undo-last

## Steps

1. Check the in-session undo stack (maintained in context, not on disk).
   - If empty: reply "Nothing to undo in this session." and stop.

2. Pop the most recent Reversible action. Display:
   ```
   Undoing: <action summary>
   Reversal: <reversal operation>
   Target: <file / record / resource>
   ```

3. Ask for explicit confirmation: "Proceed with undo? (yes/no)"
   - On "no": push the action back, stop.
   - On "yes": proceed.

4. Execute the reversal operation (see docs/recovery-model.md for the mapping).

5. Log to `~/claude-os/logs/audit.jsonl`:
   ```json
   {
     "timestamp": "<ISO8601Z>",
     "tool": "<tool used for reversal>",
     "capability_id": "<original capability_id>",
     "action": "undo",
     "target": "<target>",
     "result": "success | error",
     "confirmed_by_user": true,
     "undo_available": false
   }
   ```

6. Confirm completion: "Undone: <brief summary>"

## Limits
- Only Reversible-class actions can be undone. Compensatable and Irreversible actions are not on the undo stack.
- Max stack depth: 10 actions. Oldest entries are dropped when the stack is full.
- Stack is cleared at session end.
- The reversal action itself is NOT added back to the undo stack.
