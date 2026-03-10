# Prompt Templates

Templates used by the supervisor to construct Codex CLI prompts.

## Initial Execution Prompt

Create a structured prompt file at `/tmp/codex-handoff-{timestamp}.md` with this format:

```markdown
# Task

You are executing a coding plan. Complete ALL items below. Do not skip any steps.

## Plan

{FULL PLAN CONTENT HERE}

## Project Context

- Working directory: {pwd}
- Package manager: {npm/yarn/pnpm/bun — detect from lockfile}
- Test command: {from package.json scripts or plan}
- Build command: {from package.json scripts or plan}

## Coding Standards

{Contents of CLAUDE.md or .codex/AGENTS.md if they exist, otherwise omit}

## Instructions

1. Implement each plan item in order
2. After each significant change, run the test command to verify
3. Write clean, minimal code — follow existing patterns in the codebase
4. Do NOT add unnecessary comments, docs, or abstractions beyond what the plan specifies
5. When ALL items are complete and tests pass, output: CODEX_COMPLETE
6. If you get stuck on an item, implement what you can and note what failed
```

### Context Collection

Before building the prompt, collect:
- Read `CLAUDE.md` if it exists (for coding standards)
- Read `.codex/AGENTS.md` if it exists
- Detect test/build commands from `package.json`

## Correction Prompt (for re-runs)

When items remain incomplete after a Codex iteration, write a correction prompt to `/tmp/codex-handoff-correction-{timestamp}.md`:

```markdown
# Correction — Iteration {N+1}

## What was completed successfully
{list completed items}

## What still needs to be done
{list remaining items with specific instructions}

## Errors to fix
{test failures, build errors, or issues found in review}

## Important
- Focus ONLY on the remaining items — do not redo completed work
- Run tests after each fix
- When ALL remaining items are complete and tests pass, output: CODEX_COMPLETE
```

Then re-run:
```bash
codex exec --full-auto -s workspace-write < /tmp/codex-handoff-correction-{timestamp}.md
```
