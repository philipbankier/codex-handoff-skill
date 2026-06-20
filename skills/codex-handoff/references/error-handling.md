# Error Handling

## Common Errors And Responses

| Error | Response |
|-------|----------|
| Codex not installed | Point to official Codex CLI install docs and ask the user to verify with `codex --version`. |
| Codex CLI too old | Upgrade from the official Codex CLI docs, then re-run `codex --version` and any model preflight. |
| Model override not verified | Omit `-m MODEL` or ask the user to confirm the local account/catalog supports it. |
| Codex exits with error | Capture stdout, stderr, and exit code. Include exact failure text in the correction prompt or stop if unsafe. |
| No git repo | Ask before proceeding. Diff review is limited, so do not claim verified completion without another evidence source. |
| Tests not configured | Record the skipped check and reason. Use unverified status unless another meaningful check exists. |
| Codex hangs | Large tasks can be slow. Wait if there is output or process activity; stop and ask if it appears stalled. |
| Permission error | Keep the workspace sandbox. Ask the user to perform out-of-scope setup manually. |

## Troubleshooting

## Command Not Found: codex

Codex CLI is not installed or not in PATH.

```bash
codex --version
```

If that fails, install Codex CLI from the official docs:

https://developers.openai.com/codex/cli

Then open a new shell and run `codex --version` again.

## Model Requires Newer Codex CLI

If Codex exits with a message that the selected model requires a newer Codex version, upgrade Codex CLI from the official docs, then retry without a model override unless the local account/catalog check passes.

## No Plan Found

The skill searches for plans in this order:

1. Argument text matched against plan filenames and content
2. `docs/plans/*.md`, most recent by date prefix
3. `.claude/plans/*.md`, any recent plan files

Create a plan first, or provide the plan inline with the command. Optional planning helpers such as `/brainstorming` and `/writing-plans` are examples only.

## Codex Produces Incorrect Or Incomplete Output

Review the diff and verification evidence. If the work is close and still in scope, build a correction prompt with:

- completed items
- remaining items
- exact failing commands and exit codes
- unplanned diffs
- allowed scope
- stop conditions

If the same issue repeats or scope is unclear, stop and ask the user.

## Permission Errors During Codex Execution

The standard command uses a temporary prompt file:

```bash
prompt_file="$(mktemp -t codex-handoff.XXXXXX.md)"
# Write the rendered contract to "$prompt_file", then run:
codex exec -C "{target_dir}" --sandbox workspace-write < "$prompt_file"
```

If the plan needs system-level setup, global installs, or access outside the target repo, stop and ask the user to handle that setup separately.

## Codex Modifies Files Outside The Plan

Flag those files as `UNPLANNED` in the scorecard. Compare against the pre-run baseline before asking Codex to revert anything. Revert only Codex-created out-of-scope changes, and ask the user before touching pre-existing dirty files.
