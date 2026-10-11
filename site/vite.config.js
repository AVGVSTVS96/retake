import { defineConfig } from "vite"

export default defineConfig({
  server: { fs: { allow: [".."] } },
  build: { outDir: "dist", emptyOutDir: true, assetsInlineLimit: 0 },
})
