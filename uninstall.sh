#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"

echo "Uninstalling codex-handoff..."

# Remove command symlink
if [ -L "$CLAUDE_DIR/commands/codex-handoff.md" ]; then
  rm "$CLAUDE_DIR/commands/codex-handoff.md"
  echo "  Removed command symlink"
else
  echo "  Command symlink not found (skipping)"
fi

# Remove skill symlink
if [ -L "$CLAUDE_DIR/skills/codex-handoff" ]; then
  rm "$CLAUDE_DIR/skills/codex-handoff"
  echo "  Removed skill symlink"
else
  echo "  Skill symlink not found (skipping)"
fi

echo ""
echo "Done! codex-handoff has been removed from Claude Code."
