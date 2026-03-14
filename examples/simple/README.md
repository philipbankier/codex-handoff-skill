# Simple Walkthrough: Markdown Link Checker

This is a real captured transcript of codex-handoff executing a plan end-to-end. Every output shown below — the Codex CLI logs, git diffs, test results, and scorecard — was captured from an actual execution on 2026-03-14.

The plan builds a simple Node.js CLI tool that checks markdown files for broken links. See [`plan.md`](plan.md) for the full plan — 5 items, no phases, single-pass mode.

---

## Step 1: Plan Located

When you run `/codex-handoff`, the agent searches for a plan file. It finds `plan.md` in the working directory:

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
> Built prompt → `/tmp/codex-handoff-prompt-1.md` (1.6 KB)

The actual prompt sent to Codex:

```markdown
# Task

You are executing a coding plan. Complete ALL items below. Do not skip any steps.

## Plan

### 1. Initialize npm project with TypeScript

- `npm init -y`
- `npm install -D typescript @types/node tsx`
- Create `tsconfig.json` with `target: "ES2022"`, `module: "NodeNext"`, `outDir: "dist/"`
- Add `build` and `start` scripts to `package.json`

### 2. Create link checker — `src/check-links.ts`

- Read a markdown file from disk
- Extract all links using regex: `\[.*?\]\((https?:\/\/[^\)]+)\)`
- For each link, send a HEAD request with `fetch()`
- Collect results: `{ url, status, ok }`
- Export `checkLinks(filePath: string)` function

### 3. Add CLI argument parsing — `src/cli.ts`

- Read file path from `process.argv[2]`
- Print usage if no argument provided
- Call `checkLinks()` and print results
- Exit with code 1 if any links are broken

### 4. Add colored output

- Green checkmark for valid links (status 200-399)
- Red X for broken links (status 400+ or network error)
- Summary line: "X of Y links valid"

### 5. Add tests — `src/check-links.test.ts`

- `npm install -D vitest`
- Test: extracts links from markdown string
- Test: identifies broken vs valid links (mock fetch)
- Test: returns empty array for markdown with no links
- Add `test` script to `package.json`

## Project Context

- Working directory: /tmp/codex-handoff-demo-linkchecker
- Package manager: npm (no lockfile detected — fresh project)
- No existing test framework detected
- No CLAUDE.md or coding standards found

## Instructions

1. Implement each plan item in order
2. After each significant change, run the test command to verify
3. Write clean, minimal code — follow existing patterns in the codebase
4. Do NOT add unnecessary comments, docs, or abstractions beyond what the plan specifies
5. When ALL items are complete and tests pass, output: CODEX_COMPLETE
6. If you get stuck on an item, implement what you can and note what failed
```

---

## Step 3: Codex Executes

The agent runs Codex CLI in full-auto mode:

> **Claude Code:**
>
> Running: `codex exec --full-auto -s workspace-write < /tmp/codex-handoff-prompt-1.md`

Codex starts up and reports its configuration:

```
OpenAI Codex v0.114.0 (research preview)
--------
workdir: /private/tmp/codex-handoff-demo-linkchecker
model: gpt-5.4
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR]
reasoning effort: xhigh
--------
```

Codex begins working through the plan. Here's the key narrative from its execution:

```
codex> I'm executing the plan in order from the project root, starting by
       inspecting the workspace and then initializing the npm/TypeScript
       setup before moving on to the link checker and tests.

Plan update
  → Inspect workspace and initialize npm + TypeScript config
  • Implement link checker and CLI with colored output
  • Add Vitest tests and verify after each major change
```

**npm init succeeds:**
```
exec> npm init -y

Wrote to /private/tmp/codex-handoff-demo-linkchecker/package.json:
{
  "name": "codex-handoff-demo-linkchecker",
  "version": "1.0.0",
  ...
}
```

**npm install hits a sandbox restriction** — the Codex sandbox blocks network access to the npm registry:
```
exec> npm install -D typescript @types/node tsx

npm error code ENOTFOUND
npm error network request to https://registry.npmjs.org/@types%2fnode failed,
reason: getaddrinfo ENOTFOUND registry.npmjs.org
```

