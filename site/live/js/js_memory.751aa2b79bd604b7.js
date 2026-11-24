// js_memory -- the playground's memory view: what the last run's heap held
// over time, drawn as two small SVG charts, and the memory strategy in a few
// sentences. The points are js_runner.js's `memory.points`; js_page.js opens
// the view in a popup from its "memory" link.
//
// The top chart is the heap's cells in use, those not on the free list,
// which climb as the program allocates and drop at each collection: a
// sawtooth, each tooth's top the cells in use just before a collection and
// its foot, a dot, what the collection found live, under a mark. A fainter
// line is the heap's length, the VM's list of cells, the freed ones
// included, which never falls. The bottom chart is the wasm memory's real
// size, which only grows.

// The strategy, each sentence true of js/roc/Collector.roc, Heap.roc and
// Vm.roc, and of js/wasm/host.zig.
export const STRATEGY = [
  "Every value a program shares by reference, an object, an array, a closure, a Map or a Set, a captured variable, lives in one Roc list of cells, the heap, and a JavaScript reference is a cell's index.",
  "A collection is a mark and sweep that moves nothing: it runs between two instructions, where every value the program holds is in the machine, and marks each cell its roots reach (the operand stack, the builtins, a throw in flight and the event queue's callbacks).",
  "The sweep turns each cell left unmarked into a link of a free list, and the next allocations take their cells from that list before the heap grows.",
  "A collection is due once no cell is free and the heap holds twice the cells the last collection kept, and never fewer than 1,024, so a cell costs amortized constant time.",
  "A freed cell keeps its place, so no reference ever moves, and the heap's length, the faint line in the top chart, never falls; the cells in use, the heap less its free list, climb as the program allocates and drop at each collection to the dot, what it found live.",
  "Roc's own lists and strings come from the wasm host's allocator, which reuses what Roc frees, and the wasm memory under it, the bottom chart, only grows: WebAssembly can't give memory back.",
  "The page takes a point at each collection, the cells in use just before it and just after, and at the end of each call into the program: its run, then each frame.",
];

const WIDTH = 960;
const LEFT = 72;
const RIGHT = 20;
const TOP = 14;
const BOTTOM = 30;

const number = (n) => Math.round(n).toLocaleString("en-US");

// The smallest round number at or above `n`, a power of ten times one of
// a few steps, whose quarters are round too.
function niceAbove(n) {
  if (n <= 0) return 1;
  const ten = 10 ** Math.floor(Math.log10(n));
  for (const m of [1, 1.2, 1.6, 2, 2.4, 3, 4, 5, 6, 8, 10]) if (m * ten >= n) return m * ten;
  return 10 * ten;
}

function timeText(ms) {
  return ms < 1000 ? `${number(ms)} ms` : `${(ms / 1000).toFixed(ms < 10000 ? 1 : 0)} s`;
}

function bytesText(bytes) {
  const mb = bytes / (1024 * 1024);
  return `${Number.isInteger(mb) ? mb : mb.toFixed(1)} MB`;
}

// One chart's frame: its axes, gridlines and labels, and the scales that
// place a point on it.
function frameOf({ height, xMax, yMax, yLabel }) {
  const plotW = WIDTH - LEFT - RIGHT;
  const plotH = height - TOP - BOTTOM;
  const x = (ms) => LEFT + (ms / xMax) * plotW;
  const y = (v) => TOP + plotH - (v / yMax) * plotH;
  const parts = [];
  for (let i = 0; i <= 4; i++) {
    const v = (yMax * i) / 4;
    parts.push(`<line class="grid" x1="${LEFT}" x2="${WIDTH - RIGHT}" y1="${y(v)}" y2="${y(v)}"/>`);
    parts.push(`<text class="tick" x="${LEFT - 8}" y="${y(v) + 4}" text-anchor="end">${yLabel(v)}</text>`);
  }
  for (let i = 0; i <= 5; i++) {
    const ms = (xMax * i) / 5;
    parts.push(`<text class="tick" x="${x(ms)}" y="${height - 8}" text-anchor="${i === 0 ? "start" : i === 5 ? "end" : "middle"}">${timeText(ms)}</text>`);
  }
  parts.push(`<line class="axis" x1="${LEFT}" x2="${WIDTH - RIGHT}" y1="${y(0)}" y2="${y(0)}"/>`);
  return { x, y, parts, top: TOP, bottom: TOP + plotH };
}

function svg(height, label, parts) {
  return `<svg viewBox="0 0 ${WIDTH} ${height}" role="img" aria-label="${label}">${parts.join("")}</svg>`;
}

