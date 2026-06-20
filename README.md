# codex-handoff

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)
[![Claude Code](https://img.shields.io/badge/platform-Claude%20Code-blueviolet.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OpenClaw](https://img.shields.io/badge/platform-OpenClaw-orange.svg)](https://github.com/openclaw)

Hand off ready coding plans to [Codex CLI](https://github.com/openai/codex) for execution. Claude Code supervises, reviews evidence, and decides whether the work is done.

The product idea is simple: Claude Code manages and judges. Codex CLI performs token-heavy execution and mechanical repo work.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code). OpenClaw skill files and manifest are included, but verify your local OpenClaw install before relying on it.

## Quick Start

1. Install codex-handoff:

```bash
git clone https://github.com/philipbankier/codex-handoff-skill.git
cd codex-handoff
bash install.sh
```

2. Make sure Codex CLI is installed and on PATH:

```bash
codex --version
```

If `codex` is missing, use the [official Codex CLI install docs](https://developers.openai.com/codex/cli).

3. Create or choose a plan, then hand it off:

> "Hand this plan off to Codex"

Optional: if you already use [superpowers](https://github.com/obra/superpowers), `/brainstorming` and `/writing-plans` are useful ways to create plans first. They are examples, not dependencies.

Claude Code checks that the plan is ready, captures the pre-run baseline, sends a contract-shaped prompt to Codex CLI, reviews the diff and command evidence, and loops only when the supervisor finds specific gaps.

## Install

The easy path is to give this repo URL to Claude Code or OpenClaw and ask it to install:

> "Install and set up https://github.com/philipbankier/codex-handoff-skill"

Manual install:

```bash
git clone https://github.com/philipbankier/codex-handoff-skill.git
cd codex-handoff
bash install.sh
```

Platform-specific install:

```bash
bash install.sh --platform=claude-code
bash install.sh --platform=openclaw
```

This repo uses symlinks into the agent config directory. Updates apply with `git pull`.

Prerequisites:

| Tool        | Requirement                                                   |
|-------------|---------------------------------------------------------------|
| Claude Code | Required for the slash command workflow                       |
| OpenClaw    | Optional skill install path, verify locally                   |
| Codex CLI   | Required executor, verify with `codex --version`              |

Use the [official Codex CLI install docs](https://developers.openai.com/codex/cli) for current install and upgrade methods.

## Experimental Codex Plugin Install

`1.2.0` includes an experimental Codex-native plugin for direct execution.

Use this path when you want Codex itself to locate or accept a plan, execute scoped changes in its sandbox, run checks, review evidence, and escalate strategic blockers.

```bash
codex plugin marketplace add ./
```

Check your installed Codex CLI help before relying on plugin commands:

```bash
codex plugin --help
codex plugin marketplace --help
```

Direct Codex mode is autonomous for routine scoped work. It must stop with `ESCALATION_REQUIRED` when assumptions are overturned, scope expands, credentials are missing, verification cannot prove completion, or strategic choices appear.

If your Codex CLI uses a different plugin command shape, follow `codex plugin marketplace --help` and keep the same local repository root as the marketplace source.

## Verify / Uninstall

```bash
bash scripts/verify-install.sh
bash uninstall.sh
```

## Recommended Workflow

1. Start from a real plan. It can be in `docs/plans/`, `.claude/plans/`, or provided inline.
2. Ask Claude Code to hand it off to Codex.
3. Claude Code applies the readiness gate:

| Gate                | Meaning                                                     |
|---------------------|-------------------------------------------------------------|
| ready               | Goal, scope, constraints, checks, and stop conditions exist |
| needs clarification | The plan has unresolved choices or missing inputs           |
| needs split         | The plan is too broad for one executor run                  |
| unsafe to run       | The plan risks destructive, secret, or broad-permission work |

4. Claude Code captures the pre-run baseline:

```bash
git branch --show-current
git status --short
```

It records dirty files, the plan path, and the phase being executed.

5. Codex CLI runs with a pinned working directory and workspace-write sandbox. The supervisor should write the prompt to a `mktemp` file and clean it up after the run:

```bash
prompt_file="$(mktemp -t codex-handoff.XXXXXX.md)"
# Write the rendered contract to "$prompt_file", then run:
codex exec -C "{target_dir}" --sandbox workspace-write < "$prompt_file"
```

Model overrides are account and catalog dependent. Only pass `-m MODEL` after verifying that the installed local Codex CLI and account support that model. Otherwise, omit it and use the Codex default.

6. Claude Code reviews the result using evidence:

- exact verification commands
- exit codes
- skipped checks with reasons
- unplanned diff audit
- plan item scorecard

No executor note is a pass condition. Claude Code owns the final decision.

## Other Ways To Trigger

```text
/codex-handoff
/codex-handoff add auth to the API
/codex-handoff --max-iterations 3
/codex-handoff --model MODEL
/codex-handoff --phase 2
```

## Compatibility

| Platform     | Status                                  | Skill | Slash Command     | Install Path               |
|--------------|-----------------------------------------|-------|-------------------|----------------------------|
| Claude Code  | Stable supervisor workflow              | Yes   | `/codex-handoff`  | `~/.claude/`               |
| OpenClaw     | Existing skill files and manifest       | Yes   | Description match | `~/.openclaw/`             |
| Codex plugin | Experimental direct execution workflow  | Yes   | N/A               | local plugin marketplace   |
| Codex CLI    | Required executor for stable path       | N/A   | N/A               | User PATH                  |

## Configuration

| Option               | Default       | Description                                                   |
|----------------------|---------------|---------------------------------------------------------------|
| `--max-iterations N` | `5`           | Maximum supervisor loop iterations per phase                  |
| `--model MODEL`      | Codex default | Optional model override after local account/catalog check     |
| `--phase N`          | All phases    | Execute only phase N when a plan has phases                   |

## Examples

- [Simple walkthrough](examples/simple/) shows a captured single-pass handoff with plan, output, scorecard, and generated code.
- [Advanced multi-phase plan](examples/advanced-momentum-trader/) shows a larger phased workflow.

## How It Works Under The Hood

```text
Your AI Agent (Supervisor / Judge)
  -> sends contract prompt
Codex CLI (Executor)
  -> edits code and runs checks in the target repo
Your AI Agent
  -> reviews diff, commands, exit codes, and plan completion
```

Supervisor loop:

1. Locate the plan from arguments, `docs/plans/`, `.claude/plans/`, or inline text.
2. Detect phases and decide single-pass or phase-scoped execution.
3. Apply the readiness gate and ask before running when the plan is not ready.
4. Capture branch, `git status --short`, dirty files, plan path, and phase.
5. Build a contract-shaped Codex prompt with Goal, Context, Constraints, Allowed scope, Done when, Verification commands, and Stop conditions.
6. Rely on Codex AGENTS.md auto-discovery. Summarize relevant local instructions only when needed. Do not paste full local instruction files by default.
7. Execute Codex with `-C "{target_dir}" --sandbox workspace-write`.
8. Review the git diff, verification commands, exit codes, skipped checks, and unplanned changes.
9. Decide whether to loop, split, stop, or report completion.

## Phased Execution

For large plans with clear phase headings, codex-handoff executes one phase at a time:

- each phase gets a focused prompt
- completed phase summaries are carried forward
- scorecards are scoped to the current phase
- failed phases can be retried with `--phase N`

Plans without phase headings run in single-pass mode.

## Plan Discovery

Plans are searched in order:

1. Argument text matched against plan filenames and content
2. `docs/plans/*.md`, most recent file by date prefix
3. `.claude/plans/*.md`, any recent plan files

## Troubleshooting

Command not found: `codex`

```bash
codex --version
```

If that fails, install Codex CLI from the [official docs](https://developers.openai.com/codex/cli).

Skill not showing up:

```bash
bash scripts/verify-install.sh
```

If symlinks are broken, re-run `bash install.sh`.

No plan found:

Create a plan first. Plans are searched in `docs/plans/`, `.claude/plans/`, or can be provided inline. See [`resources/example-plan.md`](resources/example-plan.md) for the expected format.

Codex produces incomplete results:

The supervisor loop is designed for this. Claude Code reviews each iteration, builds a correction prompt with exact remaining work, and re-runs Codex while the max-iteration limit allows it.

## Repo Structure

```text
codex-handoff/
|- commands/codex-handoff.md
|- skills/codex-handoff/
|  |- SKILL.md
|  `- references/
|     |- prompt-templates.md
|     |- review-process.md
|     |- escalation-policy.md
|     `- error-handling.md
|- examples/
|- resources/example-plan.md
|- scripts/verify-install.sh
|- install.sh
|- uninstall.sh
|- openclaw.yaml
|- CONTRIBUTING.md
|- CODE_OF_CONDUCT.md
|- CHANGELOG.md
`- LICENSE
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, guidelines, and PR process.

## License

[MIT](LICENSE)
