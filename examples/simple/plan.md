# Plan: Markdown Link Checker CLI

A simple Node.js CLI tool that reads a markdown file, extracts all links, and checks whether they're valid.

**Tech Stack:** Node.js, TypeScript, node-fetch

---

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
