# Escalation Policy

Continue only while the plan, allowed scope, sandbox, and verification path remain valid.

Escalate to the user instead of re-running Codex when the next step:

- changes scope
- weakens verification
- changes architecture
- touches pre-existing dirty files
- requires broader permissions
- depends on a missing credential or service
- reveals a possible secret
- requires destructive or irreversible work
- makes a model, CLI, package, or platform assumption false

Use this format:

```markdown
## Escalation Required

Status: {BLOCKED | STRATEGIC_DECISION | UNSAFE | VERIFY_GAP}

## Facts
- {specific evidence}

## Impact
- {plan item or constraint affected}

## Options
1. {option}
2. {option}
3. {option}

## Recommended Default
Choose option {N} because {reason}.

## Safe To Continue
{yes/no, with exact scope}
```

Do not ask an open-ended question. Present facts, options, and a recommended default.
