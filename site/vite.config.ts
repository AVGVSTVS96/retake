import { defineConfig } from "vite";

export default defineConfig({
  build: { assetsInlineLimit: 0, emptyOutDir: true, outDir: "dist" },
  server: { fs: { allow: [".."] } },
});
