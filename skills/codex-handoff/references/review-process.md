# Review Process

After each Codex execution, the supervisor reviews evidence. Executor self-reports are notes, not pass conditions.

## 4a. Compare Against Baseline

Use the pre-run baseline captured before execution:

```bash
git branch --show-current
git status --short
```

Then inspect the new diff:

```bash
git status --short
git diff --stat
git diff
```

Record untracked, modified, deleted, and renamed files. Flag any file outside the allowed scope as `UNPLANNED`.

## 4b. Run Verification

Run the verification commands listed in the prompt or plan. For each command, record:

- exact command
- working directory
- exit code
- short result summary
- Codex CLI version or executor version
- exact executor command or direct-mode action
- artifact paths for saved prompt, logs, scorecard, or eval output
- secret scan result for changed files

If a check is skipped, record the exact reason. Examples: command is not configured, dependency is missing, service credentials are absent, or the plan intentionally has no runnable checks.

Do not report verified completion when no meaningful check ran. Use a status such as `DONE, VERIFICATION SKIPPED` and explain the gap.

## 4c. Audit Plan Completion

For each scoped plan item, check:

- Was the requested file created, edited, or left unchanged for a valid reason?
- Does the diff match the plan without speculative work?
- Did verification cover the changed behavior?
- Are there unplanned diffs or generated files?

## Scorecard

| Status      | Meaning                                         |
|-------------|-------------------------------------------------|
| DONE        | Implemented and supported by review evidence    |
| PARTIAL     | Started but incomplete or questionable          |
| MISSING     | Not attempted                                   |
| ERRORS      | Verification failed                             |
| UNPLANNED   | Diff outside allowed scope                      |
| UNVERIFIED  | Looks done, but checks did not run              |

## Decision Matrix

| Condition                                      | Action                                      |
|------------------------------------------------|---------------------------------------------|
| Items DONE, checks pass, no unplanned diffs    | Advance phase or final report as complete   |
| Items remain and iterations remain             | Build a scoped correction prompt            |
| Verification failed                            | Build correction prompt with exact failures |
| Unplanned diffs exist                          | Compare baseline, then revert only Codex-created out-of-scope changes or ask the user |
| No meaningful checks ran                       | Report unverified status                    |
| Max iterations reached                         | Stop and report remaining work              |
| Scope, safety, or missing input blocks review  | Stop and ask the user                       |

## Final Report Format

Present:

````markdown
## Codex Handoff Result

Iterations: {N}
Status: {COMPLETE | PARTIAL | BLOCKED | DONE, VERIFICATION SKIPPED}

Plan: {plan path}
Phase: {all | N of total}
Baseline branch: {branch}

## Completed Items
- [x] Item 1
- [x] Item 2

## Remaining Items
- [ ] Item 3: {reason}

## Verification Evidence
| Command | Exit Code | Result |
|---------|-----------|--------|
| `{cmd}` | `{code}`  | {short result} |

Skipped checks:
- {check}: {reason}

## Unplanned Diff Audit
{none | list files and action taken}

## Changes Made
```text
{git diff --stat output}
```
````

If items remain, suggest a concrete next action such as retrying a phase, splitting the plan, adding missing verification, or handling a blocker manually.

## Phased Execution Review

Review each phase only against that phase's allowed scope. After a phase passes, record:

```markdown
Phase {N}: {title}
Status: {COMPLETE | PARTIAL | BLOCKED | DONE, VERIFICATION SKIPPED}
Iterations: {M}
Files changed: {list}
Verification: {commands and exit codes}
Key changes: {one short summary}
```

Feed this phase summary, not the full phase text, into the next phase prompt.

When a phase fails at max iterations, ask whether to stop, retry the same phase, or continue with a recorded partial summary.
