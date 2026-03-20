# codex-handoff

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)](CHANGELOG.md)
[![Claude Code](https://img.shields.io/badge/platform-Claude%20Code-blueviolet.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OpenClaw](https://img.shields.io/badge/platform-OpenClaw-orange.svg)](https://github.com/openclaw)

Hand off ready-to-go coding plans to [Codex CLI](https://github.com/openai/codex) for execution. Your agent supervises, reviews, and loops until done.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenClaw](https://github.com/openclaw).

## Quick Start

**1. Install [superpowers](https://github.com/obra/superpowers)** for brainstorming and planning skills:

Give your agent the URL and ask it to install:
> "Install https://github.com/obra/superpowers so I can use brainstorming and planning skills"

**2. Install codex-handoff:**

Same approach — give your agent the URL:
> "Install https://github.com/philipbankier/codex-handoff so I can hand off plans to Codex"

**3. Brainstorm, plan, hand off:**
> "Let's brainstorm a markdown link checker CLI" → uses `/brainstorming`
>
> "Write the plan" → uses `/writing-plans`
>
> "Hand it off to codex" → codex-handoff takes over

That's it. Your agent sends the plan to Codex CLI, reviews the results, and loops if anything is incomplete. You review the final output and commit.

## Install

### The easy way (recommended)

Give the repo URL to your Claude Code or OpenClaw agent and ask it to install:

> "Install and set up https://github.com/philipbankier/codex-handoff"

The agent will clone the repo, run the installer, and configure everything. Done.

### Manual install

```bash
git clone https://github.com/philipbankier/codex-handoff.git
cd codex-handoff
bash install.sh
```

This creates symlinks into your agent's config directory. Updates are applied instantly with `git pull`.

Platform-specific:
```bash
bash install.sh --platform=claude-code    # Claude Code only
bash install.sh --platform=openclaw       # OpenClaw only
```

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [OpenClaw](https://github.com/openclaw) installed
- [Codex CLI](https://github.com/openai/codex) installed: `npm install -g @openai/codex`

### Verify / Uninstall

```bash
bash scripts/verify-install.sh            # check installation
bash uninstall.sh                         # remove
```

## Recommended Workflow

The simplest way to use codex-handoff:

**1. Brainstorm your idea** using [superpowers](https://github.com/obra/superpowers) `/brainstorming`:

> "I want to build a CLI tool that checks markdown files for broken links"

The brainstorming skill helps you explore the idea, identify requirements, and think through edge cases before writing any code.

**2. Write the plan** using `/writing-plans`:

> "Let's write the plan for this"

This produces a structured, numbered plan with clear items — exactly what Codex needs to execute.

**3. Hand it off** when the plan is ready:

> "Hand it off to codex"

Your agent locates the plan, sends it to Codex CLI, and supervises the execution. Codex writes the code, runs tests, and your agent reviews the results. If anything is incomplete, it automatically builds a correction prompt and loops — up to 5 iterations by default.

**4. Review and commit** the final output.

### Other ways to trigger

```
/codex-handoff                          # uses the most recent plan
/codex-handoff add auth to the API      # finds a relevant plan
/codex-handoff --max-iterations 3       # limit retry loops
/codex-handoff --model o4-mini          # specify Codex model
/codex-handoff --phase 2                # re-run only phase 2
```

## Compatibility

| Platform | Status | Skill | Slash Command | Install Path |
|----------|--------|-------|---------------|--------------|
| Claude Code | Full support | Yes | `/codex-handoff` | `~/.claude/` |
| OpenClaw | Skill only | Yes | Via description match | `~/.openclaw/` |
| Codex CLI | Required dependency | -- | -- | System-wide (`npm -g`) |

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `--max-iterations N` | `5` | Maximum supervisor loop iterations (per phase in phased mode) |
| `--model MODEL` | Codex default | Model for Codex CLI to use (e.g., `o4-mini`) |
| `--phase N` | All phases | Execute only phase N (for re-running a specific phase) |

## Examples

- **[Simple walkthrough](examples/simple/)** — A real captured transcript showing codex-handoff executing a 5-item plan in a single pass. Plan, Codex output, scorecard, and generated code included.

- **[Advanced: multi-phase plan](examples/advanced-momentum-trader/)** — A complex trading system with 7 separate plans demonstrating phased execution.

## How It Works Under the Hood

```
                   ┌─────────────────────────────────┐
                   │        Your AI Agent              │
                   │     (Supervisor / Judge)           │
                   └──────────┬──────────┬─────────────┘
                              │          ▲
                  1. Send     │          │  4. Review
                     plan     │          │     diff
                              ▼          │
                   ┌─────────────────────────────────┐
                   │          Codex CLI                │
                   │         (Executor)                │
                   └──────────┬──────────┬─────────────┘
                              │          ▲
                  2. Write    │          │  3. Run
                     code     │          │     tests
                              ▼          │
                   ┌─────────────────────────────────┐
                   │        Your Codebase              │
                   └───────────────────────────────────┘
```

### The Supervisor Loop

1. **Locate** — Agent finds your plan (from `docs/plans/`, `.claude/plans/`, or inline)
2. **Detect phases** — Scans for phase headings (`## Phase 1:`, `## Stage 1:`, `## Part 1:`, `## 1. ...`). If found, executes phase-by-phase. If not, runs as a single pass.
3. **Build prompt** — Constructs a structured prompt with plan + project context (package manager, test commands, coding standards from `CLAUDE.md`)
4. **Execute** — Runs `codex exec --full-auto -s workspace-write`
5. **Review** — Agent reviews the git diff, runs tests, audits plan completion with a scorecard (DONE / PARTIAL / MISSING)
6. **Decide** — If items remain and iterations are under the limit, builds a correction prompt and re-runs. In phased mode, advances to next phase when current phase passes.
7. **Report** — Presents final status with completed/remaining items and test results

### Phased Execution

For large plans with distinct phases, codex-handoff automatically detects phase headings and executes one phase at a time:

- Each phase gets a focused prompt (no wasted context on future phases)
- Dependencies between phases are respected
- Per-phase scorecards give clearer progress tracking
- Failed phases can be re-run individually with `--phase N`

Plans without phase headings run in single-pass mode.

### Plan Discovery

Plans are searched in order:
1. **Argument text** — matches against plan filenames and content
2. **`docs/plans/*.md`** — most recent file by date prefix
3. **`.claude/plans/*.md`** — any recent plan files

## Troubleshooting

### "command not found: codex"

```bash
npm install -g @openai/codex
codex --version
```

### Skill not showing up

```bash
bash scripts/verify-install.sh
```

If symlinks are broken, re-run `bash install.sh`.

### "No plan found"

Create a plan first. Plans are searched in `docs/plans/`, `.claude/plans/`, or can be provided inline. See [`resources/example-plan.md`](resources/example-plan.md) for the expected format.

### Codex produces incomplete results

This is expected — the supervisor loop handles it automatically. The agent reviews each iteration, builds correction prompts, and re-runs Codex up to `--max-iterations` times.

## Repo Structure

```
codex-handoff/
├── commands/codex-handoff.md              # Slash command definition
├── skills/codex-handoff/
│   ├── SKILL.md                           # Main skill instructions
│   └── references/
│       ├── prompt-templates.md            # Codex prompt construction
│       ├── review-process.md              # Review & scorecard logic
│       └── error-handling.md              # Error handling & troubleshooting
├── examples/
│   ├── simple/                            # Quick walkthrough (annotated transcript)
│   │   ├── README.md
│   │   ├── plan.md
│   │   └── output/                       # Actual code Codex produced
│   └── advanced-momentum-trader/          # Complex real-world example
│       ├── README.md
│       ├── design-spec.md
│       └── plan-phase1-foundation.md
├── resources/example-plan.md              # Example plan format
├── scripts/verify-install.sh              # Installation diagnostic
├── install.sh                             # Multi-platform installer
├── uninstall.sh                           # Multi-platform uninstaller
├── openclaw.yaml                          # OpenClaw manifest
├── CLAUDE.md                              # Repo conventions
├── CONTRIBUTING.md                        # Contribution guidelines
├── CODE_OF_CONDUCT.md                     # Contributor Covenant v2.1
├── CHANGELOG.md                           # Version history
└── LICENSE                                # MIT
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, guidelines, and PR process.

## License

[MIT](LICENSE)
