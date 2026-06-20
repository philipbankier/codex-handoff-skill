# codex-handoff 1.2.0 Design

## Purpose

Release `1.2.0` updates codex-handoff from a Claude Code only supervisor workflow into a dual-surface agent handoff package.

The stable path remains Claude Code supervising Codex CLI execution of an existing plan. The new experimental path adds Codex-native direct execution through a Codex plugin and skill. Direct Codex mode can act autonomously for routine scoped work, but must escalate when strategic assumptions change.

## Approved Direction

Use the recommended approach:

- Keep the Claude Code supervisor workflow as the stable path.
- Add an experimental Codex-native direct execution path.
- Package the Codex path as a Codex plugin with its own direct skill.
- Add a first-class escalation contract.
- Add release verification and a small skill eval fixture.
- Keep Grok, GLM, MCP, hooks, cloud marketplace publishing, and Claude plugin packaging out of `1.2.0`.

## Product Surfaces

| Surface      | Status in 1.2.0 | Role                                                        |
|--------------|-----------------|-------------------------------------------------------------|
| Claude Code  | Stable          | Supervisor and judge that invokes Codex CLI as executor     |
| OpenClaw     | Existing        | Skill install path remains supported, but not expanded      |
| Codex plugin | Experimental    | Direct Codex execution with strict escalation criteria      |
| Grok / GLM   | Out of scope    | Mention only as future gated model lanes after preflight    |

## Codex Plugin Shape

The Codex path must not reuse the Claude supervisor skill as-is. The Claude skill tells the supervisor to call `codex exec`; if Codex loaded that directly, the workflow would be recursive.

Add a separate Codex direct skill:

```text
codex-handoff/
|- skills/codex-handoff/
|- commands/codex-handoff.md
|- plugins/
|  `- codex-handoff-codex/
|     |- .codex-plugin/
|     |  `- plugin.json
|     `- skills/
|        `- codex-handoff-direct/
|           |- SKILL.md
|           |- agents/
|           |  `- openai.yaml
|           `- references/
|              |- execution-contract.md
|              |- escalation-policy.md
|              |- review-process.md
|              `- verification.md
|- .agents/
|  `- plugins/
|     `- marketplace.json
|- openclaw.yaml
|- install.sh
|- uninstall.sh
|- scripts/
|  |- verify-install.sh
|  `- verify-release.sh
|- evals/
|  `- evals.json
|- README.md
`- CHANGELOG.md
```

The Codex direct skill must say that Codex is the executor. It must not invoke `codex`, `claude`, Grok, GLM, or another model lane as the executor unless a local preflight proves that lane exists and the user explicitly asked for it.

## Direct Codex Execution

Direct Codex mode should run without hand-holding when the task is routine and scoped.

Execution flow:

1. Locate or accept a plan.
2. Classify readiness: `ready`, `needs clarification`, `needs split`, or `unsafe to run`.
3. Capture baseline: branch, dirty files, allowed scope, plan path, and phase.
4. Build an execution contract.
5. Execute inside Codex's configured sandbox.
6. Run checks using Scripts to Rule Them All first, then repo docs and package files.
7. Review diff, verification evidence, skipped checks, and unplanned changes.
8. Loop with a correction contract only when remaining work is mechanical and still in scope.
9. Finish with evidence or stop with escalation.

## Escalation Contract

Direct Codex mode may continue autonomously only while the plan, allowed scope, sandbox, and verification path remain valid.

Escalate when any of these are true:

- The plan's core assumption is false.
- Requirements conflict with repo or user instructions.
- The task expands outside allowed scope.
- Public API, data model, auth, billing, permissions, migrations, or external integration choices appear and were not named in the plan.
- Secrets, credentials, production data, or external auth are needed.
- Destructive or irreversible changes are needed.
- Verification cannot prove the done condition.
- Codex would need to substitute weaker evidence.
- Multiple plausible architecture or product choices exist.
- The same failure repeats after one scoped correction and the next step is not purely mechanical.
- Unplanned diffs appear, especially generated files, deleted files, lockfile churn, config changes, or edits to pre-existing dirty files.
- A requested model or tool lane is unavailable.
- Direct Codex would need to alter release scope.

Escalation report format:

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

The escalation should not ask an open-ended question. It should present facts, options, and a recommended default action.

## Verification And Release Evidence

Add `scripts/verify-release.sh`. It should stay POSIX shell and avoid package dependencies.

It should check:

- `skills/codex-handoff/SKILL.md` is under 5KB.
- `commands/codex-handoff.md` is under 15 lines.
- Markdown files in `skills/` and `commands/` have YAML frontmatter.
- Shell scripts pass `bash -n`.
- Stable stale terms are absent where they should be absent: `full-auto`, `o4-mini`, `npm install -g`, `CODEX_COMPLETE`, `PHASE_COMPLETE`.
- Version is consistent across `SKILL.md`, README badge, `openclaw.yaml`, Codex plugin manifest, and `CHANGELOG.md`.
- Codex plugin files exist.
- `evals/evals.json` exists and is valid JSON.
- Changed files do not include obvious secrets.

Add `docs/releases/1.2.0-verification.md` during the release work. It should record exact commands, exit codes, skipped checks, and known limitations.

## Skill Evals

Add a small fixture at `evals/evals.json`. This is not a full harness.

Include cases for:

- should trigger on a ready plan handoff
- should not trigger on casual Codex discussion
- ambiguous plan requires clarification
- broad plan requires split
- unsafe plan escalates
- phased plan is recognized
- missing verification commands produce unverified status
- direct Codex path escalates on strategic uncertainty
- stale model override requires preflight

## Documentation Changes

README should explain two install paths:

- Stable Claude Code and OpenClaw symlink install.
- Experimental Codex plugin install.

README should also label Codex-native direct execution as experimental and clarify that it is autonomous for routine scoped work, not strategic decision-making.

CHANGELOG should add a `1.2.0` entry that calls out:

- refreshed stable Claude supervisor workflow
- experimental Codex-native direct execution plugin
- escalation policy
- release verification script
- skill eval fixture
- version and example cleanup

## Out Of Scope

Do not add these in `1.2.0`:

- Claude plugin packaging
- public marketplace publishing
- Grok or GLM worker routing
- MCP servers
- hooks
- app code
- `package.json`
- cloud deployment
- automated release publishing

## Risks

The main risk is confusing the two execution models. The Claude path supervises Codex CLI. The Codex path is Codex executing directly. Their instructions must be separate.

The second risk is overclaiming model support. Grok and GLM should not appear as runtime claims unless local preflight proves them.

The third risk is release drift. Version, examples, README, manifests, and changelog must agree before release.

## Acceptance Criteria

`1.2.0` is ready when:

- Stable install verification passes.
- Release verification script passes.
- Codex plugin manifest and marketplace metadata exist.
- Codex direct skill exists and forbids recursive executor calls.
- Escalation policy is first-class in direct path references.
- Eval fixture exists and covers the listed cases.
- README separates stable and experimental paths.
- CHANGELOG includes `1.2.0`.
- Examples no longer teach stale or unsafe defaults.
- No secrets appear in staged changes.

## Sources

- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/plugins/build
- https://developers.openai.com/codex/learn/best-practices
- https://developers.openai.com/codex/subagents
- https://developers.openai.com/codex/guides/agents-md
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/sub-agents
- https://github.com/github/scripts-to-rule-them-all
