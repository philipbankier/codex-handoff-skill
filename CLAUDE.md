# codex-handoff

This is an AI agent skill repository, not a software project. It contains instruction files (markdown) and shell scripts — no application code.

## Structure

- `skills/codex-handoff/SKILL.md` — Primary skill definition. Keep under 5KB.
- `skills/codex-handoff/references/` — Detailed reference files loaded on-demand by the skill.
- `commands/codex-handoff.md` — Claude Code slash command definition. Keep lean (<15 lines).
- `install.sh` / `uninstall.sh` — POSIX-compatible shell scripts. Must work on macOS and Linux.
- `openclaw.yaml` — OpenClaw platform manifest.

## Conventions

- All `.md` files in `skills/` and `commands/` use YAML frontmatter delimited by `---`.
- Reference files use standard markdown with no frontmatter.
- Shell scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- This repo uses symlink-based installation — edits to source files take effect immediately in the user's agent platform.

## Important

- Do not add application code, package.json, or build tooling to this repo.
- Do not exceed 5KB for SKILL.md. Extract detailed content to `references/`.
- Test install/uninstall scripts on both macOS and Linux when modifying them.
