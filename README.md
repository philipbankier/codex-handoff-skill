# codex-handoff

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that offloads coding plans to [Codex CLI](https://github.com/openai/codex) for execution, with Claude Code acting as supervisor and judge in an automated loop.

**Claude Code plans. Codex CLI codes. Claude Code reviews.**

## How It Works

```
                   ┌─────────────────────────────────┐
                   │         Claude Code              │
                   │     (Supervisor / Judge)          │
                   └──────────┬──────────┬────────────┘
                              │          ▲
                  1. Send     │          │  4. Review
                     plan     │          │     diff
                              ▼          │
                   ┌─────────────────────────────────┐
                   │          Codex CLI                │
                   │         (Executor)                │
                   └──────────┬──────────┬────────────┘
                              │          ▲
                  2. Write    │          │  3. Run
                     code     │          │     tests
                              ▼          │
                   ┌─────────────────────────────────┐
                   │        Your Codebase              │
                   └──────────────────────────────────┘
```

### The Loop

1. **Locate** — Claude Code finds your plan (from `docs/plans/`, `.claude/plans/`, or inline)
2. **Build prompt** — Constructs a structured prompt with plan, project context, and coding standards
3. **Execute** — Runs Codex CLI in `--full-auto` mode with the prompt
4. **Review** — Claude Code reviews the git diff, runs tests, audits plan completion
5. **Decide** — If items remain and iterations are under the limit, builds a correction prompt and loops back to step 3. Otherwise, presents a final report.

Default max iterations: **5**

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured
- [Codex CLI](https://github.com/openai/codex) installed (`npm install -g @openai/codex`)

## Install

```bash
git clone https://github.com/philipbankier/codex-handoff.git
cd codex-handoff
bash install.sh
```

This creates symlinks in `~/.claude/` pointing back to the repo, so you get updates with `git pull`.

## Uninstall

```bash
cd codex-handoff
bash uninstall.sh
```

## Usage

In any Claude Code session:

```
/codex-handoff                          # uses the most recent plan
/codex-handoff add auth to the API      # finds/uses a relevant plan
/codex-handoff --max-iterations 3       # limit retry loops
/codex-handoff --model o4-mini          # specify Codex model
```

You can also trigger it conversationally:
- "hand off to codex"
- "let codex do it"
- "offload to codex"

### Typical Workflow

1. Plan your feature in Claude Code (e.g., with `/brainstorming` then `/writing-plans`)
2. Run `/codex-handoff` to execute the plan
3. Claude Code sends the plan to Codex, reviews results, and loops until done
4. Review the final report and commit

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `--max-iterations N` | `5` | Maximum supervisor loop iterations |
| `--model MODEL` | Codex default | Model for Codex CLI to use (e.g., `o4-mini`) |

## How It Finds Your Plan

Searched in order:
1. Argument text → matches against plan filenames/content
2. `docs/plans/*.md` → most recent by date prefix
3. `.claude/plans/*.md` → any recent plan files

## Project Context

The handoff prompt automatically includes:
- **Package manager** — detected from lockfile (npm/yarn/pnpm/bun)
- **Test & build commands** — from `package.json` scripts
- **Coding standards** — from `CLAUDE.md` or `.codex/AGENTS.md` if present

## License

MIT
