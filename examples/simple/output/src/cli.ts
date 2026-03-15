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
