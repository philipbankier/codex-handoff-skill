# Review Process

Review is evidence-based.

Record:

- executor version
- baseline branch and dirty files
- allowed scope
- `git status --short`
- `git diff --stat`
- reviewed `git diff`
- unplanned diff audit
- exact verification commands
- exit codes
- skipped checks and reasons
- secret scan result

Statuses:

| Status | Meaning |
|--------|---------|
| COMPLETE | Scoped items done, checks pass, no unplanned diffs |
| PARTIAL | Some scoped items remain |
| BLOCKED | Missing input, service, credential, or strategic decision |
| DONE, VERIFICATION SKIPPED | Looks done, but meaningful checks did not run |
| ESCALATION_REQUIRED | A strategic or safety boundary was reached |
