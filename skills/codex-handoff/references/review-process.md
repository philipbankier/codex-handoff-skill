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

## Phased Execution Review

When executing a multi-phase plan, the review process is scoped per-phase.

### Per-Phase Scorecard

The scorecard covers only the current phase's items. After a phase completes (all items DONE + tests pass), record a **phase summary**:

```
Phase {N}: {title}
Status: COMPLETE
Iterations: {M}
Files changed: {list of files created/modified}
Key changes: {1-2 sentence summary}
```

This summary is fed as context to the next phase's Codex prompt (see [prompt-templates.md](prompt-templates.md) "Completed Phases" section).

### Per-Phase Decision Matrix

**All phase items DONE + tests pass:** Record phase summary, advance to next phase.

**Items remain AND iterations < max (per-phase):** Build a phase correction prompt and re-run Codex.

**Max iterations reached for this phase:** Ask user:
- "Phase {N} incomplete after {max} iterations. Continue to Phase {N+1}, or stop here?"
- Record partial phase summary either way.

### Phased Final Report Format

```
## Codex Handoff Complete

Phases: {completed}/{total}
Total iterations: {sum across all phases}

### Phase 1: {title} — COMPLETE (2 iterations)
- [x] Item 1.1
- [x] Item 1.2

### Phase 2: {title} — COMPLETE (1 iteration)
- [x] Item 2.1
- [x] Item 2.2

### Phase 3: {title} — PARTIAL (3/5 items, max iterations reached)
- [x] Item 3.1
- [x] Item 3.2
- [x] Item 3.3
- [ ] Item 3.4 — reason
- [ ] Item 3.5 — reason

### Test Results
{pass/fail summary}

### Changes Made
{git diff --stat output}
```

If phases remain incomplete, suggest: "You can run `/codex-handoff --phase N` to retry a specific phase, or handle the remaining items manually."
