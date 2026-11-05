import facts from "../copy/facts.json";

const still = matchMedia("(prefers-reduced-motion: reduce)");
const dark = matchMedia("(prefers-color-scheme: dark)");

const find = <T extends Element>(root: ParentNode, selector: string, type: new () => T): T => {
  const element = root.querySelector(selector);

  if (!(element instanceof type)) {
    throw new TypeError(`index.html has no ${type.name} at ${selector}`);
  }

  return element;
};

const findAll = <T extends Element>(root: ParentNode, selector: string, type: new () => T): T[] =>
  [...root.querySelectorAll(selector)].filter((element): element is T => element instanceof type);

const probe = document.createElement("i");

probe.hidden = true;

document.body.append(probe);

const token = (name: string) => {
  probe.style.color = `var(${name})`;

  return getComputedStyle(probe).color;
};

interface Surface {
  ctx: CanvasRenderingContext2D;
  height: number;
  width: number;
}

const sharp = (canvas: HTMLCanvasElement): Surface => {
  const ratio = devicePixelRatio || 1;
  const { width, height } = canvas.getBoundingClientRect();

  canvas.width = Math.round(width * ratio);
  canvas.height = Math.round(height * ratio);

  const ctx = canvas.getContext("2d");

  if (!ctx) {
    throw new Error("canvas has no 2d context");
  }

  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);

  return { ctx, height, width };
};

const bar = (ctx: CanvasRenderingContext2D, x: number, mid: number, h: number, w: number) => {
  ctx.beginPath();
  ctx.roundRect(x - w / 2, mid - h / 2, w, Math.max(h, w), w / 2);
  ctx.fill();
};

const loudness = (i: number) => {
  const s = Math.sin(i * 12.9898) * 43_758.5453;
  const grain = s - Math.floor(s);
  const phrase = 0.55 + 0.45 * Math.sin(i * 0.21) * Math.sin(i * 0.053 + 1);

  return Math.min(1, 0.18 + 0.82 * Math.abs(phrase) * (0.55 + 0.45 * grain));
};

const inView = (element: Element, enter: () => void, leave?: () => void) => {
  new IntersectionObserver(
    ([entry]) => {
      if (entry?.isIntersecting === true) {
        enter();
      } else {
        leave?.();
      }
    },
    { threshold: 0.35 },
  ).observe(element);
};

const seconds = (s: number) => `0:${String(s).padStart(2, "0")}`;

const heroClipTakes: [start: number, stop: number][] = [
  [1.05, 5.1],
  [8.75, 15.05],
  [18.55, 22.55],
];

const heroClipLength = 24;
const heroClipTitles = ["New Recording", "New Recording 2", "New Recording 3"];

const heroStrip = () => {
  const strip = find(document, ".strip", HTMLElement);
  const video = find(document, ".hero-phone video", HTMLVideoElement);
  const canvas = find(strip, "canvas", HTMLCanvasElement);
  const head = find(strip, ".playhead", HTMLElement);
  const ruler = find(strip, ".strip-ruler", HTMLElement);
  const labels = find(strip, ".strip-takes", HTMLElement);

  for (let s = 0; s < heroClipLength; s += 5) {
    ruler.insertAdjacentHTML(
      "beforeend",
      `<span style="left:${(s / heroClipLength) * 100}%">${seconds(s)}</span>`,
    );
  }

  const tags = heroClipTakes.map(([from, to], i) => {
    const tag = document.createElement("span");
    const end = to / heroClipLength > 0.85;

    tag.className = "take";
    tag.classList.toggle("end", end);
    tag.style.left = `${((end ? to : from) / heroClipLength) * 100}%`;
    tag.innerHTML = `<span class="word">${heroClipTitles[i] ?? ""}</span><small>${seconds(Math.round(to - from))}</small>`;
    labels.append(tag);

    return { stop: to, tag };
  });

  let surface: Surface | undefined;

  const draw = (t: number) => {
    surface ??= sharp(canvas);

    const { ctx, width, height } = surface;
    const pitch = width < 600 ? 4 : 5;
    const mid = height / 2;
    const live = heroClipTakes.findIndex(([a, b]) => t >= a && t < b);

    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = token("--ink-3");

    for (let x = pitch / 2; x < (t / heroClipLength) * width; x += pitch * 2) {
      ctx.fillRect(x, mid - 0.5, 1.5, 1.5);
    }

    for (const [i, [a, b]] of heroClipTakes.entries()) {
      if (t >= a) {
        ctx.fillStyle = i === live ? token("--red") : token("--ink-3");

        const x0 = (a / heroClipLength) * width;
        const x1 = (Math.min(t, b) / heroClipLength) * width;

        ctx.clearRect(x0, 0, x1 - x0, height);

        for (let x = x0 + pitch / 2; x < x1; x += pitch) {
          bar(ctx, x, mid, loudness(Math.round(x / pitch)) * height * 0.92, 2);
        }
      }
    }

    head.style.left = `${(t / heroClipLength) * 100}%`;
    head.classList.toggle("live", live !== -1);

    for (const { stop, tag } of tags) {
      tag.classList.toggle("in", t >= stop);
    }
  };

  const settle = () => {
    draw(heroClipLength);
  };

  const moving = () => !still.matches && !dark.matches;

  const tick = () => {
    draw(video.currentTime);
    video.requestVideoFrameCallback(tick);
  };

  const play = () => {
    if (moving()) {
      video.play().then(tick).catch(settle);
    } else {
      settle();
    }
  };

  const stop = () => {
    video.pause();
  };

  addEventListener("resize", () => {
    surface = undefined;

    if (moving() && !video.paused) {
      draw(video.currentTime);
    } else {
      settle();
    }
  });

  dark.addEventListener("change", () => {
    surface = undefined;

    if (moving()) {
      play();
    } else {
      stop();
      settle();
    }
  });

  settle();
  inView(strip.parentElement ?? strip, play, stop);
};

