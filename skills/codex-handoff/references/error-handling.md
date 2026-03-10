# Error Handling

## Common Errors and Responses

| Error | Response |
|-------|----------|
| **Codex not installed** | Tell user: `npm install -g @openai/codex` |
| **Codex exits with error** | Show error output, ask user how to proceed |
| **No git repo** | Warn that review will be limited (no diff), proceed anyway |
| **Tests not configured** | Skip test step, review based on diff only |
| **Codex hangs (>10min)** | Normal for large tasks — wait patiently |

## Troubleshooting

### "command not found: codex"

Codex CLI is not installed or not in PATH.

```bash
# Install
npm install -g @openai/codex

# Verify
codex --version
```

If installed but not found, check that your npm global bin directory is in PATH:
```bash
npm config get prefix
# Add {prefix}/bin to your PATH if missing
```

### "No plan found"

The skill searches for plans in this order:
1. Argument text matched against plan filenames/content
2. `docs/plans/*.md` — most recent by date prefix
3. `.claude/plans/*.md` — any recent plan files

Create a plan first using `/brainstorming` or `/writing-plans`, or provide the plan inline with the command.

### Codex produces incorrect or incomplete output

This is expected — the supervisor loop handles it. The review step (Step 4) will detect issues and build a correction prompt for the next iteration. If issues persist after max iterations, the final report will list remaining items.

### Permission errors during Codex execution

Codex runs with `-s workspace-write` which grants write access to the working directory only. If your plan requires broader permissions (e.g., installing packages globally), you may need to run those steps manually before or after the handoff.

### Codex modifies files outside the plan

The review step catches this. Flag it in the scorecard as an issue and include it in the correction prompt with instructions to revert unplanned changes.
