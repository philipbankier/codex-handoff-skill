# codex-handoff

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)](CHANGELOG.md)
[![Claude Code](https://img.shields.io/badge/platform-Claude%20Code-blueviolet.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OpenClaw](https://img.shields.io/badge/platform-OpenClaw-orange.svg)](https://github.com/openclaw)

An AI agent skill that offloads coding plans to [Codex CLI](https://github.com/openai/codex) for execution, with your agent acting as supervisor and judge in an automated loop.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenClaw](https://github.com/openclaw) (formerly ClawdBot).

**Your agent plans. Codex CLI codes. Your agent reviews.**

## How It Works

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

### The Loop

1. **Locate** -- Agent finds your plan (from `docs/plans/`, `.claude/plans/`, or inline)
2. **Detect phases** -- Scans for phase headings (`## Phase 1:`, etc.). If found, executes phase-by-phase. If not, runs as a single pass.
3. **Build prompt** -- Constructs a structured prompt with plan (or current phase) + project context + coding standards
4. **Execute** -- Runs Codex CLI in `--full-auto` mode
5. **Review** -- Agent reviews the git diff, runs tests, audits plan completion with a scorecard
6. **Decide** -- If items remain and iterations are under the limit, builds a correction prompt and loops back to step 4. In phased mode, advances to next phase when current phase passes.
7. **Report** -- Presents final status with completed/remaining items and test results

Default max iterations: **5** (per phase in phased mode)

## Compatibility

| Platform | Status | Skill | Slash Command | Install Path |
|----------|--------|-------|---------------|--------------|
| Claude Code | Full support | Yes | `/codex-handoff` | `~/.claude/` |
| OpenClaw | Skill only | Yes | Via description match | `~/.openclaw/` |
| Codex CLI | Required dependency | -- | -- | System-wide (`npm -g`) |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or [OpenClaw](https://github.com/openclaw) installed
- [Codex CLI](https://github.com/openai/codex) installed: `npm install -g @openai/codex`

## Install

```bash
git clone https://github.com/philipbankier/codex-handoff.git
cd codex-handoff
bash install.sh
```

This creates symlinks into your agent's config directory. Updates are applied instantly with `git pull`.

### Platform-specific install

```bash
bash install.sh --platform=claude-code    # Claude Code only
bash install.sh --platform=openclaw       # OpenClaw only
bash install.sh --platform=all            # both platforms
```

With no flag, the script auto-detects which platforms are installed.

### Verify installation

```bash
bash scripts/verify-install.sh
```

## Uninstall

```bash
bash uninstall.sh                         # auto-detect and remove
bash uninstall.sh --platform=claude-code  # remove from Claude Code only
bash uninstall.sh --platform=openclaw     # remove from OpenClaw only
```

## Usage

### Claude Code

```
/codex-handoff                          # uses the most recent plan
/codex-handoff add auth to the API      # finds/uses a relevant plan
/codex-handoff --max-iterations 3       # limit retry loops
/codex-handoff --model o4-mini          # specify Codex model
/codex-handoff --phase 2                # re-run only phase 2
```

### Conversational triggers (both platforms)

- "hand off to codex"
- "let codex do it"
- "offload to codex"

### Typical Workflow

1. Plan your feature (e.g., with `/brainstorming` then `/writing-plans`)
2. Run `/codex-handoff` to execute the plan
3. Agent sends the plan to Codex, reviews results, and loops until done
4. Review the final report and commit

See [`resources/example-plan.md`](resources/example-plan.md) for the expected plan format.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `--max-iterations N` | `5` | Maximum supervisor loop iterations (per phase in phased mode) |
| `--model MODEL` | Codex default | Model for Codex CLI to use (e.g., `o4-mini`) |
| `--phase N` | All phases | Execute only phase N (for re-running a specific phase) |

## Phased Execution

For large plans with distinct phases, codex-handoff automatically detects phase headings and executes one phase at a time. This is fully dynamic -- no configuration needed.

**Auto-detected phase headings:**
- `## Phase 1: Backend`, `## Phase 2: Frontend`
- `## Stage 1: Setup`, `## Stage 2: Implementation`
- `## Part 1: Core`, `## Part 2: Extensions`
- `## 1. Backend`, `## 2. Frontend`

**Why phased execution?**
- Each phase gets a focused prompt (no wasted context on future phases)
- Dependencies between phases are respected (Phase 2 runs after Phase 1's files exist)
- Per-phase scorecards give clearer progress tracking
- Failed phases can be re-run individually with `--phase N`

Plans without phase headings run in single-pass mode, exactly as before.

## Examples

### Quick Walkthrough
See [`examples/simple/`](examples/simple/) for a complete annotated transcript
showing every step of the codex-handoff loop on a small project.

### Advanced: Multi-Phase Plan
See [`examples/advanced-momentum-trader/`](examples/advanced-momentum-trader/)
for a real-world multi-phase plan demonstrating phased execution on a
complex trading system.

## How It Finds Your Plan

Searched in order:

1. **Argument text** -- matches against plan filenames and content
2. **`docs/plans/*.md`** -- most recent file by date prefix (e.g., `2026-03-10-auth-plan.md`)
3. **`.claude/plans/*.md`** -- any recent plan files

If no plan is found, you'll be prompted to create one first.

## Project Context

The handoff prompt automatically includes:
- **Package manager** -- detected from lockfile (npm/yarn/pnpm/bun)
- **Test & build commands** -- from `package.json` scripts
- **Coding standards** -- from `CLAUDE.md` or `.codex/AGENTS.md` if present

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
├── CHANGELOG.md                           # Version history
└── LICENSE                                # MIT
```

## Troubleshooting

### "command not found: codex"

Codex CLI is not installed or not in PATH:
```bash
npm install -g @openai/codex
codex --version
```

### Skill not showing up in my agent

Run the verification script to check symlinks:
```bash
bash scripts/verify-install.sh
```

If symlinks are broken, re-run `bash install.sh`. If existing regular files block installation, back them up and remove them first.

### "No plan found"

Create a plan first. Plans are searched in `docs/plans/`, `.claude/plans/`, or can be provided inline with the command. See [`resources/example-plan.md`](resources/example-plan.md) for the expected format.

### Codex produces incomplete results

This is expected -- the supervisor loop handles it automatically. The agent reviews each iteration, builds correction prompts, and re-runs Codex up to `--max-iterations` times.

## Contributing

1. Fork the repo
2. Make changes (edits to skill files take effect immediately via symlinks)
3. Test with `bash install.sh && bash scripts/verify-install.sh`
4. Submit a PR

Keep `SKILL.md` under 5KB. Extract detailed content to `references/`.

## License

[MIT](LICENSE)
