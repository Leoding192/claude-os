#!/usr/bin/env bash
# gemini-ask.sh — non-interactive web search via Gemini CLI
# Usage: bash ~/claude-os/bin/gemini-ask.sh "<query>"

set -euo pipefail

QUERY="${1:-}"

if [[ -z "$QUERY" ]]; then
  echo "[gemini-ask] ERROR: no query provided" >&2
  exit 1
fi

gemini --yolo -p "Search the web and summarize the latest news about: ${QUERY}. Return 3-5 key findings, each in 1-2 sentences with source names." \
  2>/dev/null || true
