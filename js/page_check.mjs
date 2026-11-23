// page_check -- the JavaScript playground's page, run with no browser.
//
//   node js/page_check.mjs <build-dir> <tests-dir> <canvas-dir>
//
// It loads <build-dir>/js.wasm through the page's own js_runner.js and:
//
// - runs every program in <tests-dir> through it, each held to what node
//   itself prints for it (the program run in a fresh context whose
//   console.log writes util.format's line, as console.log does, and whose
//   timers are node's own, waited for until none is left);
// - holds each program in <tests-dir>/refused to the message its first line
//   names, but for one js-run stops on its budget of timer callbacks: the
//   page has no such budget (an interval may animate for good), so that one
//   must still be running after its ticks, as it would be in node;
// - ticks each program's clock a frame at a time, as the page does, until
//   it ends or `MOST_TICKS` have run, so its timers run;
// - runs each canvas sample <canvas-dir>/goldens.txt names, as js-canvas
//   does (its reads answered and logged as js-canvas answers and logs them,
//   its clicks queued before their frames), and holds the wasm's lines to the
//   sample's golden log, byte for byte;
// - builds the page itself, js_page.js, on a stand-in document and canvas,
//   runs every sample, calls three frames of each that has a frame loop,
//   and runs a turtle sample in slow motion, which must paint what full
//   speed paints.
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import util from "node:util";
import vm from "node:vm";

const [dir, tests, canvasDir] = process.argv.slice(2);
if (!dir || !tests || !canvasDir) {
  console.error("usage: node js/page_check.mjs <build-dir> <tests-dir> <canvas-dir>");
  process.exit(2);
}

let failures = 0;
function fail(why) { failures++; console.error(`page_check: FAIL ${why}`); }

const { loadRunner, transcriptOf } = await import(pathToFileURL(join(dir, "js_runner.js")).href);
const runner = await loadRunner(readFileSync(join(dir, "js.wasm")));

// What node prints for a program, its timers run on node's own clock until
// none is left.
async function nodeOutput(src) {
  let out = "";
  const console = { log: (...args) => { out += util.format(...args) + "\n"; } };
  const live = new Set();
  const context = {
    console,
    setTimeout: (f, ms, ...rest) => {
      const t = setTimeout(() => { live.delete(t); f(...rest); }, ms);
      live.add(t);
      return t;
    },
    setInterval: (f, ms, ...rest) => { const t = setInterval(f, ms, ...rest); live.add(t); return t; },
    clearTimeout: (t) => { live.delete(t); clearTimeout(t); },
    clearInterval: (t) => { live.delete(t); clearInterval(t); },
  };
  vm.runInNewContext(src, context);
  while (live.size > 0) await new Promise((done) => setTimeout(done, 5));
  return out;
}

// Ten seconds of the page's frames: the longest a corpus program's timers run.
const MOST_TICKS = 300;

function runWhole(src) {
  const lines = [];
  const sink = (line) => lines.push(line);
  let result = runner.start(src, sink);
  for (let n = 0; n < MOST_TICKS && result.ending === "frame"; n++) result = runner.frame(n / 30, sink);
  return { result, text: transcriptOf(lines, result) };
}

const programs = readdirSync(tests).filter((f) => f.endsWith(".js")).sort();
for (const f of programs) {
  const src = readFileSync(join(tests, f), "utf8");
  const want = await nodeOutput(src);
  const got = runWhole(src);
  if (got.result.ending !== "done") fail(`${f}: the page's run ended ${got.result.ending}: ${got.result.why}`);
  else if (got.text !== want) fail(`${f}: the page printed what node does not`);
}

const refused = readdirSync(join(tests, "refused")).filter((f) => f.endsWith(".js")).sort();
for (const f of refused) {
  const src = readFileSync(join(tests, "refused", f), "utf8");
  const must = src.split("\n")[0].replace(/^\/\/ refused: /, "");
  const got = runWhole(src);
  const last = got.text.trim().split("\n").pop();
  if (must.includes("timer callbacks")) {
    if (got.result.ending !== "frame") fail(`refused/${f}: the page's run ended ${got.result.ending}, where it must run on`);
  } else if (!["faulted", "refused"].includes(got.result.ending) || !last.startsWith("js: ") || !last.includes(must)) {
    fail(`refused/${f}: wanted \`${must}\`, the page said \`${last}\` (${got.result.ending})`);
  }
}

// ── the canvas samples, held to their golden logs ─────────────────────────

function recorded(src, frames, keyFrames, clicks) {
  const log = [];
  let keys = [];
  runner.input.pointer = (axis) => { log.push(`read ${axis === 0 ? "mouseX" : "mouseY"} 200`); return 200; };
  runner.input.key = (name) => {
    const down = keys.includes(name);
    log.push(`read keyIsDown ${name} ${down ? "down" : "up"}`);
    return down;
  };
  const sink = (line) => log.push(line);
  let result = runner.start(src, sink);
  for (let n = 0; n < frames && result.ending === "frame"; n++) {
    for (const [at, x, y] of clicks) {
      if (at !== n) continue;
      log.push(`click ${x} ${y}`);
      runner.click(x, y);
    }
    const t = n / 30;
    log.push(`frame ${n} ${String(t)}`);
    keys = (keyFrames[n] ?? "").split("+");
    result = runner.frame(t, sink);
  }
  if (result.ending === "faulted" || result.ending === "refused") log.push(`js: ${result.why}`);
  const code = result.ending === "frame" || result.ending === "done" ? 0 : 1;
  return log.map((l) => l + "\n").join("") + `[exit ${code}]\n`;
}

