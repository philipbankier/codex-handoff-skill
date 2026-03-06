---
description: "Offload a finalized plan to Codex CLI for execution, with Claude Code as supervisor/judge loop"
argument-hint: "[task description] [--max-iterations N] [--model MODEL]"
---

# Codex Handoff

Use the `codex-handoff` skill to orchestrate Codex CLI execution of the current plan. Claude Code acts as the supervisor and judge — Codex CLI does the coding.

Task: $ARGUMENTS
