# Simple Walkthrough: Markdown Link Checker

This is a complete annotated transcript showing every step of the codex-handoff loop on a small project. It demonstrates the full supervisor cycle: plan discovery, prompt construction, Codex execution, review, correction loop, and final report.

> **Note:** The agent outputs below are simulated to illustrate the flow. In a real session, these would be generated live by Claude Code and Codex CLI.

---

## The Plan

The plan builds a simple Node.js CLI tool that checks markdown files for broken links. See [`plan.md`](plan.md) for the full plan — 5 items, no phases, single-pass mode.

---

## Step 1: Plan Located

When you run `/codex-handoff`, the agent searches for a plan file. Here it finds `plan.md`:

> **Claude Code:**
>
> Found plan: `plan.md` — **Markdown Link Checker CLI**
>
> **5 items detected** (no phase headings → single-pass mode):
> 1. Initialize npm project with TypeScript
> 2. Create link checker — `src/check-links.ts`
> 3. Add CLI argument parsing — `src/cli.ts`
> 4. Add colored output
> 5. Add tests — `src/check-links.test.ts`
>
> Ready to hand off to Codex CLI. Proceed?

You confirm, and the loop begins.

---

## Step 2: Prompt Built

The agent constructs a structured prompt combining the plan with project context, then writes it to a temp file:

> **Claude Code:**
>
> Built prompt → `/tmp/codex-handoff-a1b2c3.md` (1.2 KB)

The prompt sent to Codex looks like this (abbreviated):

```markdown
# Task

Implement the following plan in the current directory.

## Plan: Markdown Link Checker CLI

### 1. Initialize npm project with TypeScript
- npm init -y
- npm install -D typescript @types/node tsx
- Create tsconfig.json with target: "ES2022", module: "NodeNext", outDir: "dist/"
- Add build and start scripts to package.json

### 2. Create link checker — src/check-links.ts
[... full plan items ...]

## Project Context
- Package manager: npm
- No existing test framework detected
- No CLAUDE.md found

## Instructions
- Implement ALL items above
- Run tests after implementation
- Do not skip any items
```

---

## Step 3: Codex Executes (Iteration 1)

The agent runs Codex CLI in full-auto mode:

> **Claude Code:**
>
> Running: `codex --approval-mode full-auto --quiet < /tmp/codex-handoff-a1b2c3.md`

Codex works for about 90 seconds. Its output:

> **Codex CLI:**
>
> ```
> ✓ Created package.json
> ✓ Installed typescript, @types/node, tsx
> ✓ Created tsconfig.json
> ✓ Created src/check-links.ts
> ✓ Created src/cli.ts
> ✓ Installed vitest
> ✓ Created src/check-links.test.ts
>
> Running tests...
> ✓ extracts links from markdown string
> ✓ returns empty array for markdown with no links
> ✗ identifies broken vs valid links — AssertionError: expected 2 but got 0
>
> 2 passed, 1 failed
> ```

---

## Step 4: Review

The agent reviews what Codex produced — checking the git diff, test results, and scoring each plan item:

> **Claude Code:**
>
> ### Git diff summary
> ```
>  6 files changed, 187 insertions(+)
>  create mode 100644 package.json
>  create mode 100644 tsconfig.json
>  create mode 100644 src/check-links.ts
>  create mode 100644 src/cli.ts
>  create mode 100644 src/check-links.test.ts
>  create mode 100644 package-lock.json
> ```
>
> ### Test results
> ```
> Tests:  2 passed, 1 failed
> ```
>
> ### Scorecard
>
> | # | Item | Status |
> |---|------|--------|
> | 1 | Initialize npm project with TypeScript | ✅ DONE |
> | 2 | Create link checker — `src/check-links.ts` | ✅ DONE |
> | 3 | Add CLI argument parsing — `src/cli.ts` | ✅ DONE |
> | 4 | Add colored output | ❌ MISSING — no color codes in cli.ts output |
> | 5 | Add tests — `src/check-links.test.ts` | ⚠️ PARTIAL — 1 of 3 tests failing |
>
> **Result: 3/5 DONE, 1 PARTIAL, 1 MISSING → looping**

