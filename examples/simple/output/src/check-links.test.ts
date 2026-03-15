import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, test, vi } from "vitest";

import { checkLinks, extractLinks } from "./check-links.ts";

const originalFetch = globalThis.fetch;

async function writeMarkdown(contents: string): Promise<string> {
  const directory = await mkdtemp(join(tmpdir(), "link-checker-"));
  const filePath = join(directory, "README.md");

  await writeFile(filePath, contents, "utf8");

  return filePath;
}

afterEach(() => {
  globalThis.fetch = originalFetch;
  vi.restoreAllMocks();
});

describe("checkLinks", () => {
  test("extracts links from markdown string", () => {
    const markdown = [
      "[One](https://example.com)",
      "[Two](http://example.org/path)",
      "[Ignore](mailto:test@example.com)",
    ].join("\n");

    expect(extractLinks(markdown)).toEqual([
      "https://example.com",
      "http://example.org/path",
    ]);
  });

  test("identifies broken vs valid links", async () => {
    const filePath = await writeMarkdown([
      "[Good](https://good.example.com)",
      "[Bad](https://bad.example.com)",
      "[Error](https://error.example.com)",
    ].join("\n"));

    const fetchMock = vi.fn(async (input: string | URL | Request, init?: RequestInit) => {
      const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;

      if (url === "https://good.example.com") {
        return new Response(null, { status: 204 });
      }

      if (url === "https://bad.example.com") {
        return new Response(null, { status: 404 });
      }

      throw new Error("network error");
    });

    globalThis.fetch = fetchMock as typeof fetch;

    await expect(checkLinks(filePath)).resolves.toEqual([
      { url: "https://good.example.com", status: 204, ok: true },
      { url: "https://bad.example.com", status: 404, ok: false },
      { url: "https://error.example.com", status: 0, ok: false },
    ]);

    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock).toHaveBeenNthCalledWith(1, "https://good.example.com", { method: "HEAD" });
    expect(fetchMock).toHaveBeenNthCalledWith(2, "https://bad.example.com", { method: "HEAD" });
    expect(fetchMock).toHaveBeenNthCalledWith(3, "https://error.example.com", { method: "HEAD" });
  });

  test("returns empty array for markdown with no links", async () => {
    const filePath = await writeMarkdown("This file has no HTTP links.");
    const fetchMock = vi.fn();

    globalThis.fetch = fetchMock as typeof fetch;

    await expect(checkLinks(filePath)).resolves.toEqual([]);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
