// js_page -- the JavaScript playground: an editor, a canvas the program draws
// on, and what it logs. Everything the page shows, its styles included, is
// made here, so the HTML is only a door.
//
// **THE PROGRAM DRAWS AS IT RUNS.** Each effect reaches `show` while the
// program is still running (js_runner.js) and is painted at once; the
// browser shows the canvas when the frame's call returns.
//
// The frame loop calls `frame(t)` about 30 times a second, `t` being the
// frame's number over 30, so a frame's `t` is the same on the page and in
// the recording host's logs (js/canvas/*.log). Each call is a tick of the
// program's clock, on which its timers run, and its clicks: a click on the
// canvas is queued at once and runs in the next frame. Pause works between
// frames.

import { loadRunner, unescaped } from "./js_runner.3cb6ca5e735cb7cd.js";
import { makePainter, SIZE } from "./js_painter.199dc8d08b3a2d42.js";
import { CANVAS_SAMPLES, CONSOLE_SAMPLES, FEATURED_SAMPLES } from "./js_samples.4ca337d6b2e67406.js";
import { memoryView, MEMORY_CSS, STRATEGY } from "./js_memory.751aa2b79bd604b7.js";

const FRAMES_PER_SECOND = 30;
const OUTPUT_KEPT = 20000;

// A console sample draws nothing, so the page hides the canvas for it and its
// output sits at the top of the column. "all features", "garbage
// collection" and "classes" (js/tests/54-big-daddy.js, 55-garbage.js and
// 61-classes-tour.js, written into js_samples.js by js/build.shale) come
// second to fourth, after the first canvas sample, which the page opens with.
const asConsole = (s) => ({ ...s, console: true });
export const SAMPLES = [
  CANVAS_SAMPLES[0],
  ...FEATURED_SAMPLES.map(asConsole),
  ...CANVAS_SAMPLES.slice(1),
  ...CONSOLE_SAMPLES.map(asConsole),
];

const BUILTINS = [
  ["background(color)", "fills the whole canvas with a color"],
  ["fill(color), noFill()", "what shapes and text are filled with, or no filling"],
  ["stroke(color, width), noStroke()", "what shapes are outlined with (width 1 unless given), or no outline"],
  ["line(x1, y1, x2, y2)", "a line, in the stroke"],
  ["rect(x, y, w, h)", "a rectangle from its top left corner"],
  ["circle(x, y, r), ellipse(x, y, rx, ry)", "from the center, by radius"],
  ["polygon([[x, y], ...])", "three or more corners, closed"],
  ["text(words, x, y, size)", "words in the fill, size 16 unless given"],
  ["forward(n), back(n), turn(degrees)", "the turtle walks, drawing a line in the stroke; turn is clockwise"],
  ["penUp(), penDown(), goto(x, y)", "the turtle starts in the middle, facing up, its pen down"],
  ["mouseX(), mouseY(), keyIsDown(key)", "read when called; a key by its name, such as \"ArrowLeft\""],
  ["onClick((x, y) => { ... })", "called with each click on the canvas, at the next frame, in canvas units"],
  ["onCollect(({ cells, live, before }) => { ... })", "called after each garbage collection, between instructions, with the heap's cells, those found live and those in use before"],
  ["setTimeout(f, ms), setInterval(f, ms)", "JavaScript's own: f called once after ms, or every ms; each answers a timer"],
  ["clearTimeout(timer), clearInterval(timer)", "the timer stops"],
  ["function frame(t) { ... }", "if the program declares it, called 30 times a second, t in seconds"],
];

// What of JavaScript the interpreter runs; js/README.md, "The subset", has
// it whole.
const LANGUAGE = [
  ["let, const, if, while, do ... while, for, for ... of, switch", "for ... of over arrays, strings, Maps, Sets and their iterators; labelled break and continue"],
  ["throw, try, catch, finally", "any value thrown; the interpreter's own TypeErrors and ReferenceErrors are caught the same way"],
  ["[a, , ...rest] = xs, { x, y: why = 2, ...others } = o", "destructuring in declarations, assignments, parameters and for ... of; default and rest parameters"],
  ["{ ...o }, a?.b, a?.[k], f?.(), ??=, ||=, &&=", "object spread, optional chaining and the logical assignments"],
  ["new Map(), new Set(), new Error(message)", "with get, set, add, has, delete, size, forEach, keys, values and entries"],
  ["Math, Object.keys, Array.from, and the methods of arrays and strings", "map, filter, reduce, splice, flat, at, split, replace and the rest"],
  ["not this, new on your own functions, classes, ==, var or regular expressions", "each refused by name, never run wrong"],
];

