import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";

import type { PathCommand } from "opentype.js";
import { parse } from "opentype.js";

const here = import.meta.dirname;
const font = parse(new Uint8Array(readFileSync(`${here}/src/funnel-display-700.ttf`)).buffer);

const defined = (value: number | undefined, what: string) => {
  if (value === undefined) {
    throw new TypeError(`funnel-display-700.ttf has no ${what}`);
  }

  return value;
};

const color = {
  ink: "#111113",
  night: "#F5F5F7",
  paper: "#F2F2F7",
  red: "#FF383C",
  redNight: "#FF4245",
  ring: "#D1D1D6",
  ringNight: "#48484A",
  tile: "#FFFFFF",
  tileNight: "#000000",
};

const TRACK = -34;
const K = 1000 / font.unitsPerEm;
const XH = Number(font.tables.os2?.sxHeight) * K;

if (Number.isNaN(XH)) {
  throw new TypeError("funnel-display-700.ttf has no x-height");
}

const ASC = 700;

const num = (n: number) => Number(n.toFixed(1));

const commandData = (c: PathCommand) => {
  if (c.type === "Z") {
    return "Z";
  }

  if (c.type === "Q") {
    return `Q${num(c.x1)} ${num(c.y1)} ${num(c.x)} ${num(c.y)}`;
  }

  if (c.type === "C") {
    return `C${num(c.x1)} ${num(c.y1)} ${num(c.x2)} ${num(c.y2)} ${num(c.x)} ${num(c.y)}`;
  }

  return `${c.type}${num(c.x)} ${num(c.y)}`;
};

const pathData = (commands: PathCommand[]) => commands.map(commandData).join("");

const circle = (cx: number, cy: number, r: number) =>
  `M${num(cx - r)} ${num(cy)}a${num(r)} ${num(r)} 0 1 0 ${num(2 * r)} 0a${num(r)} ${num(r)} 0 1 0 ${num(-2 * r)} 0Z`;

const ring = (cx: number, cy: number, r: number, w: number) =>
  `${circle(cx, cy, r)}M${num(cx - r + w)} ${num(cy)}a${num(r - w)} ${num(r - w)} 0 1 1 ${num(2 * (r - w))} 0a${num(r - w)} ${num(r - w)} 0 1 1 ${num(-2 * (r - w))} 0Z`;

const pill = (x: number, y: number, w: number, h: number) => {
  const r = Math.min(w, h) / 2;

  return `M${num(x + r)} ${num(y)}h${num(w - 2 * r)}a${num(r)} ${num(r)} 0 0 1 ${num(r)} ${num(r)}v${num(h - 2 * r)}a${num(r)} ${num(r)} 0 0 1 ${num(-r)} ${num(r)}h${num(2 * r - w)}a${num(r)} ${num(r)} 0 0 1 ${num(-r)} ${num(-r)}v${num(2 * r - h)}a${num(r)} ${num(r)} 0 0 1 ${num(r)} ${num(-r)}Z`;
};

const superellipse = (cx: number, cy: number, a: number, exponent: number) => {
  const points = Array.from({ length: 192 }, (_, i) => {
    const t = (i / 192) * Math.PI * 2;
    const x = Math.sign(Math.cos(t)) * Math.abs(Math.cos(t)) ** (2 / exponent);
    const y = Math.sign(Math.sin(t)) * Math.abs(Math.sin(t)) ** (2 / exponent);

    return `${num(cx + a * x)} ${num(cy + a * y)}`;
  });

  return `M${points.join("L")}Z`;
};

const set = (text: string, x0 = 0) => {
  const glyphs = Array.from(text, (character) => font.charToGlyph(character));
  const [first] = glyphs;

  if (!first) {
    throw new Error("set needs text");
  }

  const parts: string[] = [];
  let x = x0;
  let right = x0;

  for (const [i, glyph] of glyphs.entries()) {
    const path = glyph.getPath(x, 0, 1000);

    parts.push(pathData(path.commands));
    right = Math.max(right, path.getBoundingBox().x2);
    x += defined(glyph.advanceWidth, "advance width") * K + TRACK;

    const next = glyphs[i + 1];

    if (next) {
      x += font.getKerningValue(glyph, next) * K;
    }
  }

  return {
    d: parts.join(""),
    end: x - TRACK,
    left: x0 + defined(first.leftSideBearing, "left side bearing") * K,
    right,
  };
};

