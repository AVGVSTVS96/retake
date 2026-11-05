import { execSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const repo = new URL("..", import.meta.url).pathname;

const sh = (cmd: string) =>
  execSync(cmd, { cwd: repo, encoding: "utf-8", shell: "/bin/bash" }).trim();

const lines = (dir: string) => Number(sh(`fd -e swift . ${dir} -X cat | wc -l`));

const count = (pattern: string, dir: string) =>
  Number(sh(`rg -c '${pattern}' ${dir} | awk -F: '{s+=$NF} END {print s}'`));

const cycles = Number(
  sh(
    String.raw`rg -o 'for cycle in 0\.\.<\d+' -N --no-filename Packages/MemoKit/Tests | rg -o '\d+$'`,
  ),
);

const facts = {
  counted: new Date().toISOString().slice(0, 10),
  engineLines: lines("Packages/MemoKit/Sources"),
  engineTests: count("@Test", "Packages/MemoKit/Tests"),
  hammerCycles: cycles,
  hammerToleranceMs: 30,
  license: "MIT",
  meToo: { lockScreen: 109, savingChanges: 17, switchingApps: 90 },
  name: "retake",
  notYet: ["layered recordings", "Spatial Audio", "Studio Sound", "iCloud sync", "Apple Watch"],
  repo: "github.com/AVGVSTVS96/retake",
  swiftLines: lines("."),
  uiTests: count("func test", "UITests"),
  voiceMemos: {
    cardRiseMs: 280,
    collapseMs: 215,
    source: "reference/SPEC.md 4.1 and 4.5, frame-counted at 60 fps",
    stopWaitMs: 330,
  },
};

writeFileSync(new URL("facts.json", import.meta.url), `${JSON.stringify(facts, null, 2)}\n`);

console.log(facts);