const CSS = `
  :root { color-scheme: light dark; --ink: #1b1b1b; --dim: #6a6a6a; --line: #d8d4cc; --paper: #faf8f4; --bad: #a33a1f; --go: #2f6f4f; }
  @media (prefers-color-scheme: dark) {
    :root { --ink: #e8e6e1; --dim: #9a968e; --line: #3a3833; --paper: #1a1917; --bad: #e08a6c; --go: #2f7d56; }
  }
  body { margin: 0; background: var(--paper); color: var(--ink);
         font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
  .wrap { max-width: 1000px; margin: 0 auto; padding: 0 16px 28px; }
  .top { padding: 28px 0 16px; box-sizing: border-box; }
  h1 { font-size: 20px; margin: 0 0 4px; font-weight: 600; }
  h2 { font-size: 15px; margin: 24px 0 6px; font-weight: 600; }
  .sub { color: var(--dim); font-size: 13px; margin: 0 0 20px; }
  .bar { display: flex; gap: 10px; align-items: center; margin: 0 0 10px; flex-wrap: wrap; }
  button, select { font: inherit; font-size: 14px; color: inherit; background: transparent;
                   border: 1px solid var(--ink); border-radius: 4px; padding: 5px 14px; }
  select { max-width: 100%; }
  button:hover { background: var(--ink); color: var(--paper); }
  button.primary { background: var(--go); border-color: var(--go); color: #fff; font-weight: 600; padding: 5px 22px; }
  button.primary:hover { background: var(--ink); border-color: var(--ink); color: var(--paper); }
  .cols { display: flex; gap: 18px; flex-wrap: wrap; }
  .col { flex: 1 1 380px; min-width: 0; }
  label { display: block; font-size: 12px; text-transform: uppercase; letter-spacing: .06em;
          color: var(--dim); margin: 0 0 6px; }
  textarea, pre { width: 100%; box-sizing: border-box; background: transparent; color: inherit;
                  border: 1px solid var(--line); border-radius: 4px; padding: 10px; margin: 0;
                  font: 13px/1.45 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
  textarea { height: 560px; height: min(560px, 60vh); height: min(560px, 60dvh); resize: vertical; }
  pre { height: 130px; overflow: auto; white-space: pre; margin-top: 10px; }
  pre.console { height: 70vh; height: 70dvh; min-height: 260px; }
  .waiting, label, canvas { flex: none; }
  /* Side by side, the columns fill the screen below the bar: the editor all
     of its column, the console whatever the canvas leaves (all of it for a
     console sample), so output scrolls in its box only once it outgrows the
     screen. Stacked, on a phone, each is sized by the screen's height. The
     header above never changes height, so the canvas stays where clicks aim. */
  @media (min-width: 820px) {
    .top { display: flex; flex-direction: column; min-height: 100vh; min-height: 100dvh; }
    .cols { flex: 1 1 0; flex-wrap: nowrap; }
    .col { display: flex; flex-direction: column; min-height: 0; }
    textarea { flex: 1 1 0; height: 0; min-height: 240px; }
    pre, pre.console { flex: 1 1 0; height: 0; min-height: 130px; }
    pre.console { margin-top: 0; }
  }
  canvas { display: block; width: 100%; max-width: ${SIZE}px; aspect-ratio: 1; border: 1px solid var(--line);
           border-radius: 4px; touch-action: none; }
  canvas:focus { outline: 2px solid var(--dim); outline-offset: 2px; }
  canvas[hidden] { display: none; }
  .status { color: var(--dim); font-size: 13px; flex-basis: 100%; min-height: 1.5em; }
  .status.bad { color: var(--bad); }
  .waiting { margin: 0; padding: 18px 16px; border: 1px dashed var(--line); border-radius: 4px; color: var(--dim); }
  .waiting[hidden], label[hidden], pre[hidden] { display: none; }
  dl { display: grid; grid-template-columns: minmax(0, max-content) minmax(0, 1fr); gap: 4px 16px; margin: 0; font-size: 14px; }
  dt { font: 13px/1.5 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; overflow-wrap: anywhere; }
  dd { margin: 0; color: var(--dim); }
  .note { color: var(--dim); font-size: 13px; margin: 10px 0 0; }
  @media (max-width: 560px) { dl { grid-template-columns: 1fr; } dd { margin-bottom: 6px; } }
`;

