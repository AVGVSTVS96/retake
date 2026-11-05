import opentype from "opentype.js"
import { writeFileSync } from "node:fs"
import { spawnSync } from "node:child_process"

const here = import.meta.dirname
const font = opentype.loadSync(`${here}/src/funnel-display-700.ttf`)

const color = {
  ink: "#111113",
  night: "#F5F5F7",
  red: "#FF383C",
  redNight: "#FF4245",
  ring: "#D1D1D6",
  ringNight: "#48484A",
  paper: "#F2F2F7",
  tile: "#FFFFFF",
  tileNight: "#000000",
}

const TRACK = -34
const K = 1000 / font.unitsPerEm
const XH = font.tables.os2.sxHeight * K
const ASC = 700

const num = (n) => +n.toFixed(1)

function pathData(commands) {
  return commands.map((c) => {
    if (c.type === "M" || c.type === "L") return `${c.type}${num(c.x)} ${num(c.y)}`
    if (c.type === "Q") return `Q${num(c.x1)} ${num(c.y1)} ${num(c.x)} ${num(c.y)}`
    if (c.type === "C") return `C${num(c.x1)} ${num(c.y1)} ${num(c.x2)} ${num(c.y2)} ${num(c.x)} ${num(c.y)}`
    return "Z"
  }).join("")
}

const circle = (cx, cy, r) => `M${num(cx - r)} ${num(cy)}a${num(r)} ${num(r)} 0 1 0 ${num(2 * r)} 0a${num(r)} ${num(r)} 0 1 0 ${num(-2 * r)} 0Z`
const ring = (cx, cy, r, w) => circle(cx, cy, r) + `M${num(cx - r + w)} ${num(cy)}a${num(r - w)} ${num(r - w)} 0 1 1 ${num(2 * (r - w))} 0a${num(r - w)} ${num(r - w)} 0 1 1 ${num(-2 * (r - w))} 0Z`
const rect = (x, y, w, h) => `M${num(x)} ${num(y)}h${num(w)}v${num(h)}h${num(-w)}Z`
const pill = (x, y, w, h) => {
  const r = Math.min(w, h) / 2
  return `M${num(x + r)} ${num(y)}h${num(w - 2 * r)}a${num(r)} ${num(r)} 0 0 1 ${num(r)} ${num(r)}v${num(h - 2 * r)}a${num(r)} ${num(r)} 0 0 1 ${num(-r)} ${num(r)}h${num(2 * r - w)}a${num(r)} ${num(r)} 0 0 1 ${num(-r)} ${num(-r)}v${num(2 * r - h)}a${num(r)} ${num(r)} 0 0 1 ${num(r)} ${num(-r)}Z`
}

function superellipse(cx, cy, a, exponent) {
  const points = Array.from({ length: 192 }, (_, i) => {
    const t = (i / 192) * Math.PI * 2
    const x = Math.sign(Math.cos(t)) * Math.abs(Math.cos(t)) ** (2 / exponent)
    const y = Math.sign(Math.sin(t)) * Math.abs(Math.sin(t)) ** (2 / exponent)
    return `${num(cx + a * x)} ${num(cy + a * y)}`
  })
  return `M${points.join("L")}Z`
}

function set(text, x0 = 0) {
  let x = x0
  const parts = []
  let right = x0
  const glyphs = font.stringToGlyphs(text)
  glyphs.forEach((glyph, i) => {
    const path = glyph.getPath(x, 0, 1000)
    parts.push(pathData(path.commands))
    right = Math.max(right, path.getBoundingBox().x2)
    x += glyph.advanceWidth * K + TRACK
    if (glyphs[i + 1]) x += font.getKerningValue(glyph, glyphs[i + 1]) * K
  })
  const first = glyphs[0]
  return { d: parts.join(""), left: x0 + first.leftSideBearing * K, end: x - TRACK, right }
}

const word = set("retake")
const wordBox = { x: word.left, y: -ASC, w: word.right - word.left, h: ASC + 10 }

// The record button caught halfway to stop: the ring the app draws around it,
// and the red disc partway through its morph into the stop square.
const BUTTON = { ring: 0.07, gap: 0.075, shape: 0.76, exponent: 3 }

