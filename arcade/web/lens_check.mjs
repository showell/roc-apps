#!/usr/bin/env node
// **DOES A VIEW MARK PUT A WORLD POINT WHERE Roc SAYS IT DOES?**
//
// A lens crosses the wire as six numbers and comes out of shapewire.js as a
// canvas matrix, and a canvas matrix is six numbers in an order that is easy
// to get wrong: `setTransform(a, b, c, d, e, f)` maps (x, y) to
// (a·x + c·y + e, b·x + d·y + f), so `b` and `c` are the transposed pair and
// swapping them mirrors a rotated world instead of turning it.
//
// So this feeds shapewire.js a lens and asks where it puts points, and
// compares that against the map written the way Camera.roc writes it:
//
//     screen = zoom · R(rotation) · (world − target) + offset
//
// The two are different spellings of one thing, which is the point: a
// transposition is visible here and is invisible in a call count.
//
//   node arcade/web/lens_check.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";

const here = new URL(".", import.meta.url).pathname;

// The lens as ShapeWire.roc packs it, and one rectangle drawn through it.
const KIND = { RECT: 2, VIEW: 4 };
const f32 = (value) => {
  const buffer = new ArrayBuffer(4);
  new Float32Array(buffer)[0] = value;
  return new Uint32Array(buffer)[0];
};

function frameWords(lens) {
  const words = [KIND.VIEW, 1, ...[lens.target.x, lens.target.y, lens.offset.x, lens.offset.y, lens.rotation, lens.zoom].map(f32)];
  // A flat white rectangle: kind, brush mode, its colour and alpha, then x y w h.
  words.push(KIND.RECT, 0, 0xffffff, f32(1), f32(0), f32(0), f32(0), f32(0));
  return words;
}

// shapewire reads the words out of a wasm memory, so it is handed one.
function decodeAndPaint(words) {
  const memory = { buffer: new Uint32Array(words).buffer };
  // **THE LAST setTransform IS THE ONE THAT RESETS THE CANVAS** when the frame
  // ends, so the mark's own is the first.
  const seen = [];
  const ctx = new Proxy({}, {
    get: (_t, k) => {
      if (k === "createLinearGradient" || k === "createRadialGradient")
        return () => ({ addColorStop() {} });
      if (k === "setTransform") return (...a) => { seen.push(a); };
      return () => undefined;
    },
    set: () => true,
  });
  const sandbox = { Math, Error, Array, Uint32Array, Float32Array };
  vm.createContext(sandbox);
  // shapewire.js answers one name and answers it as a `const`, which a vm
  // context does not expose as a property, so the script says so itself.
  vm.runInContext(`${readFileSync(`${here}shapewire.js`, "utf8")}\nglobalThis.wire = ShapeWire;`, sandbox);
  sandbox.wire.paint(ctx, sandbox.wire.decode(memory, 0, words.length * 4));
  return seen[0] ?? null;
}

// Camera.roc's own arithmetic, in its own shape.
const place = (lens, world) => {
  const radians = (lens.rotation * Math.PI) / 180;
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  const dx = world.x - lens.target.x;
  const dy = world.y - lens.target.y;
  return {
    x: (dx * cos - dy * sin) * lens.zoom + lens.offset.x,
    y: (dx * sin + dy * cos) * lens.zoom + lens.offset.y,
  };
};

const through = ([a, b, c, d, e, f], p) => ({ x: a * p.x + c * p.y + e, y: b * p.x + d * p.y + f });

const LENSES = [
  { target: { x: 0, y: 0 }, offset: { x: 0, y: 0 }, rotation: 0, zoom: 1 },
  { target: { x: 400, y: 300 }, offset: { x: 400, y: 300 }, rotation: 0, zoom: 2.5 },
  { target: { x: -120, y: 640 }, offset: { x: 400, y: 300 }, rotation: 37, zoom: 0.5 },
  // A mirrored camera, where a transposed pair looks most like a rotation.
  { target: { x: 40, y: 40 }, offset: { x: 100, y: 0 }, rotation: -90, zoom: -1.25 },
];
const POINTS = [{ x: 0, y: 0 }, { x: 800, y: 0 }, { x: 0, y: 600 }, { x: 1600, y: -600 }];

let worst = 0;
for (const lens of LENSES) {
  const matrix = decodeAndPaint(frameWords(lens));
  if (!matrix) throw new Error(`lens_check: no transform for ${JSON.stringify(lens)}`);
  for (const point of POINTS) {
    const canvas = through(matrix, point);
    const roc = place(lens, point);
    worst = Math.max(worst, Math.abs(canvas.x - roc.x), Math.abs(canvas.y - roc.y));
  }
}
// A lens crosses the wire as F32, so the two agree to a float's precision and
// not to the bit.
if (worst > 0.002) {
  console.error(`lens_check: the canvas and Camera.roc disagree by ${worst} px`);
  process.exit(1);
}

// And the screen lens is the identity, or a HUD is drawn through the world.
const identity = decodeAndPaint([KIND.VIEW, 0, KIND.RECT, 0, 0xffffff, f32(1), f32(0), f32(0), f32(0), f32(0)]);
if (String(identity) !== "1,0,0,1,0,0") {
  console.error(`lens_check: the screen lens is ${identity}, not the identity`);
  process.exit(1);
}

console.log(`lens_check: ${LENSES.length} lenses x ${POINTS.length} points agree within ${worst.toFixed(5)} px`);
