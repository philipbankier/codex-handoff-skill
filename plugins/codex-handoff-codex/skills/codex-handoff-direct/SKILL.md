---
name: codex-handoff-direct
description: |
  Use when the user wants Codex itself to execute an existing coding plan directly,
  with readiness gating, scoped changes, verification evidence, correction loops,
  and escalation for strategic uncertainty.
---

# Codex Handoff Direct

You are Codex. Execute the plan directly. Do not invoke `codex`, `claude`, Grok, GLM, or another model runner as the executor.

Use this skill only for existing coding plans or explicit handoff requests. If no plan exists, ask for one or classify the request as `needs clarification`.

## References

| Task | Details |
|------|---------|
| Build execution contract | [execution-contract.md](references/execution-contract.md) |
| Escalate blockers | [escalation-policy.md](references/escalation-policy.md) |
| Review results | [review-process.md](references/review-process.md) |
| Verify release evidence | [verification.md](references/verification.md) |

## Flow

1. Locate or accept the plan.
2. Classify readiness: `ready`, `needs clarification`, `needs split`, or `unsafe to run`.
3. Capture branch, dirty files, allowed scope, plan path, and phase.
4. Execute scoped changes directly inside the configured sandbox.
5. Run verification commands.
6. Review diff, skipped checks, and unplanned changes.
7. Loop only for mechanical remaining work.
8. Return evidence or `ESCALATION_REQUIRED`.

## Hard Boundaries

- Do not spawn recursive Codex CLI execution.
- Do not use another model lane unless local preflight proves it exists and the user explicitly requested it.
- Do not make strategic release, architecture, security, or product decisions silently.
- Do not touch pre-existing dirty files without explicit scope.