// The view of a run's points: a summary line, the charts' SVG, and how many
// collections they mark.
export function memoryView(points) {
  const sampled = points.filter((p) => p.cells !== null);
  if (sampled.length === 0) {
    return { summary: "The last run ended before its heap was sampled: the program was refused, or the interpreter stopped, before any of it ran.", cells: "", bytes: "", collections: 0, drops: 0 };
  }
  const xMax = Math.max(1, ...points.map((p) => p.ms));
  const peak = Math.max(...sampled.map((p) => p.cells));
  const collections = points.reduce((n, p) => n + p.collections, 0);
  const lastLive = [...points].reverse().find((p) => p.live !== null);

  const top = frameOf({ height: 300, xMax, yMax: niceAbove(peak), yLabel: number });
  const collected = points.filter((p) => p.collections > 0);
  // Past a hundred, each mark is a short tick along the chart's top and each
  // dot smaller, so a run that collects often still shows its teeth.
  const dense = collected.length > 100;
  const markEnd = dense ? top.top + 10 : top.bottom;
  const marks = collected.map((p) => `<line class="gc" x1="${top.x(p.ms)}" x2="${top.x(p.ms)}" y1="${top.top}" y2="${markEnd}"/>`);
  const at = (ms, v) => `${top.x(ms).toFixed(1)},${top.y(v).toFixed(1)}`;
  const length = sampled.map((p) => at(p.ms, p.cells)).join(" ");
  // A collection's point climbs to what was in use before it, then drops.
  const inUse = sampled.flatMap((p) => (p.peak === null ? [at(p.ms, p.inUse)] : [at(p.ms, p.peak), at(p.ms, p.inUse)])).join(" ");
  const area = `${top.x(sampled[0].ms).toFixed(1)},${top.y(0)} ${inUse} ${top.x(sampled[sampled.length - 1].ms).toFixed(1)},${top.y(0)}`;
  const drops = sampled.filter((p) => p.peak !== null && p.peak > p.inUse).length;
  const dots = points.filter((p) => p.live !== null).map((p) => `<circle class="live" cx="${top.x(p.ms).toFixed(1)}" cy="${top.y(p.live).toFixed(1)}" r="${dense ? 2 : 3.5}"/>`);
  const cells = svg(300, "the heap's cells over the run", [
    ...top.parts,
    ...marks,
    `<polyline class="length" points="${length}"/>`,
    `<polygon class="cells-area" points="${area}"/>`,
    `<polyline class="${dense ? "cells dense" : "cells"}" points="${inUse}"/>`,
    ...dots,
  ]);

  const mostBytes = Math.max(...points.map((p) => p.bytes));
  const low = frameOf({ height: 150, xMax, yMax: niceAbove(mostBytes / (1024 * 1024)) * 1024 * 1024, yLabel: bytesText });
  const steps = [];
  points.forEach((p, i) => {
    if (i > 0) steps.push(`${low.x(p.ms).toFixed(1)},${low.y(points[i - 1].bytes).toFixed(1)}`);
    steps.push(`${low.x(p.ms).toFixed(1)},${low.y(p.bytes).toFixed(1)}`);
  });
  const bytes = svg(150, "the wasm memory's size over the run", [...low.parts, `<polyline class="bytes" points="${steps.join(" ")}"/>`]);

  const mostInUse = Math.max(...sampled.map((p) => p.peak ?? p.inUse));
  const said = [
    `${timeText(xMax)}, ${number(points.length)} points`,
    `${number(collections)} collection${collections === 1 ? "" : "s"}`,
    `at most ${number(mostInUse)} cells in use, in a heap of ${number(peak)}`,
  ];
  if (lastLive) said.push(`${number(lastLive.live)} live after the last collection`);
  said.push(`wasm memory ${bytesText(points[points.length - 1].bytes)}`);
  return { summary: said.join("; ") + ".", cells, bytes, collections, drops };
}

export const MEMORY_CSS = `
  button.link { border: 0; padding: 0; background: none; color: var(--dim); font-size: 13px;
                text-decoration: underline; text-underline-offset: 3px; cursor: pointer; }
  button.link:hover { background: none; color: var(--ink); }
  .veil { position: fixed; inset: 0; background: rgba(0, 0, 0, .45); z-index: 10; overflow: auto;
          padding: 3vh 16px; box-sizing: border-box; }
  .veil[hidden] { display: none; }
  .memory { position: relative; max-width: 1080px; min-height: 86vh; margin: 0 auto; box-sizing: border-box;
            background: var(--paper); color: var(--ink); border-radius: 8px; padding: 28px 36px 36px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, .3); }
  .memory h2 { margin: 0 0 4px; font-size: 18px; }
  .memory .close { position: absolute; top: 20px; right: 24px; }
  .memory .said { color: var(--dim); font-size: 14px; margin: 0 0 22px; max-width: 46em; }
  .memory .chart { margin: 0 0 8px; }
  .memory .chart svg { display: block; width: 100%; height: auto; overflow: visible; }
  .memory .key { color: var(--dim); font-size: 13px; margin: 0 0 26px; }
  .memory .key > span { margin-right: 18px; white-space: nowrap; }
  .memory .swatch { display: inline-block; width: 14px; height: 0; vertical-align: middle; margin-right: 6px; border-top: 2px solid; }
  .memory .how p { margin: 0 0 10px; max-width: 46em; }
  .memory svg .grid { stroke: var(--line); stroke-width: 1; }
  .memory svg .axis { stroke: var(--dim); stroke-width: 1; }
  .memory svg .tick { fill: var(--dim); font-size: 12px; }
  .memory svg .gc, .memory .swatch.gc { stroke: var(--bad); border-color: var(--bad); stroke-width: 1; stroke-dasharray: 3 4; opacity: .7; }
  .memory .swatch.gc { border-top-style: dashed; }
  .memory svg .cells, .memory .swatch.cells { stroke: var(--go); border-color: var(--go); stroke-width: 2; fill: none; stroke-linejoin: round; }
  .memory svg .cells-area { fill: var(--go); opacity: .12; stroke: none; }
  .memory svg .cells.dense { stroke-width: .6; opacity: .8; }
  .memory svg .length, .memory .swatch.length { stroke: var(--dim); border-color: var(--dim); stroke-width: 1; fill: none; opacity: .6; }
  .memory svg .live { fill: var(--ink); }
  .memory .swatch.live { width: 8px; height: 8px; border: 0; border-radius: 50%; background: var(--ink); }
  .memory svg .bytes, .memory .swatch.bytes { stroke: var(--ink); border-color: var(--ink); stroke-width: 1.5; fill: none; }
  /* On a phone a chart keeps a readable size and scrolls sideways in its own box. */
  @media (max-width: 560px) {
    .memory { padding: 22px 16px 28px; }
    .memory .close { top: 14px; right: 14px; }
    .memory .chart { overflow-x: auto; }
    .memory .chart svg { width: 640px; max-width: none; }
  }
`;
