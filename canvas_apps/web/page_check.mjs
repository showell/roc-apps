#!/usr/bin/env node
// **DOES THE PAGE ACTUALLY RUN?** Node checks the wasm and never touches
// canvas_app_runner.js, which is how a reference error in it reached the browser: the
// canvas was sized from a module that had not been bound yet, and every page
// threw before drawing a pixel.
//
// So this runs canvas_app_runner.js the way a browser would, against a canvas that
// records rather than paints and the real wasm. It cannot say whether a frame
// LOOKS right -- nothing here can -- but it says the page runs, draws, and
// keeps drawing.
//
//   canvas_apps/web/page_check.mjs <app>                  one of the built pages
//   KEYS=5:Space,40:ArrowRight FRAMES=200 …            press keys while it runs
//   DRAG=80,80,500,500 …                               hold and drag the pointer
//   SHOT=snake.png …                                   and save the last frame
//
// **A CHECK THAT CANNOT PRESS A KEY CHECKS THE ATTRACT SCREEN.** Breakout
// waits in Ready until SPACE, so without KEYS this ran 31 frames of a game
// that had not started -- which is how a sound bug reached the page.
//
// The same hole one input along: Pixel Workshop is driven entirely by dragging,
// so without DRAG this checks a canvas nobody has painted on.
//   FRAMES=1500 web/page_check.mjs trick_or_treat   the whole of a long movie
//
// Thirty frames is half a second, which is enough to say the page runs. A game
// that waits on a key needs a key: without KEYS this checks the attract screen.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import vm from "node:vm";

// **SHOT PHOTOGRAPHS THE SAME RUN IT CHECKS.** With SHOT set, every canvas is
// also a real one -- mini_canvas.mjs, a dependency-free rasterizer -- and the
// page's last frame is written to that file as a PNG. Painting is slow next to
// recording, so only the last few callbacks paint; each of the runner's draws
// clears the canvas first, so the last one is a whole frame on its own.
const SHOT = process.env.SHOT;
const mini = SHOT ? await import(new URL("./mini_canvas.mjs", import.meta.url)) : null;
const LIVE_CALLBACKS = 4;
let live = false;
let liveFills = 0;
let mainCanvas = null;

const name = process.argv[2];
if (!name) { console.error("usage: page_check.mjs <app>"); process.exit(2); }
// DIR= checks a build before it is published (build.sh's staging directory).
const dir = process.env.DIR ?? `${process.env.HOME}/build/roc-apps/next/${name}`;
const page = readFileSync(`${dir}/index.html`, "utf8");
// **THE PAGE NAMES ITS OWN SCRIPTS**, so they are read out of it rather than
// by convention. There used to be three lists of them -- build.sh's `cp`, the
// six page.html files, and two hardcoded names here -- and nothing checked
// that any two agreed. A page that loads a script build.sh never copied, or
// forgets one the others have, now fails here instead of in a browser.
const sources = [...page.matchAll(/<script\s+src="([^"]+)"\s*>/g)].map((m) => m[1]);
if (!sources.length) { console.error(`${name}: the page loads no scripts`); process.exit(1); }

// The show the page declares, taken from the page rather than assumed.
const showSrc = page.match(/window\.SHOW\s*=\s*(\{[\s\S]*?\});/);
if (!showSrc) throw new Error("the page does not set window.SHOW");

let calls = 0, fills = 0;
// What the current frame looks like, reset before each one.
let picture = 0;
// A hash of everything drawn, so a keyed run can be shown to differ from an
// unkeyed one. Counting calls cannot see where a paddle is.
let drawn = 0;
// Colours arrive as property SETS (`ctx.fillStyle = ...`), not calls, so those
// are hashed too or a colour regression is invisible.
// **TWO HASHES, BECAUSE THEY ANSWER DIFFERENT QUESTIONS.** `drawn` runs over
// the whole session and says whether THIS RUN differs from another one, which
// is how a keyed run is shown to differ from an unkeyed one. It can never
// repeat, so it says nothing about whether the page is still alive; `picture`
// is reset each frame and says what THAT FRAME looked like.
const fold = (hash, what, values) => {
  let h = (hash * 31 + what.length) | 0;
  for (const v of values) {
    if (typeof v === "number") h = (h * 31 + Math.round(v * 8)) | 0;
    else if (typeof v === "string") for (let i = 0; i < v.length; i++) h = (h * 31 + v.charCodeAt(i)) | 0;
  }
  return h;
};
const mark = (what, values) => {
  drawn = fold(drawn, what, values);
  picture = fold(picture, what, values);
};
// Properties a painter READS back, which a real canvas has to answer.
const READ_BACK = new Set(["fillStyle", "globalAlpha", "globalCompositeOperation", "imageSmoothingEnabled"]);