function button(cx, cy, d, { ringW = BUTTON.ring, morph = BUTTON.exponent, size = BUTTON.shape } = {}) {
  const r = d / 2
  const inner = r - d * ringW - d * BUTTON.gap
  return {
    ring: ring(cx, cy, r, d * ringW),
    shape: superellipse(cx, cy, inner * size, morph),
  }
}

function buttonSvg(d, { ringFill, shapeFill, ringW, cut = false }) {
  const b = button(d / 2, d / 2, d, { ringW })
  if (cut) return `<path d="${b.ring}" fill-rule="evenodd"/><path d="${b.shape}"/>`
  return `<path fill="${ringFill}" fill-rule="evenodd" d="${b.ring}"/><path fill="${shapeFill}" d="${b.shape}"/>`
}

const svg = (box, body, fill) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box.map(num).join(" ")}"${fill ? ` fill="${fill}"` : ""}>${body}</svg>\n`

function lockup({ ringFill, shapeFill, wordFill, mono = false }) {
  const d = 600
  const gap = 170
  const x = wordBox.x - d - gap
  const y = -XH / 2 - d / 2
  const b = button(x + d / 2, y + d / 2, d)
  const body = mono
    ? `<path fill-rule="evenodd" d="${b.ring}"/><path d="${b.shape}"/><path d="${word.d}"/>`
    : `<path fill="${ringFill}" fill-rule="evenodd" d="${b.ring}"/><path fill="${shapeFill}" d="${b.shape}"/><path fill="${wordFill}" d="${word.d}"/>`
  return svg([x, -ASC, wordBox.x + wordBox.w - x, Math.max(10, y + d) + ASC], body, mono ? "currentColor" : undefined)
}

function appIcon({ bg, ringFill, shapeFill, size = 1024, width = 0.7 }) {
  const d = size * width
  const o = (size - d) / 2
  const b = button(size / 2, size / 2, d, { ringW: 0.05 })
  return svg([0, 0, size, size], `${bg ? `<rect width="${size}" height="${size}" fill="${bg}"/>` : ""}<path fill="${ringFill}" fill-rule="evenodd" d="${b.ring}"/><path fill="${shapeFill}" d="${b.shape}"/>`)
}

