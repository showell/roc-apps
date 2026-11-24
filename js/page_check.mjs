// page_check -- the JavaScript playground's page, run with no browser.
//
//   node js/page_check.mjs <build-dir> <tests-dir> <canvas-dir>
//
// It finds the page's files as a browser does, by their hashed names
// (js/build.shale names each by its bytes): index.html's module script,
// then the runner and the wasm that script names. Every file a page file
// names (a module's `./` import, the wasm it fetches, the HTML's script)
// must be in <build-dir>. It loads the wasm through the page's own
// js_runner.js and:
//
// - runs every program in <tests-dir> through it, each held to what node
//   itself prints for it (the program run by node, its timers waited for
//   until none is left), node's report of a throw nothing caught written as
//   the one line js-vm writes, as js/oracle.shale writes it;
// - holds each program in <tests-dir>/refused to the message its first line
//   names, but for one js-vm stops on its budget of timer callbacks: the
//   page has no such budget (an interval may animate for good), so that one
//   must still be running after its ticks, as it would be in node;
// - ticks each program's clock a frame at a time, as the page does, until
//   it ends or `MOST_TICKS` have run, so its timers run;
// - runs each canvas sample <canvas-dir>/goldens.txt names, as js-canvas
//   does (its reads answered and logged as js-canvas answers and logs them,
//   its clicks queued before their frames), and holds the wasm's lines to the
//   sample's golden log, byte for byte;
// - builds the page itself, js_page.js, on a stand-in document and canvas,
//   runs every sample, and calls three frames of each that has a frame
//   loop;
// - holds the page's column to its flow: on load, on a pick and after an
//   edit, only the line saying the program hasn't run; on Run, the canvas
//   (or a console sample's console); after Stop, the drawing still in view;
// - holds the memory view to its flow: the "memory" link opens it, saying
//   before any run that none has run; Escape, its Close button and a click
//   outside it close it, a click inside doesn't; every sample's run records
//   points the view draws, and a program that collects shows each collection
//   as a mark where its cells in use drop, from what was in use before it to
//   what it found live.
import { spawnSync } from "node:child_process";
import { readFileSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [dir, tests, canvasDir] = process.argv.slice(2);
if (!dir || !tests || !canvasDir) {
  console.error("usage: node js/page_check.mjs <build-dir> <tests-dir> <canvas-dir>");
  process.exit(2);
}

let failures = 0;
function fail(why) { failures++; console.error(`page_check: FAIL ${why}`); }

// Each name a page file gives another: the HTML's module script, a
// module's `./` imports and the wasm it fetches.
function namedIn(file) {
  const text = readFileSync(join(dir, file), "utf8");
  const pattern = file.endsWith(".html") ? /<script type="module" src="([^"]+)"/g : /from "\.\/([^"]+)"|fetch\("([^"]+)"\)/g;
  return [...text.matchAll(pattern)].map((m) => m[1] ?? m[2]);
}
const built = new Set(readdirSync(dir));
const named = new Map();
for (let queue = ["index.html"]; queue.length > 0;) {
  const file = queue.shift();
  if (named.has(file)) continue;
  if (!built.has(file)) { fail(`the page names ${file}, which the build doesn't hold`); named.set(file, []); continue; }
  named.set(file, file.endsWith(".wasm") ? [] : namedIn(file));
  queue.push(...named.get(file));
}
for (const f of built) {
  if (!named.has(f)) fail(`the build holds ${f}, which the page never names`);
  else if (f !== "index.html" && !/\.[0-9a-f]{16}\.(js|wasm)$/.test(f)) fail(`${f} isn't named by its bytes`);
}
const pageFile = named.get("index.html")[0];
const runnerFile = named.get(pageFile).find((f) => f.startsWith("js_runner."));
const wasmFile = named.get(pageFile).find((f) => f.endsWith(".wasm"));
if (failures > 0 || !runnerFile || !wasmFile) { console.error("page_check: the page's files don't link up"); process.exit(1); }

const { loadRunner, transcriptOf } = await import(pathToFileURL(join(dir, runnerFile)).href);
const runner = await loadRunner(readFileSync(join(dir, wasmFile)));