// One canvas's context: every call and property set is hashed, and with SHOT
// is also made on `real` while the run is in its last callbacks.
const recorder = (real) => new Proxy({}, {
  get: (_t, k) => {
    if (k === "canvas") return { width: 0, height: 0 };
    if (k === "measureText") return () => ({ width: 10 });
    if (real && READ_BACK.has(k)) return real[k];
    // A gradient's stops are where most of the colour lives, so they are
    // hashed rather than thrown away.
    // A picture arrives as bytes written into an ImageData and put back, so
    // the stub hands out a real buffer and hashes what was put. A stub that
    // answered undefined here would have thrown; one that answered a dummy
    // would have hidden every pixel.
    if (k === "createImageData")
      return (w, h) => ({ width: w, height: h, data: new Uint8ClampedArray(w * h * 4) });
    if (k === "putImageData")
      return (image, ...at) => {
        calls++; mark(k, [image.width, image.height, ...image.data]);
        if (real && live) real.putImageData(image, ...at);
      };
    if (k === "createLinearGradient" || k === "createRadialGradient")
      return (...a) => {
        mark(k, a);
        const gradient = real && live ? real[k](...a) : null;
        return {
          addColorStop: (at, colour) => { mark("stop", [at, colour]); gradient?.addColorStop(at, colour); },
          real: gradient,
        };
      };
    return (...a) => {
      calls++; mark(k, a);
      if (k === "fill" || k === "fillRect") { fills++; if (live) liveFills++; }
      return real && live ? real[k](...a) : undefined;
    };
  },
  set: (_target, key, value) => {
    mark(key, [value]);
    if (real && live) real[key] = value?.real ?? value;
    return true;
  },
});

// An element that can be listened to and asked where it is: the pointer
// registers on the CANVAS rather than the window, and `place` converts a page
// coordinate through `getBoundingClientRect`.
const el = (tag) => {
  // With SHOT a canvas is backed by a real one; the first is the page's own,
  // and any after it are a painter's scratch canvases.
  const real = mini && tag === "canvas" ? mini.createCanvas(1, 1) : null;
  if (real && !mainCanvas) mainCanvas = real;
  let width = 0, height = 0, context = null;
  const node = {
    style: {}, textContent: "", appendChild() {}, remove() {},
    get width() { return width; },
    set width(v) { width = v; if (real) real.width = v; },
    get height() { return height; },
    set height(v) { height = v; if (real) real.height = v; },
    getContext: () => (context ??= recorder(real ? real.getContext("2d") : null)),
    // What drawImage reads out of a scratch canvas.
    pixel: (x, y) => real.pixel(x, y),
    addEventListener: (kind, fn) => { (listeners[kind] ??= []).push(fn); },
    getBoundingClientRect: () => ({ left: 0, top: 0, width, height }),
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
// How many distinct pictures the run produced. One means it drew once and
// then repeated itself, or froze.
let moved = 0;
let lastPicture = null;
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
      picture = 2166136261;
      live = Boolean(SHOT) && frames > limit - LIVE_CALLBACKS;
      fn(virtualNow);
      if (picture !== lastPicture) { moved++; lastPicture = picture; }
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
for (const src of sources) {
  if (!existsSync(`${dir}/${src}`)) {
    console.error(`${name}: the page loads ${src}, which is not beside it in ${dir}`);
    process.exit(1);
  }
  vm.runInContext(readFileSync(`${dir}/${src}`, "utf8"), sandbox, { filename: src });
}

const until = Date.now() + 60000;
while (frames <= limit && Date.now() < until) await new Promise((r) => setTimeout(r, 20));
if (frames < 2) { console.error(`${name}: the page never asked for a second frame`); process.exit(1); }
// **COUNTING CALLS CANNOT TELL A RUNNING PAGE FROM A DEAD ONE**, and
// `fills === 0` never could: `draw` clears the canvas with a `fillRect` before
// it paints anything, and the clear is counted. A page that painted no shape
// at all reported 29 fills over 31 frames and passed. So the two ways a page
// can be dead are asked about separately.
//
// One clear per draw, so no more fills than frames means nothing but clears.
if (fills <= frames) {
  console.error(`${name}: ${fills} fills over ${frames} frames is the background and nothing else`);
  process.exit(1);
}
// And a page can paint a great deal and still be stuck: `fps` of zero steps
// once and never again. Neither the call count nor the fill count moves when
// that happens, but the picture stops changing.
if (moved < 2) {
  console.error(`${name}: what the page drew never changed over ${frames} frames`);
  console.error(`${name}: an attract screen that waits for input needs KEYS or DRAG`);
  process.exit(1);
}
const pressed = script.length ? `, ${script.length} keys pressed` : '';
const dragged = drag ? `, dragged ${drag[0]},${drag[1]} to ${drag[2]},${drag[3]}` : '';
if (SHOT) {
  if (!liveFills) {
    console.error(`${name}: nothing was drawn in the last ${LIVE_CALLBACKS} callbacks, so there is no frame to save`);
    process.exit(1);
  }
  writeFileSync(SHOT, mainCanvas.toPNG());
}
console.log(`${name}: ran ${frames} frames, ${moved} distinct, ${calls} canvas calls, ${fills} fills${pressed}${dragged}, drawn ${drawn >>> 0}`);
