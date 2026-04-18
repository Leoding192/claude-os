#!/usr/bin/env python3
# session-finalize.py — Stop hook: carry forward unchecked tasks

import os
import re
import datetime


def main():
    root = os.popen(
        f'git -C "{os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())}" rev-parse --show-toplevel 2>/dev/null'
    ).read().strip() or os.path.expanduser("~/claude-os")
    session_file = os.path.join(root, "memory", "session.md")

    if not os.path.exists(session_file):
        exit(0)

    try:
        with open(session_file) as f:
            content = f.read()

        # Extract incomplete tasks (- [ ] lines) — FIXED: single backslashes for regex
        incomplete = [
            line.strip()
            for line in content.splitlines()
            if re.match(r"- \[ \] .+", line.strip())
        ]

        # Extract first non-empty In Progress item as summary
        summary = ""
        in_progress = re.search(r"## In Progress\n(.*?)(?=##|\Z)", content, re.DOTALL)
        if in_progress:
            for line in in_progress.group(1).splitlines():
                line = line.strip()
                if line and line not in ("-", "- [ ]"):
                    summary = re.sub(r"^- \[.\] ", "", line)[:80]
                    break

        today = datetime.date.today().isoformat()
        last_session_line = f"> Last session: {today}" + (
            f" — {summary}" if summary else ""
        )

        carried = "\n".join(incomplete) if incomplete else "-"

        new_content = f"""# Session State

> Injected at every session start. Keep this short — current work only.
> For durable decisions and lessons, write to memory/decisions.md instead.

{last_session_line}

---

## In Progress

- [ ]

## Blocked / Waiting On

-

## Next Up

{carried}

## Captures

-
"""

        with open(session_file, "w") as f:
            f.write(new_content)

        n = len(incomplete)
        print(f"[claude-os] session.md auto-cleared. {n} task(s) carried forward.")
    except Exception as e:
        print(
            f"[claude-os] warn: could not auto-clear session.md: {e}",
            file=__import__("sys").stderr,
        )


def test():
    """Test regex fix"""
    test_content = "- [ ] write tests\n- [x] done task\n- [ ] fix bug\nsome other line"
    matches = [
        line.strip()
        for line in test_content.splitlines()
        if re.match(r"- \[ \] .+", line.strip())
    ]
    assert len(matches) == 2, f"Expected 2 matches, got {len(matches)}: {matches}"
    print("✓ Regex test passed")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        test()
    else:
        main()
