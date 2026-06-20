# Prompt Templates

The supervisor writes contract-shaped prompt files for Codex CLI. The contract makes scope, evidence, and stop conditions explicit before execution.

## Initial Execution Prompt

Create the prompt file with `mktemp`:

```bash
prompt_file="$(mktemp -t codex-handoff.XXXXXX.md)"
```

Write the rendered contract to `$prompt_file`, then run Codex with that file as stdin.

````markdown
# Codex Executor Contract

## Goal

{one-paragraph goal}

## Context

- Target directory: {absolute target_dir}
- Plan path: {plan path or inline}
- Plan phase: {all | phase N of total}
- Baseline branch: {branch}
- Baseline dirty files:
  ```text
  {git status --short output}
  ```
- Package manager: {detected from lockfile, or unknown}
- Relevant supervisor notes: {short summary only when needed}

Codex should rely on project AGENTS.md auto-discovery for local instructions. Do not assume pasted instruction files are complete.

## Constraints

- Work only on the goal and plan below.
- Keep changes minimal and match existing style.
- Do not make unrelated cleanups.
- Do not hardcode secrets or credentials.
- Do not use destructive commands.
- Stop before any command that requires permissions outside the workspace sandbox.

## Allowed Scope

- Files/directories allowed: {explicit scope}
- Files/directories off limits: {explicit exclusions}
- For phased execution, do not work outside this phase unless required by this phase.

## Done When

- Every scoped plan item is done.
- Verification commands below pass.
- The git diff contains no unplanned changes.
- Any skipped check has a clear reason.

## Verification Commands

Run these commands and report each exact command with its exit code:

```bash
{command 1}
{command 2}
```

If no checks are configured, say that explicitly and provide the best available evidence from the diff. Do not claim verified completion without meaningful checks.

## Stop Conditions

Stop and report instead of guessing if:

- required credentials, environment variables, or external services are missing
- the plan conflicts with repository instructions
- the scope needs files outside the allowed scope
- a command needs permissions outside the workspace sandbox
- verification cannot run and no reasonable alternate evidence exists

## Escalation Contract

Stop and report `ESCALATION_REQUIRED` when an assumption is overturned or a strategic decision is needed.

Include:

- facts with command output or diff evidence
- impacted plan item or constraint
- 2-3 realistic options
- recommended default action
- safe-to-continue scope

## Plan

{FULL PLAN CONTENT HERE}
````

## Context Collection

Before building the prompt:

- Capture branch, `git status --short`, dirty files, plan path, and phase.
- Detect verification commands from `script/` or `scripts/` first, then repo docs, package files, and the plan.
- Summarize only the local instructions that are directly relevant and not already handled by Codex AGENTS.md auto-discovery.
- Do not paste full local instruction files by default.

Run with:

```bash
codex exec -C "{target_dir}" --sandbox workspace-write < "$prompt_file"
```

Add `-m MODEL` only after local verification that the installed Codex CLI and account support that model.
Remove the prompt file after review unless the user asks to keep it for debugging.

## Correction Prompt

When review finds remaining work, create a correction prompt with `mktemp`:

```bash
prompt_file="$(mktemp -t codex-handoff-correction.XXXXXX.md)"
```

Write the rendered correction contract to `$prompt_file`, then run Codex with that file as stdin.

````markdown
# Codex Correction Contract

## Goal

Finish the remaining scoped work from iteration {N}.

## Context

- Target directory: {absolute target_dir}
- Plan path: {plan path}
- Plan phase: {all | phase N}
- Previous iteration exit code: {exit code}
- Current dirty files:
  ```text
  {git status --short output}
  ```

## Completed Items

{supervisor-owned list of completed items}

## Remaining Items

{specific remaining plan items}

## Issues To Fix

{test failures, build errors, unplanned diffs, or review findings}

## Constraints

- Focus only on remaining items.
- Preserve completed work unless it is directly blocking verification.
- Do not touch files outside allowed scope.

## Allowed Scope

{allowed files/directories}

## Done When

- Remaining items are done.
- Verification commands pass.
- Unplanned diff audit is clean.

## Verification Commands

Report exact commands and exit codes:

```bash
{command 1}
{command 2}
```

## Stop Conditions

Stop if credentials, permissions, scope, or ambiguous requirements block progress.

## Escalation Contract

Stop and report `ESCALATION_REQUIRED` when an assumption is overturned or a strategic decision is needed.

Include:

- facts with command output or diff evidence
- impacted plan item or constraint
- 2-3 realistic options
- recommended default action
- safe-to-continue scope
````

Run with:

```bash
codex exec -C "{target_dir}" --sandbox workspace-write < "$prompt_file"
```

## Phase-Scoped Execution Prompt

For phased plans, use the initial template with these substitutions:

- `Goal`: "Complete Phase {N} of {total}: {phase_title}."
- `Plan phase`: "Phase {N} of {total}."
- `Plan`: include only the current phase content.
- `Context`: include brief summaries of completed phases, not their full text.
- `Allowed Scope`: limit work to the current phase.
- `Done When`: current phase items are done and verification passes.

## Phase Correction Prompt

Use the correction template, scoped to the current phase:

- completed items from this phase only
- remaining items from this phase only
- completed phase summaries for prior phases
- no work on future phases unless the current phase explicitly requires it
