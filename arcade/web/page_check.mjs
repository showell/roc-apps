#!/usr/bin/env node
// **DOES THE PAGE ACTUALLY RUN?** Node checks the wasm and never touches
// game_runner.js, which is how a reference error in it reached the browser: the
// canvas was sized from a module that had not been bound yet, and every page
// threw before drawing a pixel.
//
// So this runs game_runner.js the way a browser would, against a canvas that
// records rather than paints and the real wasm. It cannot say whether a frame
// LOOKS right -- nothing here can -- but it says the page runs, draws, and
// keeps drawing.
//
//   arcade/web/page_check.mjs <game>                  one of the built pages
//   KEYS=5:Space,40:ArrowRight FRAMES=200 …            press keys while it runs
//   DRAG=80,80,500,500 …                               hold and drag the pointer
//
// **A CHECK THAT CANNOT PRESS A KEY CHECKS THE ATTRACT SCREEN.** Breakout
// waits in Ready until SPACE, so without KEYS this ran 31 frames of a game
// that had not started -- which is how a sound bug reached the page.
//
// The same hole one input along: Pixel Workshop is driven entirely by dragging,
// so without DRAG this checks a canvas nobody has painted on.
//   FRAMES=1500 web/page_check.mjs halloween     the whole of a long movie
//
// Thirty frames is half a second, which is enough to say the page runs. A game
// that waits on a key needs a key: without KEYS this checks the attract screen.
import { readFileSync } from "node:fs";
import vm from "node:vm";

const name = process.argv[2];
if (!name) { console.error("usage: page_check.mjs <game>"); process.exit(2); }
const dir = `${process.env.HOME}/build/roc-apps/next/${name}`;
const page = readFileSync(`${dir}/index.html`, "utf8");
const wire = readFileSync(`${dir}/shapewire.js`, "utf8");
const runner = readFileSync(`${dir}/game_runner.js`, "utf8");

// The show the page declares, taken from the page rather than assumed.
const showSrc = page.match(/window\.SHOW\s*=\s*(\{[\s\S]*?\});/);
if (!showSrc) throw new Error("the page does not set window.SHOW");

let calls = 0, fills = 0;
// A hash of everything drawn, so a keyed run can be shown to differ from an
// unkeyed one. Counting calls cannot see where a paddle is.
let drawn = 0;
// Colours arrive as property SETS (`ctx.fillStyle = ...`), not calls, so those
// are hashed too or a colour regression is invisible.
const mark = (what, values) => {
  drawn = (drawn * 31 + what.length) | 0;
  for (const v of values) {
    if (typeof v === "number") drawn = (drawn * 31 + Math.round(v * 8)) | 0;
    else if (typeof v === "string") for (let i = 0; i < v.length; i++) drawn = (drawn * 31 + v.charCodeAt(i)) | 0;
  }
};
const ctx = new Proxy({}, {
  get: (_t, k) => {
    if (k === "canvas") return { width: 0, height: 0 };
    if (k === "measureText") return () => ({ width: 10 });
    // A gradient's stops are where most of the colour lives, so they are
    // hashed rather than thrown away.
    // A picture arrives as bytes written into an ImageData and put back, so
    // the stub hands out a real buffer and hashes what was put. A stub that
    // answered undefined here would have thrown; one that answered a dummy
    // would have hidden every pixel.
    if (k === "createImageData")
      return (w, h) => ({ width: w, height: h, data: new Uint8ClampedArray(w * h * 4) });
    if (k === "putImageData")
      return (image) => { calls++; mark(k, [image.width, image.height, ...image.data]); };
    if (k === "createLinearGradient" || k === "createRadialGradient")
      return (...a) => { mark(k, a); return { addColorStop: (at, colour) => mark("stop", [at, colour]) }; };
    return (...a) => { calls++; mark(k, a); if (k === "fill" || k === "fillRect") fills++; return undefined; };
  },
  set: (_target, key, value) => { mark(key, [value]); return true; },
});

// An element that can be listened to and asked where it is: the pointer
// registers on the CANVAS rather than the window, and `place` converts a page
// coordinate through `getBoundingClientRect`.
const el = () => {
  const node = {
    style: {}, width: 0, height: 0, textContent: "", appendChild() {}, remove() {},
    getContext: () => ctx,
    addEventListener: (kind, fn) => { (listeners[kind] ??= []).push(fn); },
    getBoundingClientRect: () => ({ left: 0, top: 0, width: node.width, height: node.height }),
  };
  return node;
};
const document_ = {
  body: { style: {}, appendChild() {} },
  head: { appendChild() {} },
  createElement: el,
  addEventListener() {},
};

