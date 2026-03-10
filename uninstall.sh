#!/usr/bin/env bash
set -euo pipefail

# --- Platform detection ---

PLATFORM="${1:-}"
UNINSTALL_CLAUDE=false
UNINSTALL_OPENCLAW=false

detect_platforms() {
  if [ -L "$HOME/.claude/skills/codex-handoff" ] || [ -L "$HOME/.claude/commands/codex-handoff.md" ]; then
    UNINSTALL_CLAUDE=true
  fi
  if [ -L "$HOME/.openclaw/skills/codex-handoff" ]; then
    UNINSTALL_OPENCLAW=true
  fi
  if [ -L "$HOME/.clawdbot/skills/codex-handoff" ]; then
    UNINSTALL_OPENCLAW=true
  fi
}

case "$PLATFORM" in
  --platform=claude-code|--claude-code)
    UNINSTALL_CLAUDE=true
    ;;
  --platform=openclaw|--openclaw)
    UNINSTALL_OPENCLAW=true
    ;;
  --platform=all|--all)
    UNINSTALL_CLAUDE=true
    UNINSTALL_OPENCLAW=true
    ;;
  "")
    detect_platforms
    ;;
  *)
    echo "Usage: bash uninstall.sh [--platform=claude-code|openclaw|all]"
    exit 1
    ;;
esac

# --- Helper ---

remove_symlink() {
  local path="$1"
  if [ -L "$path" ]; then
    rm "$path"
    echo "  Removed: $path"
  fi
}

# --- Uninstall ---

if [ "$UNINSTALL_CLAUDE" = true ]; then
  echo "Uninstalling codex-handoff from Claude Code..."
  remove_symlink "$HOME/.claude/commands/codex-handoff.md"
  remove_symlink "$HOME/.claude/skills/codex-handoff"
  echo ""
fi

if [ "$UNINSTALL_OPENCLAW" = true ]; then
  echo "Uninstalling codex-handoff from OpenClaw..."
  remove_symlink "$HOME/.openclaw/skills/codex-handoff"
  remove_symlink "$HOME/.clawdbot/skills/codex-handoff"
  echo ""
fi

if [ "$UNINSTALL_CLAUDE" = false ] && [ "$UNINSTALL_OPENCLAW" = false ]; then
  echo "No codex-handoff installation found."
  exit 0
fi

echo "Done! codex-handoff has been removed."
