---
name: Codex Handoff
version: 1.0.0
description: |
  Offload finalized coding plans to Codex CLI for automated execution.
  Use when: user says "hand off to codex", "let codex do it", "offload to codex",
  runs /codex-handoff, or has a plan ready for Codex CLI execution.
  Claude Code acts as supervisor/judge in a loop — Codex CLI does the coding.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Codex Handoff — Supervisor Loop

Claude Code is the **supervisor/judge**. Codex CLI is the **executor**. You orchestrate a loop: send plan to Codex, review results, re-run if incomplete, until the task is comprehensively done.

**Announce at start:** "Using codex-handoff to orchestrate Codex CLI execution of the plan."

## Prerequisites

- Codex CLI must be installed (`codex --version`)
- A plan must exist (in `docs/plans/`, `.claude/plans/`, or provided inline)
- The working directory should be a git repo (for diff-based review)

## Quick Start

1. **Locate** the plan (from `docs/plans/`, `.claude/plans/`, or user arguments)
2. **Build** a structured Codex prompt with plan + project context + coding standards
3. **Execute** Codex CLI in `--full-auto` mode
4. **Review** git diff, run tests, audit plan completion with a scorecard
5. **Decide** — loop with correction prompt if items remain, or finalize
6. **Report** final status with completed/remaining items and test results

## Reference

| Task | Details |
|------|---------|
| Build Codex prompt | [prompt-templates.md](references/prompt-templates.md) |
| Review & audit results | [review-process.md](references/review-process.md) |
| Handle errors | [error-handling.md](references/error-handling.md) |

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

See [prompt-templates.md](references/prompt-templates.md) for the full prompt template and context collection instructions.

### Step 3: EXECUTE CODEX

Parse optional arguments from the user's command:
- `--max-iterations N` — set max loop iterations (default: 5)
- `--model MODEL` — pass to codex as `-m MODEL`

Run Codex non-interactively:

```bash
codex exec --full-auto -s workspace-write < /tmp/codex-handoff-{timestamp}.md
```

If `--model` was specified:
```bash
codex exec --full-auto -s workspace-write -m {MODEL} < /tmp/codex-handoff-{timestamp}.md
```

**Important:** Let the command run to completion. Capture both stdout and exit code. This may take several minutes for large plans.

After Codex finishes, report to user: "Codex iteration {N} complete. Reviewing changes..."

### Step 4: REVIEW THE RESULTS

See [review-process.md](references/review-process.md) for the full review checklist, scorecard format, and decision matrix.

### Step 5: DECIDE — LOOP OR COMPLETE

- **All items DONE + tests pass:** Move to Step 6.
- **Items remain AND iterations < max:** Build a correction prompt (see [prompt-templates.md](references/prompt-templates.md)) and re-run Codex.
- **Max iterations reached:** Move to Step 6 with whatever was accomplished.

### Step 6: FINAL REPORT

See the report format in [review-process.md](references/review-process.md). If items remain, suggest: "You can run `/codex-handoff` again to continue, or handle the remaining items manually."

## Key Principles

1. **Never modify code yourself** — Your job is to supervise, not code. Codex does the coding.
2. **Be a strict judge** — Don't pass items as "done" unless they genuinely are.
3. **Correction prompts are specific** — Tell Codex exactly what's wrong and what to fix.
4. **Respect the plan** — Don't add or remove plan items. Execute what was planned.
5. **Keep the user informed** — Report status after each iteration.
