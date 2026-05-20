import react from "@vitejs/plugin-react";
import path from "node:path";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src")
    }
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./src/test/setup.ts"],
    coverage: {
      provider: "v8",
      include: [
        "src/core/lib/admin-api.ts",
        "src/core/ui/**/*.{ts,tsx}",
        "src/features/**/components/**/*.{ts,tsx}",
        "src/features/**/services/**/*.ts"
      ],
      exclude: [
        "src/**/*.d.ts",
        "src/**/__tests__/**",
        "src/features/admin-auth/components/**",
        "src/features/**/components/verification-queue.tsx",
        "src/features/**/components/audit-queue.tsx",
        "src/features/**/components/submission-card.tsx",
        "src/features/**/*-page.tsx"
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80
      }
    }
  }
});