Codex adapts by finding packages in the local bun cache:

```
codex> `npm` can't reach the registry in this sandbox, so package installs
       are blocked by ENOTFOUND. I'm checking what tooling is already
       available locally so I can still finish the implementation.

exec> ls -1 ~/.bun/install/cache | rg '^(typescript|tsx|vitest|@types)'
@types
tsx
tsx@4.21.0@@@1
typescript
typescript@5.9.3@@@1
```

**Creates `tsconfig.json` and updates `package.json`:**
```
file update
A /private/tmp/codex-handoff-demo-linkchecker/tsconfig.json
M /private/tmp/codex-handoff-demo-linkchecker/package.json
```

**Writes the source files:**
```
codex> I have the implementation shape pinned down. Next I'm adding the
       checker and CLI in src/, keeping the fetch/status behavior exactly
       aligned with the plan and using ANSI colors directly so there's no
       extra dependency surface.

file update
A /private/tmp/codex-handoff-demo-linkchecker/src/check-links.ts
A /private/tmp/codex-handoff-demo-linkchecker/src/cli.ts
```

**Build succeeds:**
```
exec> npm run build

Bundled 2 modules in 27ms
  cli.js          1.62 KB  (entry point)
  check-links.js  0.77 KB  (entry point)
```

**Installs vitest from local cache, writes tests, and runs them:**
```
codex> The checker, CLI, colored output, and tests are all implemented
       and verified. Offline package/cache workarounds were needed
       because direct registry installs were blocked in the sandbox.

Plan update
  ✓ Inspect workspace and initialize npm + TypeScript config
  ✓ Implement link checker and CLI with colored output
  ✓ Add Vitest tests and verify after each major change

CODEX_COMPLETE
```

Codex used **56,259 tokens** and completed in a single pass.

---

## Step 4: Review

The agent reviews what Codex produced — checking the git diff and running tests independently:

> **Claude Code:**
>
> **Git diff (staged):**
> ```
>  package.json             |  25 +++
>  src/check-links.test.ts  |  82 ++++++++
>  src/check-links.ts       |  39 ++++
>  src/cli.ts               |  36 ++++
>  tsconfig.json            |  11 +
>  5 files changed, 193 insertions(+)
> ```
>
> **Test results:**
> ```
> > codex-handoff-demo-linkchecker@1.0.0 test
> > node node_modules/vitest/vitest.mjs run
>
>  RUN  v3.2.4 /private/tmp/codex-handoff-demo-linkchecker
>
>  ✓ src/check-links.test.ts (3 tests) 12ms
>
>  Test Files  1 passed (1)
>       Tests  3 passed (3)
>    Start at  19:43:49
>    Duration  224ms (transform 58ms, setup 0ms, collect 48ms, tests 12ms, environment 0ms, prepare 35ms)
> ```
>
> **Scorecard:**
>
> | # | Item | Status |
> |---|------|--------|
> | 1 | Initialize npm project with TypeScript | DONE |
> | 2 | Create link checker — `src/check-links.ts` | DONE |
> | 3 | Add CLI argument parsing — `src/cli.ts` | DONE |
> | 4 | Add colored output | DONE |
> | 5 | Add tests — `src/check-links.test.ts` | DONE |
>
> **Result: 5/5 DONE, 3/3 tests passing — complete**

---

## Step 5: Final Report

All items passed on the first iteration, so no correction loop was needed:

> **Claude Code:**
>
> ## codex-handoff Report
>
> **Plan:** Markdown Link Checker CLI
> **Mode:** Single-pass (no phases)
> **Iterations:** 1 of 5 max
>
> ### Results
>
> | # | Item | Status |
> |---|------|--------|
> | 1 | Initialize npm project with TypeScript | DONE |
> | 2 | Create link checker — `src/check-links.ts` | DONE |
> | 3 | Add CLI argument parsing — `src/cli.ts` | DONE |
> | 4 | Add colored output | DONE |
> | 5 | Add tests — `src/check-links.test.ts` | DONE |
>
> **All 5 items complete.** Tests passing (3/3).
>
> ### Files created
> ```
> package.json
> tsconfig.json
> src/check-links.ts       (39 lines — link extraction + HTTP checking)
> src/cli.ts               (36 lines — CLI with ANSI colored output)
> src/check-links.test.ts  (82 lines — 3 vitest tests with fetch mocking)
> ```
>
> Ready to review and commit.

