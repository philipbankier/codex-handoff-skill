---
name: codex-handoff
description: Use when offloading a finalized coding plan to Codex CLI for execution. Claude Code supervises and judges completion in a loop. Triggered by /codex-handoff or when user says "hand off to codex", "let codex do it", "offload to codex".
---

# Codex Handoff — Supervisor Loop

Claude Code is the **supervisor/judge**. Codex CLI is the **executor**. You orchestrate a loop: send plan to Codex, review results, re-run if incomplete, until the task is comprehensively done.

**Announce at start:** "Using codex-handoff to orchestrate Codex CLI execution of the plan."

## Prerequisites

- Codex CLI must be installed (`codex --version`)
- A plan must exist (in `docs/plans/`, `.claude/plans/`, or provided inline)
- The working directory should be a git repo (for diff-based review)

## Process

### Step 1: LOCATE THE PLAN

Find the plan to execute. Search in order:

1. If user provided a task description with the command, use that as context to find the relevant plan
2. Check `docs/plans/` for the most recent `.md` file (sorted by date prefix)
3. Check `.claude/plans/` for any recent plan files
4. If no plan found, tell the user: "No plan found. Please create one first using /brainstorming or /writing-plans."

Once found:
- Read the plan file completely
- Present a brief summary to the user
- Ask: "Ready to hand off to Codex CLI?"
- Wait for confirmation before proceeding

### Step 2: BUILD THE CODEX PROMPT

Create a structured prompt file at `/tmp/codex-handoff-{timestamp}.md`. The prompt must include:

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

Also collect:
- Read `CLAUDE.md` if it exists (for coding standards)
- Read `.codex/AGENTS.md` if it exists
- Detect test/build commands from `package.json`

### Step 3: EXECUTE CODEX

Parse optional arguments from the user's command:
- `--max-iterations N` → set max loop iterations (default: 5)
- `--model MODEL` → pass to codex as `-m MODEL`

Run Codex non-interactively:

```bash
codex exec --full-auto -s workspace-write < /tmp/codex-handoff-{timestamp}.md
```

If `--model` was specified:
```bash
codex exec --full-auto -s workspace-write -m {MODEL} < /tmp/codex-handoff-{timestamp}.md
```

**Important:**
- Let the command run to completion — do NOT interrupt it
- Capture both stdout and the exit code
- This may take several minutes for large plans

After Codex finishes, report to user: "Codex iteration {N} complete. Reviewing changes..."

### Step 4: REVIEW THE RESULTS

After each Codex execution, perform a comprehensive review:

**4a. Check what changed:**
```bash
git diff --stat
git diff  # full diff for detailed review
```

**4b. Run tests:**
- Run the project's test command (e.g., `npm test`, `npm run check`)
- Run the build command if applicable
- Capture pass/fail results

**4c. Audit plan completion:**
Go through each item in the plan and check:
- Was the file created/modified as specified?
- Does the implementation match what was planned?
- Are there any obvious issues in the diff?

Create a scorecard:
- DONE items (implemented correctly)
- PARTIAL items (started but incomplete or buggy)
- MISSING items (not attempted)
- ERRORS (test failures, build errors)

### Step 5: DECIDE — LOOP OR COMPLETE

**If ALL items DONE + tests pass:**
- Move to Step 6 (Final Report)

**If there are PARTIAL, MISSING, or ERROR items AND iterations < max:**
Build a correction prompt and write to `/tmp/codex-handoff-correction-{timestamp}.md`:

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

**If max iterations reached:**
- Move to Step 6 with whatever was accomplished

### Step 6: FINAL REPORT

Present to the user:

```
## Codex Handoff Complete

Iterations: {N}
Status: {COMPLETE | PARTIAL — X of Y items done}

### Completed Items
- [x] Item 1
- [x] Item 2

### Remaining Items (if any)
- [ ] Item 3 — reason it wasn't completed

### Test Results
{pass/fail summary}

### Changes Made
{git diff --stat output}
```

If there are remaining items, suggest: "You can run `/codex-handoff` again to continue, or handle the remaining items manually."

## Error Handling

- **Codex not installed:** Tell user to install with `npm install -g @openai/codex`
- **Codex exits with error:** Show the error output, ask user how to proceed
- **No git repo:** Warn that review will be limited (no diff), but proceed anyway
- **Tests not configured:** Skip test step, review based on diff only
- **Codex hangs (>10min per iteration):** This is normal for large tasks — wait patiently

## Key Principles

1. **Never modify code yourself** — Your job is to supervise, not code. Codex does the coding.
2. **Be a strict judge** — Don't pass items as "done" unless they genuinely are.
3. **Correction prompts are specific** — Tell Codex exactly what's wrong and what to fix.
4. **Respect the plan** — Don't add or remove plan items. Execute what was planned.
5. **Keep the user informed** — Report status after each iteration.