function element(tag, props = {}, children = []) {
  const e = document.createElement(tag);
  Object.assign(e, props);
  for (const c of children) e.appendChild(c);
  return e;
}

export function buildPage(runner, env = window) {
  document.head.appendChild(element("style", { textContent: CSS + MEMORY_CSS }));
  const picker = element("select", {}, SAMPLES.map((s, i) => element("option", { value: String(i), textContent: s.title })));
  const runButton = element("button", { textContent: "Run", className: "primary" });
  const stopButton = element("button", { textContent: "Stop" });
  const pauseButton = element("button", { textContent: "Pause" });
  const memoryLink = element("button", { className: "link", textContent: "memory", title: "what the last run's heap held, and how the VM collects it" });
  const status = element("span", { className: "status", textContent: "" });
  const editor = element("textarea", { spellcheck: false, value: SAMPLES[0].source });
  const canvas = element("canvas", { width: SIZE, height: SIZE, tabIndex: 0 });
  const output = element("pre", { textContent: "" });
  const canvasLabel = element("label", { textContent: "Canvas, 400 by 400" });
  const waiting = element("p", { className: "waiting", textContent: "This program hasn't run yet. Press Run to start it." });
  const wrap = element("div", { className: "wrap" }, [
    element("div", { className: "top" }, [
      element("h1", { textContent: "JavaScript, in Roc" }),
      element("p", { className: "sub", textContent: "A subset of JavaScript run by a bytecode VM written in Roc. Its console.log prints what node prints; the canvas builtins below are this page's own, named after p5.js's but not p5.js." }),
      element("div", { className: "bar" }, [picker, runButton, stopButton, pauseButton, memoryLink, status]),
      element("div", { className: "cols" }, [
        element("div", { className: "col" }, [element("label", { textContent: "Program" }), editor]),
        element("div", { className: "col" }, [waiting, canvasLabel, canvas, output]),
      ]),
    ]),
    element("h2", { textContent: "The JavaScript it runs" }),
    element("dl", {}, LANGUAGE.flatMap(([what, more]) => [element("dt", { textContent: what }), element("dd", { textContent: more })])),
    element("h2", { textContent: "The canvas builtins" }),
    element("dl", {}, BUILTINS.flatMap(([call, what]) => [element("dt", { textContent: call }), element("dd", { textContent: what })])),
    element("p", { className: "note", textContent: "Colors are CSS color strings (\"tomato\", \"#3a7\", \"hsl(200, 70%, 45%)\"). The origin is the top left corner. A run may take 3,000,000 steps and 20,000 effects before its first frame, and each frame, with the clicks and timers it runs, 300,000 steps and 20,000 effects." }),
  ]);
  document.body.appendChild(wrap);

  // **THE MEMORY VIEW** is a popup over the page, opened by the "memory"
  // link: the last run's timeline (js_runner.js's `memory`), drawn again at
  // the end of each call while it is open, and the strategy in a few
  // sentences. Escape, its Close button or a click outside it closes it.
  const memorySaid = element("p", { className: "said" });
  const cellsChart = element("div", { className: "chart" });
  const bytesChart = element("div", { className: "chart" });
  const closeButton = element("button", { textContent: "Close", className: "close" });
  const swatch = (kind, words) => element("span", {}, [element("i", { className: `swatch ${kind}` }), element("span", { textContent: words })]);
  const memoryPanel = element("div", { className: "memory" }, [
    closeButton,
    element("h2", { textContent: "Memory" }),
    memorySaid,
    element("label", { textContent: "The heap, in cells" }),
    cellsChart,
    element("p", { className: "key" }, [swatch("cells", "cells in use"), swatch("length", "the heap's length"), swatch("live", "live after a collection"), swatch("gc", "a collection")]),
    element("label", { textContent: "The wasm memory, in bytes" }),
    bytesChart,
    element("h2", { textContent: "How the VM keeps its memory" }),
    element("div", { className: "how" }, STRATEGY.map((s) => element("p", { textContent: s }))),
  ]);
  const veil = element("div", { className: "veil", hidden: true }, [memoryPanel]);
  document.body.appendChild(veil);
  // What the view calls the run it shows, or null before the page's first,
  // and when it was last drawn: a run on show is drawn at most four times a
  // second.
  let shownRun = null;
  let drawnAt = -Infinity;

  function drawMemory() {
    drawnAt = globalThis.performance.now();
    if (shownRun === null) {
      memorySaid.textContent = "No program has run yet. Run one, and this shows what its heap holds as it goes.";
      cellsChart.innerHTML = "";
      bytesChart.innerHTML = "";
      return;
    }
    const view = memoryView(runner.memory.points);
    memorySaid.textContent = `${shownRun}: ${view.summary}`;
    cellsChart.innerHTML = view.cells;
    bytesChart.innerHTML = view.bytes;
  }
  function openMemory() {
    drawMemory();
    veil.hidden = false;
    closeButton.focus();
  }
  function closeMemory() {
    veil.hidden = true;
  }
  memoryLink.addEventListener("click", openMemory);
  closeButton.addEventListener("click", closeMemory);
  veil.addEventListener("click", (e) => { if (e.target === veil) closeMemory(); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !veil.hidden) closeMemory(); });

  const ctx = canvas.getContext("2d");
  const painter = makePainter(ctx);
  painter.reset();

  // **NOTHING SHOWS UNTIL RUN.** Until the program in the editor has been
  // run, the column holds one line saying so, and no canvas or console: a
  // canvas that is there but blank looked like a program that had started
  // and ignored its clicks. Picking a sample or editing the program goes
  // back to that line; Run shows the canvas, or for a console sample the
  // console, and Stop leaves what was drawn in view.
  function showKindOf(sample) {
    waiting.hidden = true;
    canvasLabel.hidden = false;
    output.hidden = false;
    canvas.hidden = Boolean(sample.console);
    output.className = sample.console ? "console" : "";
    canvasLabel.textContent = sample.console ? "Console" : "Canvas, 400 by 400";
  }

  // The program in the editor as not yet run: the line, and nothing drawn.
  function notRun() {
    waiting.hidden = false;
    canvasLabel.hidden = true;
    canvas.hidden = true;
    output.hidden = true;
    output.textContent = "";
    painter.reset();
    say("", false);
  }
  notRun();

  // The input the program reads: the pointer over the canvas, in its own
  // 400-by-400 units, and the keys held while the canvas has the focus.
  const keys = new Set();
  let pointerX = SIZE / 2;
  let pointerY = SIZE / 2;
  runner.input.pointer = (axis) => (axis === 0 ? pointerX : pointerY);
  runner.input.key = (name) => keys.has(name);
  canvas.addEventListener("pointermove", (e) => {
    const box = canvas.getBoundingClientRect();
    pointerX = ((e.clientX - box.left) * SIZE) / box.width;
    pointerY = ((e.clientY - box.top) * SIZE) / box.height;
  });
  // A click goes to the run on show while it waits for frames; its handler
  // runs in the next frame.
  canvas.addEventListener("pointerdown", (e) => {
    if (!current || current.over) return;
    const box = canvas.getBoundingClientRect();
    runner.click(((e.clientX - box.left) * SIZE) / box.width, ((e.clientY - box.top) * SIZE) / box.height);
  });
  canvas.addEventListener("keydown", (e) => { keys.add(e.key); if (e.key.startsWith("Arrow") || e.key === " ") e.preventDefault(); });
  canvas.addEventListener("keyup", (e) => keys.delete(e.key));
  canvas.addEventListener("blur", () => keys.clear());

  // The run on show: its number (a stopped run's calls are let go), the
  // next frame's number, and whether it is paused.
  let current = null;

  function say(text, bad) {
    status.textContent = text;
    status.className = bad ? "status bad" : "status";
  }

  function log(text) {
    const all = output.textContent + text;
    output.textContent = all.length > OUTPUT_KEPT ? all.slice(all.length - OUTPUT_KEPT) : all;
    output.scrollTop = output.scrollHeight;
  }

  function show(line) {
    if (line.startsWith("log ")) log(unescaped(line.slice(4)) + "\n");
    else painter.paint(line);
  }

  function sinkFor(run) {
    return (line) => {
      if (run === current) show(line);
    };
  }

  async function settle(run, result) {
    if (run !== current) return;
    if (!veil.hidden && (result.ending !== "frame" || globalThis.performance.now() - drawnAt > 250)) drawMemory();
    const SAID = { done: "ran to its end", faulted: "stopped", thrown: "stopped by an uncaught throw", refused: "refused", crashed: "the interpreter crashed" };
    if (result.ending === "frame") {
      say(`frame ${run.frame}${run.paused ? ", paused" : ""}`, false);
      if (!run.paused) schedule(run);
      return;
    }
    if (result.ending === "thrown") log(`${result.why}\n`);
    else if (result.ending !== "done") log(`js: ${result.why}\n`);
    say(SAID[result.ending] ?? result.ending, result.ending !== "done");
    run.over = true;
  }

  // The next frame, at its time. Each schedule is a new loop, and an older
  // one still waiting for the browser lets itself go.
  function schedule(run) {
    run.loop += 1;
    const loop = run.loop;
    env.requestAnimationFrame((now) => tick(run, loop, now));
  }

  function tick(run, loop, now) {
    if (run !== current || run.paused || loop !== run.loop) return;
    if (now < run.due) { env.requestAnimationFrame((later) => tick(run, loop, later)); return; }
    run.due = Math.max(run.due + 1000 / FRAMES_PER_SECOND, now - 100);
    callFrame(run);
  }

  function callFrame(run) {
    const t = run.frame / FRAMES_PER_SECOND;
    run.frame += 1;
    settle(run, runner.frame(t, sinkFor(run)));
  }

  function runNow() {
    showKindOf(SAMPLES[Number(picker.value)]);
    output.textContent = "";
    painter.reset();
    const run = { frame: 0, paused: false, over: false, due: 0, loop: 0 };
    current = run;
    const sample = SAMPLES[Number(picker.value)];
    shownRun = editor.value === sample.source ? `The last run, “${sample.title}”` : "The last run, your program";
    pauseButton.textContent = "Pause";
    say("running", false);
    return settle(run, runner.start(editor.value, sinkFor(run)));
  }

  function stop() {
    if (current && !current.over) say("stopped by you", false);
    current = null;
  }

  runButton.addEventListener("click", () => { runNow(); canvas.focus(); });
  stopButton.addEventListener("click", stop);
  pauseButton.addEventListener("click", () => {
    const run = current;
    if (!run || run.over) return;
    run.paused = !run.paused;
    pauseButton.textContent = run.paused ? "Go on" : "Pause";
    say(`frame ${run.frame}${run.paused ? ", paused" : ""}`, false);
    if (!run.paused) schedule(run);
  });
  // A program is read from its top: setting a textarea's value leaves the
  // cursor at the end, and a browser scrolls the box to its cursor.
  function fromTheTop() {
    editor.setSelectionRange(0, 0);
    editor.scrollTop = 0;
  }
  picker.addEventListener("change", () => {
    stop();
    editor.value = SAMPLES[Number(picker.value)].source;
    fromTheTop();
    notRun();
  });
  fromTheTop();
  // An edited program hasn't run either, so the run on show stops with it.
  editor.addEventListener("input", () => {
    stop();
    notRun();
  });
  return { picker, runButton, stopButton, pauseButton, status, editor, canvas, output, waiting, canvasLabel, runNow, memoryLink, veil, closeButton, memorySaid, cellsChart, bytesChart };
}

if (typeof window !== "undefined" && !window.JS_PAGE_CHECK) {
  const bytes = await (await fetch("js.592f01801d8fdb43.wasm")).arrayBuffer();
  buildPage(await loadRunner(bytes));
}