const goldens = readFileSync(join(canvasDir, "goldens.txt"), "utf8").trim().split("\n");
for (const entry of goldens) {
  const [name, frames, keys = "", clickText = ""] = entry.split(" ");
  const clicks = clickText === "" ? [] : clickText.split(",").map((c) => c.split(":").map(Number));
  const want = readFileSync(join(canvasDir, `${name}.log`), "utf8");
  const got = recorded(readFileSync(join(canvasDir, `${name}.js`), "utf8"), Number(frames), (keys === "-" ? "" : keys).split(","), clicks);
  if (got !== want) {
    const a = want.split("\n");
    const b = got.split("\n");
    let i = 0;
    while (i < a.length && a[i] === b[i]) i++;
    fail(`canvas ${name}: line ${i + 1}: the log \`${a[i]}\`, the page \`${b[i]}\``);
  }
}

// ── the page itself, on a stand-in document ───────────────────────────────

class Element {
  constructor(tag) {
    this.tag = tag; this.children = []; this.listeners = {}; this.textContent = ""; this.value = ""; this.className = "";
    this.scrollTop = 0; this.scrollHeight = 0;
  }
  appendChild(c) { this.children.push(c); return c; }
  addEventListener(kind, fn) { (this.listeners[kind] ??= []).push(fn); }
  fire(kind, event = {}) { for (const fn of this.listeners[kind] ?? []) fn(event); }
  focus() {}
  getBoundingClientRect() { return { left: 0, top: 0, width: 400, height: 400 }; }
  getContext() {
    const calls = [];
    this.calls = calls;
    const ctx = { fillStyle: "", strokeStyle: "", lineWidth: 1, font: "" };
    for (const m of ["fillRect", "beginPath", "moveTo", "lineTo", "closePath", "arc", "ellipse", "rect", "fill", "stroke", "fillText"]) {
      ctx[m] = (...args) => calls.push(`${m} ${args.join(" ")}`);
    }
    return ctx;
  }
}
globalThis.window = { JS_PAGE_CHECK: true };
globalThis.document = { head: new Element("head"), body: new Element("body"), createElement: (t) => new Element(t) };
const frames = [];
const env = { setTimeout: (f) => f(), requestAnimationFrame: (f) => frames.push(f) };
const settled = () => new Promise((done) => setImmediate(done));

const { buildPage, SAMPLES } = await import(pathToFileURL(join(dir, "js_page.js")).href);
const page = buildPage(runner, env);
if (SAMPLES.length < goldens.length + 2) fail(`the page offers ${SAMPLES.length} samples`);

async function runSample(index, speed) {
  page.picker.value = String(index);
  page.picker.fire("change");
  page.speed.value = String(speed);
  frames.length = 0;
  page.canvas.calls.length = 0;
  await page.runNow();
  for (let k = 0; k < 3 && frames.length > 0; k++) {
    frames.shift()(1e12 + k * 1000);
    await settled();
  }
  return { said: page.status.textContent, calls: [...page.canvas.calls], printed: page.output.textContent };
}

let looped = 0;
for (let i = 0; i < SAMPLES.length; i++) {
  const s = SAMPLES[i];
  const r = await runSample(i, 0);
  const wantRefused = s.title === "Outside the subset";
  // A sample that waits for frames: a frame loop, a click handler or a timer.
  const loops = /function frame\(|onClick\(|setTimeout\(|setInterval\(/.test(s.source);
  if (wantRefused !== r.said.startsWith("refused")) fail(`sample ${s.title}: the status says \`${r.said}\``);
  else if (!wantRefused && loops && r.said !== "frame 3") fail(`sample ${s.title}: after three frames the status says \`${r.said}\``);
  else if (!wantRefused && !loops && r.said !== "ran to its end") fail(`sample ${s.title}: the status says \`${r.said}\``);
  if (r.printed === "" && r.calls.length <= 1) fail(`sample ${s.title}: the page printed nothing and drew nothing`);
  if (loops) looped++;
}

const spiral = SAMPLES.findIndex((s) => /forward\(/.test(s.source));
if (spiral < 0) fail("no sample walks the turtle");
else {
  const fast = await runSample(spiral, 0);
  const slow = await runSample(spiral, 1);
  for (let k = 0; k < 400 && page.status.textContent === "running"; k++) await settled();
  const slowCalls = [...page.canvas.calls];
  if (slow.said === "running" && page.status.textContent !== fast.said) fail(`slow motion: the status says \`${page.status.textContent}\``);
  if (slowCalls.join("\n") !== fast.calls.join("\n")) fail(`slow motion painted ${slowCalls.length} calls, full speed ${fast.calls.length}`);
  if (page.output.textContent !== fast.printed) fail(`slow motion printed \`${page.output.textContent}\`, full speed \`${fast.printed}\``);
}

const total = programs.length + refused.length + goldens.length + SAMPLES.length + 1;
if (failures > 0) { console.error(`page_check: ${failures} of ${total} failed`); process.exit(1); }
console.log(`page_check: ${programs.length} programs print what node prints, ${refused.length} refused, ${goldens.length} canvas samples match their logs, ${SAMPLES.length} samples run on the page (${looped} three frames on), slow motion paints and prints what full speed does`);
