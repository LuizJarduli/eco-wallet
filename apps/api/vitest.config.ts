import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    exclude: ["dist/**", "node_modules/**"],
    coverage: {
      all: true,
      exclude: [
        "src/index.ts",
        "src/core/config/env.ts",
        "src/core/logger/**/*.ts",
        "src/core/supabase/**/*.ts",
        "src/test/**/*.ts"
      ],
      include: ["src/**/*.ts"],
      provider: "v8",
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80
      }
    },
    environment: "node"
  }
});
