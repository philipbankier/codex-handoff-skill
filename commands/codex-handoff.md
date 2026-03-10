---
description: "Hand off a coding plan to Codex CLI for execution. Claude Code supervises, reviews diffs, and loops until complete."
argument-hint: "[task description] [--max-iterations N] [--model MODEL]"
---

# Codex Handoff

Use the `codex-handoff` skill to orchestrate Codex CLI execution of the current plan. Claude Code acts as the supervisor and judge — Codex CLI does the coding.

Task: $ARGUMENTS
