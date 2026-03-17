#!/usr/bin/env bash
# install.sh — bootstrap claude-os on a fresh machine
# Usage:
#   bash install.sh              — full install
#   bash install.sh --rotate-secrets  — re-prompt for all Keychain secrets

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()   { echo "[install] $*"; }
warn()  { echo "[install] WARN: $*" >&2; }
die()   { echo "[install] ERROR: $*" >&2; exit 1; }
step()  { echo ""; echo "[install] ── $* ──────────────────────────────────────"; }

ROTATE_SECRETS=false
for arg in "$@"; do
  [[ "$arg" == "--rotate-secrets" ]] && ROTATE_SECRETS=true
done

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
step "Checking prerequisites"

check_cmd() {
  if command -v "$1" &>/dev/null; then
    log "  ✓ $1"
  else
    warn "  ✗ $1 not found — $2"
  fi
}

check_cmd git      "install via Xcode CLT: xcode-select --install"
check_cmd node     "install via https://nodejs.org or: brew install node"
check_cmd npm      "comes with node"
check_cmd jq       "brew install jq"
check_cmd python3  "comes with macOS"

# ── 2. Claude Code CLI ────────────────────────────────────────────────────────
step "Claude Code CLI"
if command -v claude &>/dev/null; then
  log "  ✓ claude $(claude --version 2>/dev/null || echo '(version unknown)')"
else
  warn "  ✗ claude not found"
  log "  Install: npm install -g @anthropic-ai/claude-code"
  log "  Then re-run this script"
fi

# ── 3. Codex CLI ──────────────────────────────────────────────────────────────
step "OpenAI Codex CLI"
if command -v codex &>/dev/null; then
  log "  ✓ codex $(codex --version 2>/dev/null || echo '(version unknown)')"
else
  warn "  ✗ codex not found"
  log "  Install: sudo npm install -g @openai/codex"
fi

# ── 4. Sync config to ~/.claude ───────────────────────────────────────────────
step "Syncing config to ~/.claude"
bash "$REPO_DIR/sync.sh"

# ── 5. Secrets (Keychain) ─────────────────────────────────────────────────────
step "Secrets — macOS Keychain"

store_secret() {
  local service="$1"
  local account="$2"
  local label="$3"

  # Check if already exists
  if security find-generic-password -s "$service" -a "$account" &>/dev/null; then
    if [ "$ROTATE_SECRETS" = true ]; then
      security delete-generic-password -s "$service" -a "$account" 2>/dev/null || true
      log "  Rotating $label..."
    else
      log "  ✓ $label already in Keychain (use --rotate-secrets to update)"
      return
    fi
  else
    log "  Setting up $label..."
  fi

  echo -n "  Enter $label (input hidden): "
  read -rs secret
  echo ""

  if [ -z "$secret" ]; then
    warn "  Skipped $label (empty input)"
    return
  fi

  security add-generic-password -s "$service" -a "$account" -w "$secret" -U
  log "  ✓ $label saved to Keychain"
}

store_secret "claude-os.github"   "GITHUB_PERSONAL_ACCESS_TOKEN" "GitHub PAT"
store_secret "claude-os.mail163" "MAIL_163_ADDRESS"             "163 邮箱地址 (如 yourname@163.com)"
store_secret "claude-os.mail163" "MAIL_163_APP_PASSWORD"        "163 授权码 (非登录密码，在邮箱设置→IMAP→授权码生成)"

# ── 6. ~/.claude/settings.json ────────────────────────────────────────────────
step "Global settings"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"
if [ ! -f "$GLOBAL_SETTINGS" ]; then
  echo '{}' > "$GLOBAL_SETTINGS"
  log "  Created empty $GLOBAL_SETTINGS"
else
  log "  ✓ $GLOBAL_SETTINGS exists (not modified)"
fi

# ── 7. Raycast scripts ────────────────────────────────────────────────────────
step "Raycast integration"

if command -v raycast &>/dev/null || [ -d "/Applications/Raycast.app" ]; then
  log "  ✓ Raycast found"
  log "  Raycast scripts are at: $REPO_DIR/raycast/"
  log ""
  log "  To activate:"
  log "    1. Open Raycast → Settings → Extensions → Script Commands"
  log "    2. Click '+' → Add Script Directory"
  log "    3. Select: $REPO_DIR/raycast"
  log "    4. The following commands will appear:"
  log "         'Claude Brief'   — daily calendar + email summary"
  log "         'Claude Capture' — quick-capture a thought (with text input)"
  log "         'Claude Ask'     — open Claude session in Terminal"
  log ""
  log "  Recommended keyboard shortcuts (set in Raycast after adding scripts):"
  log "         Cmd+Shift+B   → Claude Brief"
  log "         Cmd+Shift+Space → Claude Capture"
  log "         Cmd+Shift+A   → Claude Ask"
else
  warn "  Raycast not found — skipping"
  log "  Install Raycast from https://www.raycast.com, then re-run this script"
  log "  Scripts are ready at: $REPO_DIR/raycast/"
fi

# ── 8. Summary ────────────────────────────────────────────────────────────────
step "Install complete"
echo ""
log "claude-os is ready at: $REPO_DIR"
log ""
log "Next steps:"
log "  1. cd ~/your-project && claude    — start a session with full config"
log "  2. Run ./sync.sh after any change to agents/skills/commands"
log "  3. Run ./install.sh --rotate-secrets to update Keychain tokens"
log "  4. Add $REPO_DIR/raycast to Raycast Script Commands (see above)"
log ""
log "Commands: /plan  /review  /remember  /brief  /draft-email  /capture  /task"
