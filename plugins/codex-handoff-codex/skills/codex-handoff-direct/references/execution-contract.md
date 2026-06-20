# Execution Contract

Before editing, record:

- Goal
- Plan path or inline plan
- Phase
- Baseline branch
- Baseline `git status --short`
- Allowed scope
- Off-limits scope
- Verification commands
- Stop conditions

Proceed only when readiness is `ready`.

Readiness gates:

| Gate | Meaning |
|------|---------|
| `ready` | Goal, scope, checks, and stop conditions are clear |
| `needs clarification` | Required inputs or choices are missing |
| `needs split` | Plan is too broad for one direct run |
| `unsafe to run` | Plan risks destructive work, secrets, broad permissions, or production data |

For correction loops, work only on remaining scoped items. If the next step changes scope or strategy, escalate.
