---
name: Codex Handoff
version: 1.2.0
description: |
  Use when the user wants Claude Code to supervise Codex CLI execution of an existing coding plan,
  including readiness gating, phased execution, verification evidence, and correction loops.
  Claude Code acts as supervisor/judge. Codex CLI does the execution.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Codex Handoff - Supervisor Loop

Claude Code supervises and judges. Codex CLI executes token-heavy code and check work. Pass/fail belongs to the supervisor.

Announce at start: "Using codex-handoff to orchestrate Codex CLI execution of the plan."

## Prerequisites

- Codex CLI installed and verified with `codex --version`.
- A plan exists in `docs/plans/`, `.claude/plans/`, or inline.
- A git repo is preferred for diff-based review.
- Use Bash only for orchestration: git state, prompt files, Codex CLI, and checks. Do not hand-code the task.

## Quick Start

1. Locate the plan.
2. Gate readiness: `ready`, `needs clarification`, `needs split`, or `unsafe to run`.
3. Detect phases if present.
4. Capture branch, `git status --short`, dirty files, plan path, and phase.
5. Build a contract-shaped prompt.
6. Run Codex with pinned directory and workspace sandbox.
7. Review exact command evidence and unplanned diffs.
8. Decide whether to loop, split, stop, or report completion.

## Reference

| Task | Details |
|------|---------|
| Build Codex prompt | [prompt-templates.md](references/prompt-templates.md) |
| Review and audit results | [review-process.md](references/review-process.md) |
| Escalate blockers | [escalation-policy.md](references/escalation-policy.md) |
| Handle errors | [error-handling.md](references/error-handling.md) |

## Process

## Step 1: Locate And Gate The Plan

Search in order:

1. User arguments matched against plan filenames and content
2. `docs/plans/`, most recent `.md` file by date prefix
3. `.claude/plans/`, recent plan files

If no plan is found, tell the user to create or provide one. `/brainstorming` and `/writing-plans` are optional examples if installed, not required dependencies.

Read the plan completely, summarize it, then classify readiness:

| Gate | Use When |
|------|----------|
| `ready` | Goal, scope, checks, and stop conditions are clear |
| `needs clarification` | Required inputs or choices are missing |
| `needs split` | Plan is too broad for one Codex run |
| `unsafe to run` | Plan risks destructive work, secrets, or broad permissions |

Ask the user before running unless they already gave explicit approval for this exact plan and scope.

## Step 2: Detect Phases

Scan for H2 headings matching `## Phase N:`, `## Stage N:`, `## Part N:`, or numbered H2 sections like `## 1. Backend`.

- Phases found: report the count and execute sequentially.
- No phases: run single-pass.
- `--phase N`: run only that phase.

## Step 3: Build The Codex Prompt

See [prompt-templates.md](references/prompt-templates.md). Each prompt must include:

- Goal
- Context, including target directory and pre-run baseline
- Constraints
- Allowed scope
- Done when
- Verification commands
- Stop conditions

Codex auto-discovers project `AGENTS.md`. Do not paste full local instruction files by default.

## Step 4: Execute Codex

Arguments:

- `--max-iterations N`: default 5, per phase in phased mode
- `--model MODEL`: optional; pass only after verifying the local Codex install/account supports it
- `--phase N`: execute only phase N

```bash
prompt_file="$(mktemp -t codex-handoff.XXXXXX.md)"
# Write the rendered contract to "$prompt_file", then run:
codex exec -C "{target_dir}" --sandbox workspace-write [-m MODEL] < "$prompt_file"
```

Capture stdout, stderr, and exit code. Review before deciding.

## Step 5: Review The Results

See [review-process.md](references/review-process.md). Review is supervisor-owned:

- compare against the pre-run baseline
- inspect `git diff --stat` and `git diff`
- run listed verification commands
- record exact commands, exit codes, and skipped checks with reasons
- audit unplanned file changes
- score each plan item

Executor notes are useful context only. They are not pass conditions.

## Step 6: Decide

- All scoped items done and evidence passes: advance or report done.
- Items remain and iterations remain: build a correction prompt and re-run.
- Missing inputs, unsafe scope, or repeated failure: stop and ask the user.
- No meaningful checks available: report unverified status, but do not claim verified completion.

## Key Principles

1. Supervise, do not code the task yourself.
2. Be a strict judge. Pass only what the diff and command evidence support.
3. Keep correction prompts specific and scoped.
4. Respect the plan. Do not add speculative work.
5. Keep the user informed after each iteration and phase transition.
