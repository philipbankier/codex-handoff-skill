#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing codex-handoff..."

# Create target directories if they don't exist
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

# Symlink the command
if [ -L "$CLAUDE_DIR/commands/codex-handoff.md" ]; then
  echo "Removing existing command symlink..."
  rm "$CLAUDE_DIR/commands/codex-handoff.md"
elif [ -f "$CLAUDE_DIR/commands/codex-handoff.md" ]; then
  echo "Warning: $CLAUDE_DIR/commands/codex-handoff.md exists as a regular file."
  echo "Back it up and remove it, then re-run install.sh"
  exit 1
fi
ln -s "$SCRIPT_DIR/commands/codex-handoff.md" "$CLAUDE_DIR/commands/codex-handoff.md"
echo "  Linked command: codex-handoff.md"

# Symlink the skill directory
if [ -L "$CLAUDE_DIR/skills/codex-handoff" ]; then
  echo "Removing existing skill symlink..."
  rm "$CLAUDE_DIR/skills/codex-handoff"
elif [ -d "$CLAUDE_DIR/skills/codex-handoff" ]; then
  echo "Warning: $CLAUDE_DIR/skills/codex-handoff exists as a regular directory."
  echo "Back it up and remove it, then re-run install.sh"
  exit 1
fi
ln -s "$SCRIPT_DIR/skills/codex-handoff" "$CLAUDE_DIR/skills/codex-handoff"
echo "  Linked skill: codex-handoff/"

echo ""
echo "Done! codex-handoff is now available in Claude Code."
echo "Usage: /codex-handoff [task description]"
