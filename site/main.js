import facts from "../copy/facts.json"

const still = matchMedia("(prefers-reduced-motion: reduce)")
const dark = matchMedia("(prefers-color-scheme: dark)")

const probe = document.createElement("i")
probe.hidden = true
document.body.append(probe)
const token = (name) => {
  probe.style.color = `var(${name})`
  return getComputedStyle(probe).color
}

function sharp(canvas) {
  const ratio = devicePixelRatio || 1
  const { width, height } = canvas.getBoundingClientRect()
  canvas.width = Math.round(width * ratio)
  canvas.height = Math.round(height * ratio)
  const ctx = canvas.getContext("2d")
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
  return { ctx, width, height }
}

function bar(ctx, x, mid, h, w) {
  ctx.beginPath()
  ctx.roundRect(x - w / 2, mid - h / 2, w, Math.max(h, w), w / 2)
  ctx.fill()
}

const loudness = (i) => {
  const s = Math.sin(i * 12.9898) * 43758.5453
  const grain = s - Math.floor(s)
  const phrase = 0.55 + 0.45 * Math.sin(i * 0.21) * Math.sin(i * 0.053 + 1)
  return Math.min(1, 0.18 + 0.82 * Math.abs(phrase) * (0.55 + 0.45 * grain))
}

const inView = (el, enter, leave) => {
  new IntersectionObserver(([entry]) => (entry.isIntersecting ? enter() : leave?.()), { threshold: 0.35 }).observe(el)
}

// The hero clip records, stops and records again three times. These are the
// clip's own record and stop moments, read from its frames.
function heroStrip() {
  const strip = document.querySelector(".strip")
  const video = document.querySelector(".hero-phone video")
  const canvas = strip.querySelector("canvas")
  const head = strip.querySelector(".playhead")
  const ruler = strip.querySelector(".strip-ruler")
  const labels = strip.querySelector(".strip-takes")
  const takes = [[1.05, 5.1], [8.75, 15.05], [18.55, 22.55]]
  const length = 24
  const names = ["New Recording", "New Recording 2", "New Recording 3"]

  for (let s = 0; s < length; s += 5) ruler.insertAdjacentHTML("beforeend", `<span style="left:${(s / length) * 100}%">0:${String(s).padStart(2, "0")}</span>`)
  const tags = takes.map(([from, to], i) => {
    const el = document.createElement("span")
    el.className = "take"
    const end = to / length > 0.85
    el.classList.toggle("end", end)
    el.style.left = `${((end ? to : from) / length) * 100}%`
    el.innerHTML = `<span class="word">${names[i]}</span><small>0:${String(Math.round(to - from)).padStart(2, "0")}</small>`
    labels.append(el)
    return el
  })

  let size
  const draw = (t) => {
    size ??= sharp(canvas)
    const { ctx, width, height } = size
    ctx.clearRect(0, 0, width, height)
    const pitch = width < 600 ? 4 : 5
    const mid = height / 2
    const live = takes.findIndex(([a, b]) => t >= a && t < b)
    ctx.fillStyle = token("--ink-3")
    for (let x = pitch / 2; x < (t / length) * width; x += pitch * 2) ctx.fillRect(x, mid - 0.5, 1.5, 1.5)
    takes.forEach(([a, b], i) => {
      if (t < a) return
      ctx.fillStyle = i === live ? token("--red") : token("--ink-3")
      const end = Math.min(t, b)
      const x0 = (a / length) * width
      const x1 = (end / length) * width
      ctx.clearRect(x0, 0, x1 - x0, height)
      for (let x = x0 + pitch / 2; x < x1; x += pitch) bar(ctx, x, mid, loudness(Math.round(x / pitch)) * height * 0.92, 2)
    })
    head.style.left = `${(t / length) * 100}%`
    head.classList.toggle("live", live >= 0)
    tags.forEach((tag, i) => tag.classList.toggle("in", t >= takes[i][1]))
  }

  const settle = () => draw(length)
  const moving = () => !still.matches && !dark.matches

  let frame
  const tick = () => {
    draw(video.currentTime)
    frame = video.requestVideoFrameCallback ? video.requestVideoFrameCallback(tick) : requestAnimationFrame(tick)
  }
  const play = () => {
    if (!moving()) return settle()
    video.play().then(tick, settle)
  }
  const stop = () => video.pause()

  addEventListener("resize", () => {
    size = undefined
    moving() && !video.paused ? draw(video.currentTime) : settle()
  })
  dark.addEventListener("change", () => {
    size = undefined
    moving() ? play() : (stop(), settle())
  })
  settle()
  inView(strip.parentElement, play, stop)
}