const favicon = (() => {
  const b = button(32, 32, 62, { ringW: 0.1 })
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><style>.r{fill:${color.ink}}.s{fill:${color.red}}@media (prefers-color-scheme:dark){.r{fill:${color.night}}.s{fill:${color.redNight}}}</style><path class="r" fill-rule="evenodd" d="${b.ring}"/><path class="s" d="${b.shape}"/></svg>\n`
})()

const markSvg = (ringFill, shapeFill) => svg([0, 0, 1000, 1000], buttonSvg(1000, { ringFill, shapeFill }))

const files = {
  "wordmark.svg": svg([wordBox.x, wordBox.y, wordBox.w, wordBox.h], `<path d="${word.d}"/>`, color.ink),
  "wordmark-dark.svg": svg([wordBox.x, wordBox.y, wordBox.w, wordBox.h], `<path d="${word.d}"/>`, color.night),
  "wordmark-mono.svg": svg([wordBox.x, wordBox.y, wordBox.w, wordBox.h], `<path d="${word.d}"/>`, "currentColor"),
  "mark.svg": markSvg(color.ink, color.red),
  "mark-dark.svg": markSvg(color.night, color.redNight),
  "mark-mono.svg": svg([0, 0, 1000, 1000], buttonSvg(1000, { cut: true }), "currentColor"),
  "lockup.svg": lockup({ ringFill: color.ink, shapeFill: color.red, wordFill: color.ink }),
  "lockup-dark.svg": lockup({ ringFill: color.night, shapeFill: color.redNight, wordFill: color.night }),
  "lockup-mono.svg": lockup({ mono: true }),
  "favicon.svg": favicon,
  "app-icon.svg": appIcon({ bg: color.tile, ringFill: color.ring, shapeFill: color.red }),
  "app-icon-dark.svg": appIcon({ bg: color.tileNight, ringFill: color.ringNight, shapeFill: color.redNight }),
  "app-icon-tinted.svg": appIcon({ bg: "#000000", ringFill: "#5A5A5A", shapeFill: "#FFFFFF" }),
}

const explore = (() => {
  const card = (body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 640"><rect width="1600" height="640" fill="${color.paper}"/>${body}</svg>\n`
  const place = (d, fill, x = 800) => {
    const s = 0.36
    const w = wordBox.w * s
    return `<path fill="${fill}" transform="translate(${num(x - w / 2 - wordBox.x * s)} 420) scale(${s})" d="${d}"/>`
  }

  // A · Playhead: the word cut where a new take starts, by the red playhead
  const re = set("re")
  const head = { gap: 70, w: 34, dot: 50 }
  const px = re.end + head.gap
  const take = set("take", px + head.w + head.gap)
  const playhead = pill(px, -ASC - 40, head.w, ASC + 230) + circle(px + head.w / 2, -ASC - 40, head.dot) + circle(px + head.w / 2, 190, head.dot)
  const total = take.end - re.left
  const a = (() => {
    const s = 0.36
    const tx = 800 - (total * s) / 2 - re.left * s
    return `<g transform="translate(${num(tx)} 420) scale(${s})"><path fill="${color.ink}" d="${re.d}${take.d}"/><path fill="${color.red}" d="${playhead}"/></g>`
  })()

  // B · Button: lockup, picked
  const bSvg = (() => {
    const s = 0.36
    const d = 600, gap = 170
    const x = wordBox.x - d - gap
    const w = (wordBox.x + wordBox.w - x) * s
    const tx = 800 - w / 2 - x * s
    const bt = button(x + d / 2, -XH / 2, d)
    return `<g transform="translate(${num(tx)} 420) scale(${s})"><path fill="${color.ink}" fill-rule="evenodd" d="${bt.ring}"/><path fill="${color.red}" d="${bt.shape}"/><path fill="${color.ink}" d="${word.d}"/></g>`
  })()

  // C · Waveform: the word sliced into the app's bars, pitch 4.75 to width 1.75
  const c = (() => {
    const s = 0.36
    const pitch = 34, bar = 14
    const bars = []
    for (let x = wordBox.x - pitch; x < wordBox.x + wordBox.w + pitch; x += pitch) bars.push(pill(x, -ASC - 20, bar, ASC + 60))
    const tx = 800 - (wordBox.w * s) / 2 - wordBox.x * s
    return `<defs><clipPath id="bars"><path d="${bars.join("")}"/></clipPath></defs><g transform="translate(${num(tx)} 420) scale(${s})"><path clip-path="url(#bars)" fill="${color.ink}" d="${word.d}"/><path fill="${color.red}" d="${pill(wordBox.x + wordBox.w + 40, -ASC - 40, 20, ASC + 100)}"/></g>`
  })()

  return {
    "explore-a-playhead.svg": card(a),
    "explore-b-button.svg": card(bSvg),
    "explore-c-waveform.svg": card(c),
  }
})()

Object.assign(files, explore)
for (const [name, body] of Object.entries(files)) writeFileSync(`${here}/${name}`, body)

const png = (src, out, size) => {
  const r = spawnSync("rsvg-convert", ["-w", String(size), "-h", String(size), `${here}/${src}`, "-o", `${here}/${out}`])
  if (r.status) throw new Error(r.stderr.toString())
}
png("favicon.svg", "favicon-32.png", 32)
png("app-icon.svg", "apple-touch-icon.png", 180)
png("app-icon.svg", "icon-512.png", 512)
png("app-icon.svg", "app-icon-1024.png", 1024)
png("app-icon-dark.svg", "app-icon-dark-1024.png", 1024)
png("app-icon-tinted.svg", "app-icon-tinted-1024.png", 1024)
for (const f of ["mark", "mark-dark", "lockup", "lockup-dark", "wordmark", "wordmark-dark"]) {
  const r = spawnSync("rsvg-convert", ["-h", "512", `${here}/${f}.svg`, "-o", `${here}/${f}.png`])
  if (r.status) throw new Error(r.stderr.toString())
}
console.log(Object.keys(files).length, "svg files written")