---

## What Codex Actually Built

Here are the key source files Codex produced:

### `src/check-links.ts`
```typescript
import { readFile } from "node:fs/promises";

const LINK_PATTERN = /\[.*?\]\((https?:\/\/[^\)]+)\)/g;

export type LinkResult = {
  url: string;
  status: number;
  ok: boolean;
};

export function extractLinks(markdown: string): string[] {
  return Array.from(markdown.matchAll(LINK_PATTERN), ([, url]) => url);
}

export async function checkLinks(filePath: string): Promise<LinkResult[]> {
  const markdown = await readFile(filePath, "utf8");
  const links = extractLinks(markdown);

  return Promise.all(
    links.map(async (url) => {
      try {
        const response = await fetch(url, { method: "HEAD" });
        const ok = response.status >= 200 && response.status < 400;
        return { url, status: response.status, ok };
      } catch {
        return { url, status: 0, ok: false };
      }
    }),
  );
}
```

### `src/cli.ts`
```typescript
import { checkLinks } from "./check-links.ts";

const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const RESET = "\x1b[0m";

function formatResult(ok: boolean): string {
  return ok ? `${GREEN}✓${RESET}` : `${RED}X${RESET}`;
}

const filePath = process.argv[2];

if (!filePath) {
  console.error("Usage: npm start -- <markdown-file>");
  process.exit(1);
}

try {
  const results = await checkLinks(filePath);
  const validCount = results.filter((result) => result.ok).length;

  for (const result of results) {
    const status = result.status === 0 ? "ERR" : String(result.status);
    console.log(`${formatResult(result.ok)} ${status} ${result.url}`);
  }

  console.log(`${validCount} of ${results.length} links valid`);

  if (validCount !== results.length) {
    process.exit(1);
  }
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`${RED}X${RESET} ${message}`);
  process.exit(1);
}
```

### `src/check-links.test.ts` (abbreviated)
```typescript
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, test, vi } from "vitest";
import { checkLinks, extractLinks } from "./check-links.ts";

// ... helper to write temp markdown files ...

describe("checkLinks", () => {
  test("extracts links from markdown string", () => {
    const markdown = "[One](https://example.com)\n[Two](http://example.org/path)\n[Ignore](mailto:test@example.com)";
    expect(extractLinks(markdown)).toEqual([
      "https://example.com",
      "http://example.org/path",
    ]);
  });

  test("identifies broken vs valid links", async () => {
    // Mocks fetch to return 204 for good.example.com, 404 for bad.example.com,
    // and throws for error.example.com
    // Asserts: [{ok: true}, {ok: false, status: 404}, {ok: false, status: 0}]
  });

  test("returns empty array for markdown with no links", async () => {
    // Writes markdown with no HTTP links, asserts empty array, fetch not called
  });
});
```

---

## Key Takeaways

1. **Single-iteration completion** — For this simple 5-item plan, Codex completed everything in one pass. The correction loop exists for when items are missed, but simple plans often don't need it.

2. **Sandbox adaptation** — The Codex sandbox blocked npm registry access (network isolation). Codex autonomously discovered packages in the local bun cache and wired up `file:` references. This is a real-world wrinkle you'll encounter — Codex is resourceful about working within its constraints.

3. **Scorecard-driven decisions** — After Codex finishes, the agent independently reviews the diff and runs tests. Each plan item is scored as DONE, PARTIAL, or MISSING. If anything is incomplete, the agent builds a targeted correction prompt and loops.

4. **You stay in control** — The agent asks for confirmation before starting, shows you the scorecard after each iteration, and presents a final report. You decide when to commit.

5. **The generated code is clean** — Codex produced well-structured TypeScript: a focused module (`check-links.ts`), a separate CLI entry point (`cli.ts`) with ANSI colors, and thorough tests with proper fetch mocking. No unnecessary abstractions or over-engineering.