// What node prints for a program, run as node runs a file, its timers on
// node's own clock until none is left. Its report of a throw nothing caught,
// on stderr (`<path>:<n>`, the line, a caret, then what was thrown past a
// blank line when it is an error, and the stack), is the one line js-vm
// writes: `Uncaught <the first line of what was thrown> (line <n>)`.
function nodeOutput(file) {
  const path = resolve(file);
  const r = spawnSync(process.execPath, [path], { encoding: "utf8" });
  const report = r.stderr.split("\n");
  const start = report.findIndex((l) => l.startsWith(`${path}:`) && /^\d+$/.test(l.slice(path.length + 1)));
  if (start < 0) return r.stdout;
  const thrown = report.slice(start + 3).find((l) => l !== "") ?? "";
  return `${r.stdout}Uncaught ${thrown} (line ${report[start].slice(path.length + 1)})\n`;
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
  const want = nodeOutput(join(tests, f));
  const got = runWhole(src);
  if (!["done", "thrown"].includes(got.result.ending)) fail(`${f}: the page's run ended ${got.result.ending}: ${got.result.why}`);
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
    this.scrollTop = 0; this.scrollHeight = 0; this.hidden = false;
    this.selectionStart = 0; this.selectionEnd = 0;
  }
  setSelectionRange(start, end) { this.selectionStart = start; this.selectionEnd = end; }
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
globalThis.document = Object.assign(new Element("document"), { head: new Element("head"), body: new Element("body"), createElement: (t) => new Element(t) });
const frames = [];
const env = { setTimeout: (f) => f(), requestAnimationFrame: (f) => frames.push(f) };
const settled = () => new Promise((done) => setImmediate(done));

const { buildPage, SAMPLES } = await import(pathToFileURL(join(dir, pageFile)).href);
const page = buildPage(runner, env);
if (SAMPLES.length < goldens.length + 2) fail(`the page offers ${SAMPLES.length} samples`);

// What the column shows: the not-yet-run line alone, or the canvas (a
// canvas sample's, with its console under it) or the console.
function shown() {
  if (!page.waiting.hidden) return page.canvasLabel.hidden && page.canvas.hidden && page.output.hidden ? "not run" : "the line beside the run";
  if (page.canvasLabel.hidden || page.output.hidden) return "neither";
  return page.canvas.hidden ? "console" : "canvas";
}
if (shown() !== "not run") fail(`on load the page shows ${shown()}, where it must say the program hasn't run`);

// The memory view before any run: it opens, says so, and each way to close
// it closes it.
const memoryOpen = () => !page.veil.hidden;
if (page.memoryLink.textContent !== "memory") fail(`the memory link says \`${page.memoryLink.textContent}\``);
if (memoryOpen()) fail("the memory view is open on load");
page.memoryLink.fire("click");
if (!memoryOpen()) fail("the memory link doesn't open the memory view");
if (!page.memorySaid.textContent.startsWith("No program has run yet")) fail(`before any run the memory view says \`${page.memorySaid.textContent}\``);
if (page.cellsChart.innerHTML !== "") fail("before any run the memory view draws a chart");
document.fire("keydown", { key: "Escape" });
if (memoryOpen()) fail("Escape doesn't close the memory view");
page.memoryLink.fire("click");
page.veil.fire("click", { target: page.veil.children[0] });
if (!memoryOpen()) fail("a click inside the memory view closes it");
page.veil.fire("click", { target: page.veil });
if (memoryOpen()) fail("a click outside the memory view doesn't close it");
page.memoryLink.fire("click");
page.closeButton.fire("click");
if (memoryOpen()) fail("the memory view's Close doesn't close it");
let memoryChecks = 0;

async function runSample(index) {
  page.editor.scrollTop = 500;
  page.editor.selectionStart = page.editor.selectionEnd = 9999;
  page.picker.value = String(index);
  page.picker.fire("change");
  if (page.editor.scrollTop !== 0 || page.editor.selectionStart !== 0 || page.editor.selectionEnd !== 0) {
    fail(`sample ${SAMPLES[index].title}: once picked the program isn't shown from its top`);
  }
  if (shown() !== "not run") fail(`sample ${SAMPLES[index].title}: once picked the page shows ${shown()}`);
  frames.length = 0;
  page.canvas.calls.length = 0;
  const running = page.runNow();
  const want = SAMPLES[index].console ? "console" : "canvas";
  if (shown() !== want) fail(`sample ${SAMPLES[index].title}: on Run the page shows ${shown()}, not the ${want}`);
  await running;
  for (let k = 0; k < 3 && frames.length > 0; k++) {
    frames.shift()(1e12 + k * 1000);
    await settled();
  }
  return { said: page.status.textContent, calls: [...page.canvas.calls], printed: page.output.textContent };
}