const word = set("retake");
const wordBox = { h: ASC + 10, w: word.right - word.left, x: word.left, y: -ASC };

const halfwayToStop = { exponent: 3, gap: 0.075, ring: 0.07, size: 0.76 };

interface ButtonLook {
  ringWidth?: number;
}

const recordButton = (
  cx: number,
  cy: number,
  d: number,
  { ringWidth = halfwayToStop.ring }: ButtonLook = {},
) => {
  const r = d / 2;
  const inner = r - d * ringWidth - d * halfwayToStop.gap;

  return {
    disc: superellipse(cx, cy, inner * halfwayToStop.size, halfwayToStop.exponent),
    ring: ring(cx, cy, r, d * ringWidth),
  };
};

interface Fills {
  disc: string;
  ring: string;
}

const svg = (box: number[], body: string, fill?: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box.map(num).join(" ")}"${fill === undefined ? "" : ` fill="${fill}"`}>${body}</svg>\n`;

const markSvg = (fills: Fills) => {
  const b = recordButton(500, 500, 1000);

  return svg(
    [0, 0, 1000, 1000],
    `<path fill="${fills.ring}" fill-rule="evenodd" d="${b.ring}"/><path fill="${fills.disc}" d="${b.disc}"/>`,
  );
};

const markMonoSvg = () => {
  const b = recordButton(500, 500, 1000);

  return svg(
    [0, 0, 1000, 1000],
    `<path d="${b.ring}" fill-rule="evenodd"/><path d="${b.disc}"/>`,
    "currentColor",
  );
};

const lockupGap = 170;
const lockupButton = 600;
const lockupLeft = wordBox.x - lockupButton - lockupGap;

const lockup = (fills?: Fills & { word: string }) => {
  const y = -XH / 2 - lockupButton / 2;
  const b = recordButton(lockupLeft + lockupButton / 2, y + lockupButton / 2, lockupButton);

  const body = fills
    ? `<path fill="${fills.ring}" fill-rule="evenodd" d="${b.ring}"/><path fill="${fills.disc}" d="${b.disc}"/><path fill="${fills.word}" d="${word.d}"/>`
    : `<path fill-rule="evenodd" d="${b.ring}"/><path d="${b.disc}"/><path d="${word.d}"/>`;

  return svg(
    [lockupLeft, -ASC, wordBox.x + wordBox.w - lockupLeft, Math.max(10, y + lockupButton) + ASC],
    body,
    fills ? undefined : "currentColor",
  );
};

const appIcon = ({ bg, ...fills }: Fills & { bg: string }) => {
  const size = 1024;
  const b = recordButton(size / 2, size / 2, size * 0.7, { ringWidth: 0.05 });

  return svg(
    [0, 0, size, size],
    `<rect width="${size}" height="${size}" fill="${bg}"/><path fill="${fills.ring}" fill-rule="evenodd" d="${b.ring}"/><path fill="${fills.disc}" d="${b.disc}"/>`,
  );
};

