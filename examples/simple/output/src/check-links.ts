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

        return {
          url,
          status: response.status,
          ok,
        };
      } catch {
        return {
          url,
          status: 0,
          ok: false,
        };
      }
    }),
  );
}