const cssNumber = (element: HTMLElement, property: string) =>
  Number(element.style.getPropertyValue(property));

const stopTiming = () => {
  const timing = find(document, ".timing", HTMLElement);
  const lanes = find(timing, ".lanes", HTMLElement);

  const blocks = findAll(timing, ".block", HTMLElement).map((element) => ({
    element,
    from: cssNumber(element, "--from"),
    to: cssNumber(element, "--to"),
  }));

  const rows = findAll(timing, ".row-in", HTMLElement).map((element) => ({
    at: cssNumber(element, "--at"),
    element,
  }));

  const buttons = findAll(timing, ".speeds button", HTMLButtonElement);
  const end = 600;

  const show = (t: number) => {
    lanes.style.setProperty("--t", String(t));
    lanes.classList.toggle("done", t >= end);

    for (const block of blocks) {
      const shown = Math.max(0, Math.min(1, (t - block.from) / (block.to - block.from)));

      block.element.style.setProperty("--shown", `${shown * 100}%`);
    }

    for (const row of rows) {
      row.element.style.setProperty("--row", t >= row.at ? "1" : "0");
    }
  };

  let raf = 0;

  const run = (rate: number) => {
    cancelAnimationFrame(raf);

    if (still.matches) {
      show(end);

      return;
    }

    let start: number | undefined;

    const step = (now: number) => {
      start ??= now;

      const t = Math.min(end, (now - start) * rate);

      show(t);

      if (t < end) {
        raf = requestAnimationFrame(step);
      }
    };

    raf = requestAnimationFrame(step);
  };

  for (const button of buttons) {
    button.addEventListener("click", () => {
      for (const other of buttons) {
        other.setAttribute("aria-pressed", String(other === button));
      }

      run(Number(button.dataset.rate));
    });
  }

  show(still.matches ? end : 0);

  let seen = false;

  inView(timing, () => {
    if (!seen) {
      seen = true;
      setTimeout(() => {
        run(1);
      }, 250);
    }
  });
};

const hammerTake = (cycle: number) => ({
  ms: 50 + (cycle % 7) * 10 + (cycle % 5 === 0 ? 20 : 0),
  paused: cycle % 5 === 0,
  title: cycle === 0 ? "New Recording" : `New Recording ${cycle + 1}`,
});

const ledger = () => {
  const canvas = find(document, ".ledger canvas", HTMLCanvasElement);
  const readout = find(document, ".ledger-read", HTMLElement);
  const title = find(readout, ".title", HTMLElement);
  const length = find(readout, ".len", HTMLElement);
  const count = facts.hammerCycles;
  const takes = Array.from({ length: count }, (_, cycle) => hammerTake(cycle));
  const longest = Math.max(...takes.map((take) => take.ms));

  let surface: Surface | undefined;
  let shown = still.matches ? count : 0;
  let active = -1;

  const layout = () => {
    surface ??= sharp(canvas);

    const rows = surface.width < 560 ? 3 : 1;
    const per = Math.ceil(count / rows);

    return { ...surface, band: surface.height / rows, per, pitch: surface.width / per };
  };

  const draw = () => {
    const { ctx, width, height, per, pitch, band } = layout();
    const ink = token("--ink-3");
    const red = token("--red");

    ctx.clearRect(0, 0, width, height);

    for (const [i, take] of takes.slice(0, shown).entries()) {
      const row = Math.floor(i / per);
      const x = (i % per) * pitch + pitch / 2;

      ctx.fillStyle = i === active ? red : ink;
      bar(
        ctx,
        x,
        row * band + band / 2,
        (take.ms / longest) * band * 0.86,
        Math.max(1, Math.min(2.5, pitch * 0.5)),
      );
    }
  };

  const read = (i: number) => {
    const take = takes[i];

    if (take) {
      title.textContent = take.title;
      length.textContent = `${take.ms} ms long${take.paused ? ", paused and resumed once" : ""}`;
    }
  };

  read(count - 1);

  canvas.addEventListener("pointermove", (event) => {
    const { per, pitch, band } = layout();
    const box = canvas.getBoundingClientRect();
    const row = Math.min(Math.floor((event.clientY - box.top) / band), Math.ceil(count / per) - 1);

    const i = Math.max(
      0,
      Math.min(count - 1, row * per + Math.floor((event.clientX - box.left) / pitch)),
    );

    if (i !== active) {
      active = i;
      read(i);
      draw();
    }
  });

  canvas.addEventListener("pointerleave", () => {
    active = -1;
    read(count - 1);
    draw();
  });

  addEventListener("resize", () => {
    surface = undefined;
    draw();
  });

  dark.addEventListener("change", draw);
  draw();

  inView(canvas, () => {
    if (shown === count) {
      return;
    }

    let start: number | undefined;

    const step = (now: number) => {
      start ??= now;
      shown = Math.min(count, Math.round(((now - start) / 1400) * count));
      draw();

      if (shown < count) {
        requestAnimationFrame(step);
      }
    };

    requestAnimationFrame(step);
  });
};

const copyButton = () => {
  const button = find(document, ".copy", HTMLButtonElement);
  const code = find(document, ".code code", HTMLElement);

  const copy = async () => {
    await navigator.clipboard.writeText(code.textContent);
    button.textContent = "Copied";
    setTimeout(() => {
      button.textContent = "Copy";
    }, 1600);
  };

  button.addEventListener("click", () => {
    void copy();
  });
};

heroStrip();

stopTiming();

ledger();

copyButton();