const limit = Number(process.env.FRAMES ?? 30);
// KEYS is `frame:Code` pairs: the key goes down on that frame and up the next.
const script = (process.env.KEYS ?? '').split(',').filter(Boolean).map((pair) => {
  const [at, code] = pair.split(':');
  return { at: Number(at), code };
});
// DRAG is `x0,y0,x1,y1`: the button goes down at the first point, the pointer
// walks to the second over the run, and the button comes up at the end.
const dragArg = (process.env.DRAG ?? '').split(',').filter(Boolean).map(Number);
const drag = dragArg.length === 4 ? dragArg : null;
let frames = 0;
// **THE CLOCK IS VIRTUAL, OR THE PAGE TAKES NO STEPS.** The runner paces the
// movie by elapsed time now, and setImmediate fires far faster than a frame is
// due, so against the real clock this ran the page without ever advancing the
// movie. One animation frame here is one frame of the movie's own time.
const STEP_MS = 1000 / 60;
let virtualNow = 0;
const sandbox = {
  console, performance: { now: () => virtualNow }, WebAssembly, fetch: async () => ({}), TextDecoder,
  document: document_, window: {},
  requestAnimationFrame: (fn) => {
    if (frames++ >= limit) return;
    setImmediate(() => {
      for (const { at, code } of script) {
        if (at === frames) press('keydown', code);
        if (at === frames - 1) press('keyup', code);
      }
      if (drag) dragTo(frames);
      virtualNow += STEP_MS;
      fn(virtualNow);
    });
  },
  setImmediate,
};
// The page listens on `window`; record the listeners so the script can fire at
// them, which is what a browser does.
const listeners = {};
sandbox.addEventListener = (kind, fn) => { (listeners[kind] ??= []).push(fn); };
const press = (kind, code) =>
  (listeners[kind] ?? []).forEach((fn) => fn({ code, repeat: false, preventDefault() {} }));
const point = (kind, event) =>
  (listeners[kind] ?? []).forEach((fn) => fn({ ...event, preventDefault() {} }));
const dragTo = (frame) => {
  const span = Math.max(1, limit - 4);
  const t = Math.min(1, Math.max(0, (frame - 2) / span));
  const at = {
    clientX: drag[0] + (drag[2] - drag[0]) * t,
    clientY: drag[1] + (drag[3] - drag[1]) * t,
    button: 0,
  };
  if (frame === 2) point('mousedown', at);
  else if (frame >= limit - 1) point('mouseup', at);
  else if (frame > 2) point('mousemove', at);
};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;

// The one thing a page cannot do here: stream a module over fetch.
const bytes = readFileSync(`${dir}/${name}.wasm`);
sandbox.WebAssembly = Object.create(WebAssembly);
sandbox.WebAssembly.instantiateStreaming = async () => {
  // **THE SAME IMPORTS THE BROWSER GIVES IT**, which is none. Stubbing every
  // declared import would pass a module the page itself could not link.
  const mod = new WebAssembly.Module(bytes);
  return { instance: new WebAssembly.Instance(mod, { env: {} }) };
};

vm.createContext(sandbox);
vm.runInContext(`window.SHOW = ${showSrc[1]};`, sandbox);
vm.runInContext(wire, sandbox, { filename: "shapewire.js" });
vm.runInContext(runner, sandbox, { filename: "game_runner.js" });

const until = Date.now() + 60000;
while (frames <= limit && Date.now() < until) await new Promise((r) => setTimeout(r, 20));
if (frames < 2) { console.error(`${name}: the page never asked for a second frame`); process.exit(1); }
if (fills === 0) { console.error(`${name}: the page drew nothing`); process.exit(1); }
const pressed = script.length ? `, ${script.length} keys pressed` : '';
const dragged = drag ? `, dragged ${drag[0]},${drag[1]} to ${drag[2]},${drag[3]}` : '';
console.log(`${name}: ran ${frames} frames, ${calls} canvas calls, ${fills} fills${pressed}${dragged}, drawn ${drawn >>> 0}`);
