import type { NextConfig } from "next";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const projectDir = path.dirname(fileURLToPath(import.meta.url));

/** Load apps/web/.env* when Turbopack root is the monorepo (Next would otherwise skip them). */
const loadWebAppEnv = (dir: string): void => {
  for (const file of [".env.local", ".env"]) {
    const filePath = path.join(dir, file);

    if (!fs.existsSync(filePath)) {
      continue;
    }

    for (const line of fs.readFileSync(filePath, "utf8").split("\n")) {
      const trimmed = line.trim();

      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separator = trimmed.indexOf("=");

      if (separator === -1) {
        continue;
      }

      const key = trimmed.slice(0, separator).trim();
      const rawValue = trimmed.slice(separator + 1).trim();
      const value = rawValue.replace(/^["']|["']$/g, "");

      if (process.env[key] === undefined) {
        process.env[key] = value;
      }
    }
  }
};

loadWebAppEnv(projectDir);

const nextConfig: NextConfig = {
  turbopack: {
    root: path.join(projectDir, "../..")
  }
};

export default nextConfig;
