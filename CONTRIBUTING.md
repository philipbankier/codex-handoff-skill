# Contributing to codex-handoff

Thanks for your interest in contributing! This is a skill repository for AI agent platforms — it contains markdown instruction files and shell scripts, not application code.

## Getting Started

1. **Fork and clone** the repo
2. **Install locally** using symlinks:
   ```bash
   bash install.sh
   ```
   Edits to source files take effect immediately — no rebuild needed.

3. **Verify** your installation:
   ```bash
   bash scripts/verify-install.sh
   ```

## What You Can Contribute

- **Skill improvements** — Better prompts, clearer instructions, edge case handling
- **New reference docs** — Guides for specific workflows or troubleshooting scenarios
- **Shell script fixes** — Portability improvements, better error messages
- **Examples** — Real-world plans and walkthroughs demonstrating codex-handoff usage
- **Bug reports** — Installation issues, unclear documentation, unexpected behavior

## Guidelines

### Skill Files (`skills/codex-handoff/`)

- **SKILL.md** must stay under **5KB**. If you're adding detail, extract it to a file in `references/`.
- Reference files use standard markdown with no YAML frontmatter.
- Keep instructions actionable and concise — the audience is an AI agent, not a human reader.

### Shell Scripts

- Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- Scripts must work on both **macOS** and **Linux**.
- Test `install.sh` and `uninstall.sh` on both platforms when modifying them.

### Markdown Files

- Files in `skills/` and `commands/` use YAML frontmatter delimited by `---`.
- Use clear, scannable formatting (headers, bullet points, code blocks).

### Commits

- Write clear, descriptive commit messages.
- Keep commits focused — one logical change per commit.

## Submitting a Pull Request

1. Create a feature branch from `main`.
2. Make your changes.
3. Test with:
   ```bash
   bash install.sh && bash scripts/verify-install.sh
   ```
4. Open a PR with a clear description of what changed and why.

## Reporting Issues

Open a GitHub issue with:
- What you expected to happen
- What actually happened
- Your platform (macOS/Linux) and agent platform (Claude Code/OpenClaw)
- Output of `bash scripts/verify-install.sh` if it's an installation issue

## Important

- Do **not** add application code, `package.json`, or build tooling to this repo.
- Do **not** commit `.env` files, API keys, or personal configuration.
- This repo uses symlink-based installation — keep that architecture intact.
