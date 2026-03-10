# Review Process

After each Codex execution, perform a comprehensive review.

## 4a. Check What Changed

```bash
git diff --stat
git diff  # full diff for detailed review
```

## 4b. Run Tests

- Run the project's test command (e.g., `npm test`, `npm run check`)
- Run the build command if applicable
- Capture pass/fail results

## 4c. Audit Plan Completion

Go through each item in the plan and check:
- Was the file created/modified as specified?
- Does the implementation match what was planned?
- Are there any obvious issues in the diff?

## Scorecard

Create a scorecard with these categories:

| Status | Meaning |
|--------|---------|
| DONE | Implemented correctly |
| PARTIAL | Started but incomplete or buggy |
| MISSING | Not attempted |
| ERRORS | Test failures, build errors |

## Decision Matrix

**ALL items DONE + tests pass:** Move to Final Report (Step 6).

**PARTIAL, MISSING, or ERROR items AND iterations < max:** Build a correction prompt (see [prompt-templates.md](prompt-templates.md)) and re-run Codex.

**Max iterations reached:** Move to Final Report with whatever was accomplished.

## Final Report Format

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