---

## Step 5: Decision — Loop

The agent decides to loop because items remain incomplete. It builds a targeted correction prompt:

> **Claude Code:**
>
> 2 items need work. Building correction prompt...
>
> Built correction prompt → `/tmp/codex-handoff-d4e5f6.md`

The correction prompt focuses only on what's missing:

```markdown
# Correction — Iteration 2

The following items from the plan are incomplete. Fix them.

## MISSING: Item 4 — Add colored output
- cli.ts currently prints plain text
- Add green checkmark (✓) for valid links (status 200-399)
- Add red X (✗) for broken links (status 400+ or network error)
- Add summary line: "X of Y links valid"
- Use ANSI escape codes (no dependencies needed)

## PARTIAL: Item 5 — Tests
- The test "identifies broken vs valid links" is failing
- The mock fetch setup appears incorrect — review and fix
- Ensure all 3 tests pass

## Context
- Existing files: src/check-links.ts, src/cli.ts, src/check-links.test.ts
- Run `npx vitest run` after fixes to verify
```

---

## Step 6: Codex Executes (Iteration 2)

> **Claude Code:**
>
> Running: `codex --approval-mode full-auto --quiet < /tmp/codex-handoff-d4e5f6.md`

> **Codex CLI:**
>
> ```
> ✓ Updated src/cli.ts — added ANSI color codes
> ✓ Updated src/check-links.test.ts — fixed mock fetch setup
>
> Running tests...
> ✓ extracts links from markdown string
> ✓ identifies broken vs valid links
> ✓ returns empty array for markdown with no links
>
> 3 passed, 0 failed
> ```

---

## Step 7: Final Review

> **Claude Code:**
>
> ### Git diff summary (cumulative)
> ```
>  6 files changed, 203 insertions(+)
> ```
>
> ### Test results
> ```
> Tests:  3 passed, 0 failed
> ```
>
> ### Final Scorecard
>
> | # | Item | Status |
> |---|------|--------|
> | 1 | Initialize npm project with TypeScript | ✅ DONE |
> | 2 | Create link checker — `src/check-links.ts` | ✅ DONE |
> | 3 | Add CLI argument parsing — `src/cli.ts` | ✅ DONE |
> | 4 | Add colored output | ✅ DONE |
> | 5 | Add tests — `src/check-links.test.ts` | ✅ DONE |
>
> **Result: 5/5 DONE — all items complete**

---

## Step 8: Final Report

This is what you see at the end of the session:

> **Claude Code:**
>
> ---
>
> ## codex-handoff Report
>
> **Plan:** Markdown Link Checker CLI
> **Mode:** Single-pass (no phases)
> **Iterations:** 2 of 5 max
>
> ### Results
>
> | # | Item | Status |
> |---|------|--------|
> | 1 | Initialize npm project with TypeScript | ✅ |
> | 2 | Create link checker — `src/check-links.ts` | ✅ |
> | 3 | Add CLI argument parsing — `src/cli.ts` | ✅ |
> | 4 | Add colored output | ✅ |
> | 5 | Add tests — `src/check-links.test.ts` | ✅ |
>
> **All 5 items complete.** Tests passing (3/3).
>
> ### Files created
> ```
> package.json
> tsconfig.json
> src/check-links.ts
> src/cli.ts
> src/check-links.test.ts
> ```
>
> Ready to review and commit.
>
> ---

---

## Key Takeaways

1. **Automatic looping** — Codex missed colored output and had a test bug. The agent detected both, built a focused correction prompt, and Codex fixed them on iteration 2.

2. **Scorecard-driven decisions** — The agent doesn't guess whether things are done. It scores each plan item as DONE, PARTIAL, or MISSING and loops until all are DONE (or max iterations hit).

3. **Focused corrections** — Iteration 2's prompt only mentions the 2 incomplete items, not the entire plan. This keeps Codex focused and avoids re-doing completed work.

4. **You stay in control** — The agent asks for confirmation before starting, shows you the scorecard after each iteration, and presents a final report. You decide when to commit.
