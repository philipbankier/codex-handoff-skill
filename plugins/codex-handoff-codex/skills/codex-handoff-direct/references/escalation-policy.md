# Escalation Policy

Continue autonomously only while the plan, allowed scope, sandbox, and verification path remain valid.

Return `ESCALATION_REQUIRED` when:

- the plan's core assumption is false
- requirements conflict with repo or user instructions
- the task expands outside allowed scope
- secrets, credentials, production data, or external auth are needed
- destructive or irreversible changes are needed
- verification cannot prove the done condition
- multiple plausible architecture or product choices exist
- the same failure repeats after one scoped correction
- unplanned diffs appear in risky files
- a requested model or tool lane is unavailable
- direct Codex would need to alter release scope

Escalation report:

```markdown
## Escalation Required

Status: {BLOCKED | STRATEGIC_DECISION | UNSAFE | VERIFY_GAP}

## Facts
- {specific evidence}

## Overturned Assumption
- {plan or prompt assumption that no longer holds}

## Options
1. {option}
2. {option}
3. {option}

## Recommended Default
Choose option {N} because {reason}.

## Safe To Continue
{yes/no, with exact scope}

## Exact Next Step
{one command, approval, plan edit, or decision needed}
```
