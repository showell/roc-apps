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
//   SEARCH='?start=trees' …                            open at this address
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
//
// After the run, and after its hash, the page goes through checkPointer: drags
// by mouse and by finger, each ended by pointerup and by pointercancel. What
// the runner tells `advance` is judged on every page. With
// STILL_BETWEEN_DRAGS=1 in an app's shot.env the picture is judged too.
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

// The page's canvas, and the pointer it has captured.
let pageCanvas = null;
let captured = null;

// An element that can be listened to and asked where it is: the pointer
// registers on the CANVAS rather than the window, and `place` converts a page
// coordinate through `getBoundingClientRect`.
const el = (tag) => {
  // With SHOT a canvas is backed by a real one; the first is the page's own,
  // and any after it are a painter's scratch canvases.
  const real = mini && tag === "canvas" ? mini.createCanvas(1, 1) : null;
  if (real && !mainCanvas) mainCanvas = real;
  let width = 0, height = 0, context = null;
  const heard = {};
  const node = {
    style: {}, textContent: "", appendChild() {}, remove() {},
    get width() { return width; },
    set width(v) { width = v; if (real) real.width = v; },
    get height() { return height; },
    set height(v) { height = v; if (real) real.height = v; },
    getContext: () => (context ??= recorder(real ? real.getContext("2d") : null)),
    // What drawImage reads out of a scratch canvas.
    pixel: (x, y) => real.pixel(x, y),
    addEventListener: (kind, fn) => { (heard[kind] ??= []).push(fn); },
    fire: (kind, event) => (heard[kind] ?? []).forEach((fn) => fn(event)),
    setPointerCapture: (id) => { captured = id; },
    getBoundingClientRect: () => ({ left: 0, top: 0, width, height }),
  };
  if (tag === "canvas") pageCanvas ??= node;
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
// The callback the page left waiting when the run ended, for checkPointer.
let parked = null;
const sandbox = {
  console, performance: { now: () => virtualNow }, WebAssembly, fetch: async () => ({}), TextDecoder,
  document: document_, window: {},
  location: { search: process.env.SEARCH ?? "" }, URLSearchParams,
  requestAnimationFrame: (fn) => {
    if (frames++ >= limit) { parked = fn; return; }
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
// As a browser does it: the canvas hears a pointer that is over it or captured
// by it, and the window hears every one.
const point = (kind, fields) => {
  const event = { pointerId: 1, pointerType: "mouse", button: -1, buttons: 0, ...fields, preventDefault() {} };
  const over = event.clientX >= 0 && event.clientX < pageCanvas.width
    && event.clientY >= 0 && event.clientY < pageCanvas.height;
  if (over || captured === event.pointerId) pageCanvas.fire(kind, event);
  (listeners[kind] ?? []).forEach((fn) => fn(event));
  if (kind !== "pointerdown" && kind !== "pointermove" && captured === event.pointerId) captured = null;
};
const dragTo = (frame) => {
  const span = Math.max(1, limit - 4);
  const t = Math.min(1, Math.max(0, (frame - 2) / span));
  const at = {
    clientX: drag[0] + (drag[2] - drag[0]) * t,
    clientY: drag[1] + (drag[3] - drag[1]) * t,
  };
  if (frame === 2) point('pointerdown', { ...at, button: 0, buttons: 1 });
  else if (frame === limit - 1) point('pointerup', { ...at, button: 0 });
  else if (frame > 2 && frame < limit - 1) point('pointermove', { ...at, buttons: 1 });
};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;

// What the runner last told the app, with the strikes since checkPointer asked.
const told = { steps: 0, held: 0, struck: 0, x: 0, y: 0 };
const tellingAdvance = (advance) => (keysHeld, keysStruck, held, struck, x, y, wheel) => {
  told.steps++;
  Object.assign(told, { held, x, y, struck: told.struck | struck });
  return advance(keysHeld, keysStruck, held, struck, x, y, wheel);
};

// The one thing a page cannot do here: stream a module over fetch.
const bytes = readFileSync(`${dir}/${name}.wasm`);
sandbox.WebAssembly = Object.create(WebAssembly);
sandbox.WebAssembly.instantiateStreaming = async () => {
  // **THE SAME IMPORTS THE BROWSER GIVES IT**, which is none. Stubbing every
  // declared import would pass a module the page itself could not link.
  const mod = new WebAssembly.Module(bytes);
  const { exports } = new WebAssembly.Instance(mod, { env: {} });
  return { instance: { exports: { ...exports, advance: tellingAdvance(exports.advance) } } };
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

const refuse = (why) => {
  console.error(`${name}: ${why}`);
  process.exit(1);
};
const expect = (holds, why) => { if (!holds) refuse(why); };

// The last frame an app answers after a run of steps from a fresh start, each
// taking the five pointer numbers `pointerAt` says.
const WATCHED_STEPS = 20;
const frameAfterSteps = (pointerAt) => {
  const { exports } = new WebAssembly.Instance(new WebAssembly.Module(bytes), { env: {} });
  for (let i = 0; i < WATCHED_STEPS; i++) exports.advance(0, 0, ...pointerAt(i));
  const at = exports.computeFrame();
  const frame = vm.runInContext("RocGlue", sandbox).frame(new DataView(exports.memory.buffer), at);
  return JSON.stringify(frame, (_key, value) => (typeof value === "bigint" ? String(value) : value));
};

// A page says whether its app reads the pointer, because the wasm can't, and the
// runner sets touch-action from that. So what it says is measured here.
const checkTouchAction = () => {
  const said = Boolean(sandbox.SHOW.readsPointer);
  const untouched = frameAfterSteps(() => [0, 0, 0, 0, 0]);
  const dragged = frameAfterSteps((i) => [7, i === 0 ? 7 : 0, pageCanvas.width * (0.2 + i / 50), pageCanvas.height * 0.4, 1]);
  const reads = untouched !== dragged;
  expect(said === reads, `the page says readsPointer ${said}, but the pointer ${reads ? "changes" : "never changes"} what the app draws`);
  const wanted = said ? "none" : "auto";
  expect(pageCanvas.style.touchAction === wanted, `touch-action is ${pageCanvas.style.touchAction}, not ${wanted}`);
};

// One step of the app, however many animation frames that takes: what it was
// told, and the picture it drew.
const step = () => {
  const before = told.steps;
  told.struck = 0;
  for (let tries = 0; told.steps === before; tries++) {
    if (tries === 60) refuse("the page stopped stepping");
    const callback = parked;
    virtualNow += STEP_MS;
    picture = 2166136261;
    callback(virtualNow);
  }
  return { ...told, picture };
};

const checkPointer = () => {
  const still = process.env.STILL_BETWEEN_DRAGS === "1";
  const { width, height } = pageCanvas;
  const near = (a, b) => Math.abs(a - b) < 0.01;
  const spot = (x, y) => ({ clientX: x, clientY: y, x, y });
  const from = spot(width * 0.25, height * 0.5);
  const to = spot(width * 0.75, height * 0.5);
  const off = spot(width + 50, -50);
  const down = { button: 0, buttons: 1 };
  const secondFinger = { pointerId: 9, pointerType: "touch" };

  if (still) expect(step().picture === step().picture, "the picture does not hold still");

  // Both ways of ending, by both devices. `device` is what every event in the
  // drag carries.
  const drag = (device, ending) => {
    const says = `${device.pointerType} drag ended by ${ending}`;
    point("pointerdown", { ...device, ...from, ...down });
    const pressed = step();
    expect(pressed.held === 1 && pressed.struck === 1, `${says}: the press reached the app as held ${pressed.held}, struck ${pressed.struck}`);
    expect(near(pressed.x, from.x), `${says}: the press is at ${pressed.x}, not ${from.x}`);
    expect(step().struck === 0, `${says}: the press struck twice`);

    point("pointermove", { ...device, ...to, buttons: 1 });
    const moved = step();
    expect(moved.held === 1 && near(moved.x, to.x), `${says}: the move reached the app as held ${moved.held} at ${moved.x}`);
    if (still) expect(moved.picture !== pressed.picture, `${says}: the drag did not move the widget`);

    point("pointermove", { ...device, ...off, buttons: 1 });
    const outside = step();
    expect(near(outside.x, off.x) && near(outside.y, off.y), `${says}: a drag off the canvas stopped tracking at ${outside.x}, ${outside.y}`);

    point("pointerdown", { ...secondFinger, ...from, ...down });
    point("pointermove", { ...secondFinger, ...from, buttons: 1 });
    point("pointerup", { ...secondFinger, ...from, button: 0 });
    const ignored = step();
    expect(ignored.held === 1 && near(ignored.x, off.x), `${says}: a second finger took over the drag`);

    point("pointermove", { ...device, ...to, buttons: 1 });
    const back = step();
    point(ending, { ...device, ...to, button: ending === "pointerup" ? 0 : -1 });
    const left = step();
    expect(left.held === 0, `${says}: the button is still held after it`);

    // A button pressed somewhere else still shows on a move, and isn't a drag.
    point("pointermove", { ...device, ...from, buttons: 1 });
    const after = step();
    expect(after.held === 0 && after.struck === 0, `${says}: a move after it reached the app as held ${after.held}`);
    if (still) expect(after.picture === left.picture && left.picture === back.picture, `${says}: a move after it moved the widget`);
    point("pointermove", { ...device, ...to });
    step();
  };
  for (const device of [{ pointerId: 1, pointerType: "mouse" }, { pointerId: 7, pointerType: "touch" }]) {
    drag(device, "pointerup");
    drag(device, "pointercancel");
  }

  // pointerdown and pointerup come only with the first button down and the
  // last one up. The buttons between them arrive as moves.
  point("pointerdown", { ...from, ...down });
  expect(step().held === 1, "left alone is not held");
  point("pointermove", { ...from, button: 2, buttons: 3 });
  const both = step();
  expect(both.held === 3 && both.struck === 2, `a second button reached the app as held ${both.held}, struck ${both.struck}`);
  point("pointermove", { ...from, button: 0, buttons: 2 });
  expect(step().held === 2, "right is not left held alone");
  point("pointerup", { ...from, button: 2 });
  expect(step().held === 0, "the last button up left something held");

  // A window that loses focus ends a drag, and the moves that follow don't
  // start it again.
  point("pointerdown", { ...from, ...down });
  step();
  (listeners.blur ?? []).forEach((fn) => fn());
  point("pointermove", { ...to, buttons: 1 });
  expect(step().held === 0, "a drag survived the window losing focus");
  point("pointerup", { ...to, button: 0 });
  step();

  console.log(`${name}: pointer checked by mouse and finger, ending by pointerup and pointercancel, touch-action ${pageCanvas.style.touchAction}, ${still ? "picture and " : ""}advance judged`);
};

// The runner is shared, so the apps that read the pointer prove it for all of
// them, and painting these drags through safari alone would cost minutes.
checkTouchAction();
if (sandbox.SHOW.readsPointer) checkPointer();
