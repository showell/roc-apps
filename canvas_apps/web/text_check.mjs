#!/usr/bin/env node
// This checks what a canvas gets asked for a line of type, on both sides of
// each choice a `Text` shape makes, and that a page scaled for the screen still
// puts things where the app said. It hands shapes_canvas.js shapes in the form
// the generated reader answers.
//
// With `raster`, it also sets lines of type on mini_canvas and looks at the
// ink, which needs the stand-in fonts that mini_font.mjs names. build.sh gives
// that to the widgets, whose shots need those fonts anyway.
//
//   node canvas_apps/web/text_check.mjs [raster]
import { readFileSync } from "node:fs";
import vm from "node:vm";

const here = new URL(".", import.meta.url).pathname;

function fail(why) {
  console.error(`text_check: ${why}`);
  process.exit(1);
}

function same(got, want, what) {
  if (JSON.stringify(got) !== JSON.stringify(want)) {
    fail(`${what}: got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);
  }
}

const sandbox = { Math, Error, Array, Uint32Array, Float32Array, DataView };
vm.createContext(sandbox);
vm.runInContext(`${readFileSync(`${here}shapes_canvas.js`, "utf8")}\nglobalThis.wire = ShapesCanvas;`, sandbox);

// What a frame did to the canvas: each call, and each property as it stood when
// the line was set.
function painted(shapes, scale) {
  const calls = [];
  const set = {};
  const ctx = new Proxy({}, {
    get: (_t, k) => (...a) => { calls.push({ k, a, ...set }); },
    set: (_t, k, v) => { set[k] = v; return true; },
  });
  sandbox.wire.paint(ctx, shapes, scale);
  return calls;
}

const line = (fields) => ({
  tag: "Text",
  value: {
    text: "Sun.height_px(clock)", x: 24, y: 266, size: 15,
    face: { tag: "Code" }, align: { tag: "Left" }, color: { r: 32, g: 16, b: 8, a: 1 },
    ...fields,
  },
});
const setting = (fields) => painted([line(fields)]).find((call) => call.k === "fillText");

const code = setting({});
same(code.a, ["Sun.height_px(clock)", 24, 266], "the words and their place");
same(code.fillStyle, "rgba(32,16,8,1)", "the color");
same(code.textBaseline, "alphabetic", "the baseline");
same(code.textAlign, "left", "a left-aligned line");
if (!code.font.startsWith("15px ") || !code.font.endsWith(", monospace")) fail(`code is set in ${code.font}`);

const prose = setting({ face: { tag: "Prose" }, align: { tag: "Center" }, size: 13.5 });
same(prose.textAlign, "center", "a centered line");
if (!prose.font.startsWith("13.5px ") || !prose.font.endsWith(", sans-serif")) fail(`prose is set in ${prose.font}`);

// Text is not a mark: the frame's end is the one transform this frame sets.
const transforms = (scale, shapes) => painted(shapes, scale).filter((c) => c.k === "setTransform").map((c) => c.a);
same(transforms(undefined, [line({})]), [[1, 0, 0, 1, 0, 0]], "a frame at the app's own size");
same(transforms(2.5, [line({})]), [[2.5, 0, 0, 2.5, 0, 0]], "a frame scaled for the screen");

// A view is the app's own, so a scaled page holds the scale outside it.
const camera = { target: { x: 10, y: 20 }, offset: { x: 100, y: 200 }, rotation: 0, zoom: 3 };
const view = { tag: "View", value: { tag: "World", value: camera } };
same(transforms(1, [view])[0], [3, 0, -0, 3, 70, 140], "a view at the app's own size");
same(transforms(2, [view])[0], [6, 0, -0, 6, 140, 280], "a view scaled for the screen");
same(transforms(2, [{ tag: "View", value: { tag: "Screen" } }])[0], [2, 0, 0, 2, 0, 0], "the screen, scaled");

let raster = "";
if (process.argv[2] === "raster") {
  const { createCanvas } = await import("./mini_canvas.mjs");
  const stack = (generic) => `20px Nothing Here, ${generic}`;

  // The ink's left and right ends, and its top and bottom, in canvas pixels.
  const ink = (paint) => {
    const canvas = createCanvas(200, 60);
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#fff";
    ctx.fillRect(0, 0, 200, 60);
    ctx.fillStyle = "#000";
    paint(ctx);
    const inked = [];
    for (let y = 0; y < 60; y++) {
      for (let x = 0; x < 200; x++) if (canvas.pixel(x, y)[0] < 128) inked.push({ x, y });
    }
    if (!inked.length) fail("a line of type left no ink");
    const xs = inked.map((p) => p.x), ys = inked.map((p) => p.y);
    return { left: Math.min(...xs), right: Math.max(...xs), top: Math.min(...ys), bottom: Math.max(...ys), count: inked.length };
  };
  const set = (font, align, text) => ink((ctx) => { ctx.font = font; ctx.textAlign = align; ctx.fillText(text, 100, 40); });

  // A capital stands on the baseline, about 0.7 of the size tall.
  const capital = set(stack("sans-serif"), "left", "H");
  if (capital.bottom !== 39) fail(`a capital ends at row ${capital.bottom}, not on the baseline`);
  if (capital.top < 24 || capital.top > 27) fail(`a capital's top is at row ${capital.top}`);
  if (capital.left < 100 || capital.left > 104) fail(`a line starts at column ${capital.left}`);

  // A centered line sits either side of its x.
  const centered = set(stack("sans-serif"), "center", "HHH");
  if (centered.left >= 100 || centered.right <= 100) fail(`a centered line runs ${centered.left} to ${centered.right}`);
  if (Math.abs(100 - centered.left - (centered.right - 100)) > 2) fail("a centered line is off center");

  // In monospace an i is as wide as an m; in a sans serif it is narrower.
  const wide = (generic, text) => { const r = set(stack(generic), "left", `${text}|`); return r.right; };
  if (wide("monospace", "iiii") !== wide("monospace", "mmmm")) fail("the monospace stand-in isn't monospace");
  if (wide("sans-serif", "iiii") >= wide("sans-serif", "mmmm")) fail("the sans stand-in isn't proportional");

  // A letter with a hole keeps it: an o inks far less than its box.
  const ring = set(stack("sans-serif"), "left", "o");
  if (ring.count * 10 > (ring.right - ring.left + 1) * (ring.bottom - ring.top + 1) * 7) fail("an o has no hole");

  // A stack with no generic family, and a letter no face has, stop the shot.
  for (const [font, text] of [["20px Nothing Here", "H"], ["20px sans-serif", "\u{e000}"]]) {
    let stopped = false;
    try { set(font, "left", text); } catch { stopped = true; }
    if (!stopped) fail(`${font} set ${text} and should have stopped`);
  }
  raster = ", and type on mini_canvas";
}

console.log(`text_check: lines of type and scaled frames as asked${raster}`);
