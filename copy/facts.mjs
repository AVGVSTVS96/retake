import { execSync } from "node:child_process"
import { writeFileSync } from "node:fs"

const repo = process.env.RETAKE ?? `${process.env.HOME}/Developer/voice-memos`
const sh = (cmd) => execSync(cmd, { cwd: repo, encoding: "utf8", shell: "/bin/bash" }).trim()
const lines = (dir) => +sh(`fd -e swift . ${dir} -X cat | wc -l`)
const count = (pattern, dir) => +sh(`rg -c '${pattern}' ${dir} | awk -F: '{s+=$NF} END {print s}'`)

const cycles = +sh(`rg -o 'for cycle in 0\\.\\.<\\d+' -N --no-filename Packages/MemoKit/Tests | rg -o '\\d+$'`)

const facts = {
  name: "retake",
  repo: "github.com/AVGVSTVS96/retake",
  license: "MIT",
  swiftLines: lines("."),
  engineLines: lines("Packages/MemoKit/Sources"),
  engineTests: count("@Test", "Packages/MemoKit/Tests"),
  uiTests: count("func test", "UITests"),
  hammerCycles: cycles,
  hammerToleranceMs: 30,
  voiceMemos: { stopWaitMs: 330, collapseMs: 215, cardRiseMs: 280, source: "reference/SPEC.md 4.1 and 4.5, frame-counted at 60 fps" },
  meToo: { savingChanges: 17, switchingApps: 90, lockScreen: 109 },
  notYet: ["layered recordings", "Spatial Audio", "Studio Sound", "iCloud sync", "Apple Watch"],
  counted: new Date().toISOString().slice(0, 10),
}
writeFileSync(new URL("./facts.json", import.meta.url), JSON.stringify(facts, null, 2) + "\n")
console.log(facts)
