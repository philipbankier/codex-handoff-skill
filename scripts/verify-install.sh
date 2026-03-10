#!/usr/bin/env bash
set -euo pipefail

echo "codex-handoff installation check"
echo "================================"
echo ""

errors=0

# Check Codex CLI
echo "Codex CLI:"
if command -v codex &>/dev/null; then
  echo "  [OK] codex found: $(codex --version 2>/dev/null || echo 'version unknown')"
else
  echo "  [!!] codex not found — install with: npm install -g @openai/codex"
  errors=$((errors + 1))
fi
echo ""

# Check Claude Code
echo "Claude Code:"
if [ -d "$HOME/.claude" ]; then
  if [ -L "$HOME/.claude/skills/codex-handoff" ]; then
    target="$(readlink "$HOME/.claude/skills/codex-handoff")"
    if [ -d "$target" ]; then
      echo "  [OK] skill symlink: $HOME/.claude/skills/codex-handoff -> $target"
    else
      echo "  [!!] skill symlink broken: $target does not exist"
      errors=$((errors + 1))
    fi
  elif [ -d "$HOME/.claude/skills/codex-handoff" ]; then
    echo "  [OK] skill directory exists (not a symlink — manual install)"
  else
    echo "  [--] skill not installed"
    errors=$((errors + 1))
  fi

  if [ -L "$HOME/.claude/commands/codex-handoff.md" ]; then
    target="$(readlink "$HOME/.claude/commands/codex-handoff.md")"
    if [ -f "$target" ]; then
      echo "  [OK] command symlink: $HOME/.claude/commands/codex-handoff.md -> $target"
    else
      echo "  [!!] command symlink broken: $target does not exist"
      errors=$((errors + 1))
    fi
  elif [ -f "$HOME/.claude/commands/codex-handoff.md" ]; then
    echo "  [OK] command file exists (not a symlink — manual install)"
  else
    echo "  [--] command not installed"
    errors=$((errors + 1))
  fi
else
  echo "  [--] ~/.claude/ directory not found"
fi
echo ""

# Check OpenClaw
echo "OpenClaw:"
openclaw_found=false
for dir in "$HOME/.openclaw" "$HOME/.clawdbot"; do
  if [ -d "$dir" ]; then
    openclaw_found=true
    if [ -L "$dir/skills/codex-handoff" ]; then
      target="$(readlink "$dir/skills/codex-handoff")"
      if [ -d "$target" ]; then
        echo "  [OK] skill symlink: $dir/skills/codex-handoff -> $target"
      else
        echo "  [!!] skill symlink broken: $target does not exist"
        errors=$((errors + 1))
      fi
    else
      echo "  [--] skill not installed in $dir"
    fi
  fi
done
if [ "$openclaw_found" = false ]; then
  echo "  [--] OpenClaw not detected (no ~/.openclaw or ~/.clawdbot)"
fi
echo ""

# Summary
echo "================================"
if [ "$errors" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$errors issue(s) found."
fi