function stopTiming() {
  const timing = document.querySelector(".timing")
  const lanes = timing.querySelector(".lanes")
  const blocks = [...timing.querySelectorAll(".block")].map((el) => ({
    el,
    from: +el.style.getPropertyValue("--from"),
    to: +el.style.getPropertyValue("--to"),
  }))
  const rows = [...timing.querySelectorAll(".row-in")].map((el) => ({ el, at: +el.style.getPropertyValue("--at") }))
  const buttons = [...timing.querySelectorAll(".speeds button")]
  const end = 600

  const show = (t) => {
    lanes.style.setProperty("--t", t)
    for (const b of blocks) b.el.style.setProperty("--shown", `${Math.max(0, Math.min(1, (t - b.from) / (b.to - b.from))) * 100}%`)
    for (const r of rows) r.el.style.setProperty("--row", t >= r.at ? 1 : 0)
  }

  let raf
  const run = (rate) => {
    cancelAnimationFrame(raf)
    if (still.matches) return show(end)
    let start
    const step = (now) => {
      start ??= now
      const t = Math.min(end, (now - start) * rate)
      show(t)
      if (t < end) raf = requestAnimationFrame(step)
    }
    raf = requestAnimationFrame(step)
  }

  for (const button of buttons) {
    button.addEventListener("click", () => {
      for (const b of buttons) b.setAttribute("aria-pressed", b === button)
      run(+button.dataset.rate)
    })
  }

  show(still.matches ? end : 0)
  let seen = false
  inView(timing, () => {
    if (seen) return
    seen = true
    setTimeout(() => run(1), 250)
  })
}

// One bar per take in the test, as long as that take: 50 ms plus 10 ms per
// cycle mod 7, and every fifth take pauses, resumes and records 20 ms more.
function ledger() {
  const canvas = document.querySelector(".ledger canvas")
  const readout = document.querySelector(".ledger-read")
  const count = facts.hammerCycles
  const takes = Array.from({ length: count }, (_, c) => ({
    title: c === 0 ? "New Recording" : `New Recording ${c + 1}`,
    ms: 50 + (c % 7) * 10 + (c % 5 === 0 ? 20 : 0),
    paused: c % 5 === 0,
  }))
  const longest = Math.max(...takes.map((t) => t.ms))

  let size, shown = still.matches ? count : 0, active = -1
  const layout = () => {
    size ??= sharp(canvas)
    const rows = size.width < 560 ? 3 : 1
    const per = Math.ceil(count / rows)
    return { ...size, rows, per, pitch: size.width / per, band: size.height / rows }
  }
  const draw = () => {
    const { ctx, width, height, per, pitch, band } = layout()
    ctx.clearRect(0, 0, width, height)
    const ink = token("--ink-3"), red = token("--red")
    for (let i = 0; i < shown; i++) {
      const row = Math.floor(i / per)
      const x = (i % per) * pitch + pitch / 2
      ctx.fillStyle = i === active ? red : ink
      bar(ctx, x, row * band + band / 2, (takes[i].ms / longest) * band * 0.86, Math.max(1, Math.min(2.5, pitch * 0.5)))
    }
  }
  const read = (i) => {
    const t = takes[i]
    readout.querySelector(".title").textContent = t.title
    readout.querySelector(".len").textContent = `${t.ms} ms${t.paused ? ", paused and resumed once" : ""}`
  }
  read(count - 1)

  canvas.addEventListener("pointermove", (e) => {
    const { per, pitch, band } = layout()
    const r = canvas.getBoundingClientRect()
    const row = Math.min(Math.floor((e.clientY - r.top) / band), Math.ceil(count / per) - 1)
    const i = Math.max(0, Math.min(count - 1, row * per + Math.floor((e.clientX - r.left) / pitch)))
    if (i === active) return
    active = i
    read(i)
    draw()
  })
  canvas.addEventListener("pointerleave", () => {
    active = -1
    read(count - 1)
    draw()
  })
  addEventListener("resize", () => {
    size = undefined
    draw()
  })
  dark.addEventListener("change", draw)

  draw()
  inView(canvas, () => {
    if (shown === count) return
    let start
    const step = (now) => {
      start ??= now
      shown = Math.min(count, Math.round(((now - start) / 1400) * count))
      draw()
      if (shown < count) requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  })
}

function copyButton() {
  const button = document.querySelector(".copy")
  button.addEventListener("click", async () => {
    await navigator.clipboard.writeText(document.querySelector(".code code").textContent)
    button.textContent = "Copied"
    setTimeout(() => (button.textContent = "Copy"), 1600)
  })
}

heroStrip()
stopTiming()
ledger()
copyButton()