let looped = 0;
for (let i = 0; i < SAMPLES.length; i++) {
  const s = SAMPLES[i];
  const r = await runSample(i);
  const wantRefused = s.title === "Outside the subset";
  // A sample that waits for frames: a frame loop, a click handler or a timer.
  const loops = /function frame\(|onClick\(|setTimeout\(|setInterval\(/.test(s.source);
  if (wantRefused !== r.said.startsWith("refused")) fail(`sample ${s.title}: the status says \`${r.said}\``);
  else if (!wantRefused && loops && r.said !== "frame 3") fail(`sample ${s.title}: after three frames the status says \`${r.said}\``);
  else if (!wantRefused && !loops && r.said !== "ran to its end") fail(`sample ${s.title}: the status says \`${r.said}\``);
  if (r.printed === "" && r.calls.length <= 1) fail(`sample ${s.title}: the page printed nothing and drew nothing`);
  if (loops) looped++;
  // Its run's memory: points with the heap's cells, drawn when the view opens.
  if (!wantRefused) {
    const cellsKept = runner.memory.points.filter((p) => p.cells !== null).length;
    page.memoryLink.fire("click");
    if (cellsKept === 0 || !page.cellsChart.innerHTML.includes("<polyline") || !page.bytesChart.innerHTML.includes("<polyline")) {
      fail(`sample ${s.title}: its run kept ${cellsKept} points of the heap, and the memory view drew ${page.cellsChart.innerHTML.length} bytes of chart`);
    }
    if (!page.memorySaid.textContent.startsWith(`The last run, “${s.title}”: `)) fail(`sample ${s.title}: the memory view says \`${page.memorySaid.textContent}\``);
    page.closeButton.fire("click");
    memoryChecks++;
  }
}

// Stop leaves the drawing in view; an edit goes back to the line.
{
  const r = await runSample(0);
  page.stopButton.fire("click");
  if (shown() !== "canvas" || page.canvas.calls.length !== r.calls.length) fail(`after Stop the page shows ${shown()}, ${page.canvas.calls.length} calls of ${r.calls.length}`);
  page.editor.value += "\n";
  page.editor.fire("input");
  if (shown() !== "not run" || page.status.textContent !== "") fail(`after an edit the page shows ${shown()}, status \`${page.status.textContent}\``);
}

// A program that collects: the view counts its collections, marks each, and
// draws a dot for what each found live.
{
  const collecting = "51-collector-roots.js";
  page.editor.value = readFileSync(join(tests, collecting), "utf8");
  page.editor.fire("input");
  await page.runNow();
  for (let k = 0; k < 300 && frames.length > 0; k++) {
    frames.shift()(1e12 + k * 1000);
    await settled();
  }
  page.memoryLink.fire("click");
  const marks = (page.cellsChart.innerHTML.match(/class="gc"/g) ?? []).length;
  const dots = (page.cellsChart.innerHTML.match(/class="live"/g) ?? []).length;
  const counted = runner.memory.points.reduce((n, p) => n + p.collections, 0);
  if (counted === 0 || marks === 0 || dots !== marks) fail(`${collecting}: ${counted} collections recorded, ${marks} marked and ${dots} live dots drawn`);
  // Each collection's point drops: in use just before it above what it kept,
  // and the in-use line drawn through both, beside the heap's length.
  const teeth = runner.memory.points.filter((p) => p.collections > 0);
  const dropped = teeth.filter((p) => p.peak > p.inUse && p.inUse === p.live).length;
  const drawn = /<polyline class="cells( dense)?" points="([^"]*)"/.exec(page.cellsChart.innerHTML);
  const vertices = drawn ? drawn[2].split(" ").length : 0;
  const sampledCount = runner.memory.points.filter((p) => p.cells !== null).length;
  if (dropped !== teeth.length || vertices !== sampledCount + teeth.length || !page.cellsChart.innerHTML.includes('class="length"')) {
    fail(`${collecting}: ${dropped} of ${teeth.length} collections drop their cells in use, and the in-use line has ${vertices} vertices for ${sampledCount} points`);
  }
  if (!page.memorySaid.textContent.startsWith("The last run, your program: ")) fail(`${collecting}: the memory view says \`${page.memorySaid.textContent}\``);
  page.closeButton.fire("click");
  memoryChecks++;
  console.log(`page_check: ${collecting} on the page: ${page.memorySaid.textContent}`);
}

const total = programs.length + refused.length + goldens.length + SAMPLES.length + 3;
if (failures > 0) { console.error(`page_check: ${failures} of ${total} failed`); process.exit(1); }
console.log(`page_check: ${named.size} files, each linked and named by its bytes; ${programs.length} programs print what node prints, ${refused.length} refused, ${goldens.length} canvas samples match their logs, ${SAMPLES.length} samples run on the page (${looped} three frames on), each shown from its top, nothing shows before Run and Stop keeps the drawing; the memory view opens and closes each way, and ${memoryChecks} runs drew their memory, collections marked`);
