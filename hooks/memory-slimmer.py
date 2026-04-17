#!/usr/bin/env python3
"""
Memory Slimmer — Deterministic file size management for Claude-OS memory files.
No LLM calls. Rules-based archiving and pruning.
"""

import os
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Tuple, List, Optional

# Configuration
CLAUDE_OS = Path.home() / "claude-os"
LOGS_DIR = CLAUDE_OS / "logs"
BACKUPS_DIR = CLAUDE_OS / "backups"
ARCHIVES_DIR = Path.home() / ".claude" / "archive"

LOGS_DIR.mkdir(parents=True, exist_ok=True)
BACKUPS_DIR.mkdir(parents=True, exist_ok=True)
ARCHIVES_DIR.mkdir(parents=True, exist_ok=True)

LOG_FILE = LOGS_DIR / "memory-slim.log"


class FileSlimmer:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.project_name = project_root.name
        self.actions = []

    def log_action(self, filename: str, action: str, before_lines: int, after_lines: int, archive_path: Optional[str] = None):
        """Log a slimming action."""
        timestamp = datetime.now().isoformat()
        entry = f"[{timestamp}] {self.project_name} | {filename} | {action} | {before_lines}→{after_lines}"
        if archive_path:
            entry += f" | archived to {archive_path}"
        self.actions.append(entry)

    def save_log(self):
        """Persist all actions to log file."""
        if self.actions:
            with open(LOG_FILE, "a") as f:
                for action in self.actions:
                    f.write(action + "\n")

    def backup_file(self, filepath: Path) -> Path:
        """Create timestamped backup of a file."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{filepath.name}.{timestamp}.bak"
        backup_path = BACKUPS_DIR / self.project_name / backup_name
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(filepath, backup_path)
        return backup_path

    def read_file(self, filepath: Path) -> List[str]:
        """Read file as lines."""
        if not filepath.exists():
            return []
        with open(filepath, "r") as f:
            return f.readlines()

    def write_file(self, filepath: Path, lines: List[str]):
        """Write lines to file."""
        filepath.parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, "w") as f:
            f.writelines(lines)

    def slim_claude_md(self, filepath: Path) -> bool:
        """Slim CLAUDE.md: only manage injected marker content."""
        lines = self.read_file(filepath)
        if not lines:
            return False

        # Find injection markers
        start_idx = None
        end_idx = None
        for i, line in enumerate(lines):
            if "INJECT_START" in line:
                start_idx = i
            if "INJECT_END" in line:
                end_idx = i

        if start_idx is None or end_idx is None:
            return False  # No markers, skip

        inject_lines = lines[start_idx + 1 : end_idx]
        inject_count = len(inject_lines)

        if inject_count <= 30:
            return False  # Within target, no action

        # Backup and archive
        self.backup_file(filepath)
        archive_path = ARCHIVES_DIR / f"{self.project_name}.CLAUDE.inject.archive.md"
        self.write_file(archive_path, inject_lines)

        # Slim: keep first 15-20 lines of injected content
        slim_target = 18
        slim_lines = inject_lines[:slim_target]

        # Reconstruct full file
        new_lines = lines[: start_idx + 1] + slim_lines + lines[end_idx:]
        self.write_file(filepath, new_lines)

        self.log_action(
            "CLAUDE.md",
            "slim_inject_markers",
            len(lines),
            len(new_lines),
            str(archive_path)
        )
        return True

    def slim_project_context_md(self, filepath: Path) -> bool:
        """Slim project.context.md: target ≤80 lines."""
        lines = self.read_file(filepath)
        original_count = len(lines)

        if original_count <= 80:
            return False  # Within soft target

        if original_count <= 120:
            return False  # Within hard limit, no action yet

        # Over hard limit: aggressive slim
        # Keep first ~80 lines (core context), archive the rest
        self.backup_file(filepath)

        keep_idx = 80
        archive_content = lines[keep_idx:]
        slim_lines = lines[:keep_idx]

        archive_path = ARCHIVES_DIR / f"{self.project_name}.project.context.archive.md"
        self.write_file(archive_path, archive_content)
        self.write_file(filepath, slim_lines)

        self.log_action(
            ".claude/project.context.md",
            "trim_to_core_context",
            original_count,
            len(slim_lines),
            str(archive_path)
        )
        return True

    def slim_project_state_md(self, filepath: Path) -> bool:
        """Slim project.state.md: target ≤35 lines."""
        lines = self.read_file(filepath)
        original_count = len(lines)

        if original_count <= 35:
            return False  # Within soft target

        if original_count <= 60:
            return False  # Within hard limit, no action yet

        # Over hard limit: aggressive slim
        # Keep first ~35 lines (status summary), archive the rest
        self.backup_file(filepath)

        keep_idx = 35
        archive_content = lines[keep_idx:]
        slim_lines = lines[:keep_idx]

        archive_path = ARCHIVES_DIR / f"{self.project_name}.project.state.archive.md"
        self.write_file(archive_path, archive_content)
        self.write_file(filepath, slim_lines)

        self.log_action(
            ".claude/project.state.md",
            "trim_to_status_only",
            original_count,
            len(slim_lines),
            str(archive_path)
        )
        return True

    def slim_activity_log_md(self, filepath: Path) -> bool:
        """Slim activity.log.md: keep latest 30 entries max."""
        lines = self.read_file(filepath)
        if not lines:
            return False

        # Count entries (lines starting with "## ")
        entries = []
        entry_start = 0
        for i, line in enumerate(lines):
            if line.startswith("## ") and i > 0:  # Skip initial header
                entries.append((entry_start, i))
                entry_start = i
        # Add final entry
        if entry_start < len(lines):
            entries.append((entry_start, len(lines)))

        # Content entries (skip header/template sections)
        content_entries = [e for e in entries if "Session Template" not in lines[e[0]]]

        if len(content_entries) <= 30:
            return False  # Within target

        # Keep latest 25 entries, archive oldest
        keep_count = 25
        archive_start_idx = content_entries[-keep_count][0]

        self.backup_file(filepath)
        archive_content = lines[:archive_start_idx]
        archive_path = ARCHIVES_DIR / f"{self.project_name}.activity.archive.md"
        self.write_file(archive_path, archive_content)

        # Write back: keep header + template + latest entries
        new_lines = lines[archive_start_idx:]
        self.write_file(filepath, new_lines)

        self.log_action(
            ".claude/activity.log.md",
            "archive_old_entries",
            len(lines),
            len(new_lines),
            str(archive_path)
        )
        return True

    def run(self):
        """Execute slimming for all project memory files."""
        # Find memory files
        claude_md = self.project_root / "CLAUDE.md"
        project_context = self.project_root / ".claude" / "project.context.md"
        project_state = self.project_root / ".claude" / "project.state.md"
        activity_log = self.project_root / ".claude" / "activity.log.md"

        changed = False
        changed |= self.slim_claude_md(claude_md)
        changed |= self.slim_project_context_md(project_context)
        changed |= self.slim_project_state_md(project_state)
        changed |= self.slim_activity_log_md(activity_log)

        self.save_log()
        return changed


def main():
    """Run memory slimming for current project or specified project."""
    import sys

    if len(sys.argv) > 1:
        project_root = Path(sys.argv[1]).resolve()
    else:
        # Detect current project from environment or CWD
        project_root = Path.cwd().resolve()

    if not project_root.exists():
        print(f"Error: Project root {project_root} does not exist", file=sys.stderr)
        return 1

    slimmer = FileSlimmer(project_root)
    changed = slimmer.run()

    if changed:
        print(f"✓ Memory slimmed for {slimmer.project_name}")
        for action in slimmer.actions:
            print(f"  {action}")
    else:
        print(f"• No slimming needed for {slimmer.project_name}")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