const favicon = () => {
  const b = recordButton(32, 32, 62, { ringWidth: 0.1 });

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><style>.r{fill:${color.ink}}.s{fill:${color.red}}@media (prefers-color-scheme:dark){.r{fill:${color.night}}.s{fill:${color.redNight}}}</style><path class="r" fill-rule="evenodd" d="${b.ring}"/><path class="s" d="${b.disc}"/></svg>\n`;
};

const wordmark = (fill: string) =>
  svg([wordBox.x, wordBox.y, wordBox.w, wordBox.h], `<path d="${word.d}"/>`, fill);

const exploreCard = (body: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 640"><rect width="1600" height="640" fill="${color.paper}"/>${body}</svg>\n`;

const exploreScale = 0.36;

const wordCutByPlayhead = () => {
  const re = set("re");
  const head = { dot: 50, gap: 70, w: 34 };
  const px = re.end + head.gap;
  const take = set("take", px + head.w + head.gap);

  const playhead =
    pill(px, -ASC - 40, head.w, ASC + 230) +
    circle(px + head.w / 2, -ASC - 40, head.dot) +
    circle(px + head.w / 2, 190, head.dot);

  const tx = 800 - ((take.end - re.left) * exploreScale) / 2 - re.left * exploreScale;

  return `<g transform="translate(${num(tx)} 420) scale(${exploreScale})"><path fill="${color.ink}" d="${re.d}${take.d}"/><path fill="${color.red}" d="${playhead}"/></g>`;
};

const lockupPicked = () => {
  const w = (wordBox.x + wordBox.w - lockupLeft) * exploreScale;
  const tx = 800 - w / 2 - lockupLeft * exploreScale;
  const b = recordButton(lockupLeft + lockupButton / 2, -XH / 2, lockupButton);

  return `<g transform="translate(${num(tx)} 420) scale(${exploreScale})"><path fill="${color.ink}" fill-rule="evenodd" d="${b.ring}"/><path fill="${color.red}" d="${b.disc}"/><path fill="${color.ink}" d="${word.d}"/></g>`;
};

const wordSlicedIntoBars = () => {
  const barWidth = 14;
  const pitch = 34;
  const bars: string[] = [];

  for (let x = wordBox.x - pitch; x < wordBox.x + wordBox.w + pitch; x += pitch) {
    bars.push(pill(x, -ASC - 20, barWidth, ASC + 60));
  }

  const tx = 800 - (wordBox.w * exploreScale) / 2 - wordBox.x * exploreScale;

  return `<defs><clipPath id="bars"><path d="${bars.join("")}"/></clipPath></defs><g transform="translate(${num(tx)} 420) scale(${exploreScale})"><path clip-path="url(#bars)" fill="${color.ink}" d="${word.d}"/><path fill="${color.red}" d="${pill(wordBox.x + wordBox.w + 40, -ASC - 40, 20, ASC + 100)}"/></g>`;
};

const files = {
  "app-icon-dark.svg": appIcon({
    bg: color.tileNight,
    disc: color.redNight,
    ring: color.ringNight,
  }),
  "app-icon-tinted.svg": appIcon({ bg: "#000000", disc: "#FFFFFF", ring: "#5A5A5A" }),
  "app-icon.svg": appIcon({ bg: color.tile, disc: color.red, ring: color.ring }),
  "explore-a-playhead.svg": exploreCard(wordCutByPlayhead()),
  "explore-b-button.svg": exploreCard(lockupPicked()),
  "explore-c-waveform.svg": exploreCard(wordSlicedIntoBars()),
  "favicon.svg": favicon(),
  "lockup-dark.svg": lockup({ disc: color.redNight, ring: color.night, word: color.night }),
  "lockup-mono.svg": lockup(),
  "lockup.svg": lockup({ disc: color.red, ring: color.ink, word: color.ink }),
  "mark-dark.svg": markSvg({ disc: color.redNight, ring: color.night }),
  "mark-mono.svg": markMonoSvg(),
  "mark.svg": markSvg({ disc: color.red, ring: color.ink }),
  "wordmark-dark.svg": wordmark(color.night),
  "wordmark-mono.svg": wordmark("currentColor"),
  "wordmark.svg": wordmark(color.ink),
};

for (const [name, body] of Object.entries(files)) {
  writeFileSync(`${here}/${name}`, body);
}

const rasterize = (src: string, out: string, size: string[]) => {
  const result = spawnSync("rsvg-convert", [...size, `${here}/${src}`, "-o", `${here}/${out}`]);

  if (result.status !== 0) {
    throw new Error(result.stderr.toString());
  }
};

const square = (side: number) => ["-w", String(side), "-h", String(side)];

rasterize("favicon.svg", "favicon-32.png", square(32));

rasterize("app-icon.svg", "apple-touch-icon.png", square(180));

rasterize("app-icon.svg", "icon-512.png", square(512));

rasterize("app-icon.svg", "app-icon-1024.png", square(1024));

rasterize("app-icon-dark.svg", "app-icon-dark-1024.png", square(1024));

rasterize("app-icon-tinted.svg", "app-icon-tinted-1024.png", square(1024));

for (const name of ["mark", "mark-dark", "lockup", "lockup-dark", "wordmark", "wordmark-dark"]) {
  rasterize(`${name}.svg`, `${name}.png`, ["-h", "512"]);
}

console.log(Object.keys(files).length, "svg files written");
