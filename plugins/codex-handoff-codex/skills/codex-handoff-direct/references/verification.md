# Verification

Prefer commands in this order:

1. `script/test`, `script/lint`, `script/check`, or matching `scripts/` commands
2. Commands documented in `AGENTS.md`, `README.md`, `HACKING.md`, or package files
3. Plan-specific commands
4. Focused syntax checks when no test command exists

For every command, record:

- command
- working directory
- exit code
- short result

If no meaningful check runs, do not claim verified completion.
