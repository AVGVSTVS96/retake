import { defineConfig } from "oxlint";
import antiSlop from "ultracite/oxlint/anti-slop";
import core from "ultracite/oxlint/core";

export default defineConfig({
  extends: [core, antiSlop],
  ignorePatterns: [...(core.ignorePatterns ?? []), "reference/**", "parity/**"],
  jsPlugins: [{ name: "no-comments", specifier: "./tools/oxlint/no-comments.ts" }],
  options: { typeAware: true },
  rules: {
    "import/no-cycle": "error",
    "no-comments/no-comments": "error",
    "oxc/no-accumulating-spread": "error",
  },
});
