#!/usr/bin/env node
// **DOES A VIEW MARK PUT A WORLD POINT WHERE Camera.roc SAYS IT DOES?**
//
// A camera reaches the page as four settings and leaves shapewire.js as a
// canvas matrix, and a canvas matrix is six numbers in an order that is easy
// to get wrong: `setTransform(a, b, c, d, e, f)` maps (x, y) to
// (a·x + c·y + e, b·x + d·y + f), so `b` and `c` are the transposed pair and
// swapping them mirrors a rotated world instead of turning it.
//
// So this hands shapewire.js a view mark and asks where it puts points, and
// compares that against the map written the way Camera.roc writes it:
//
//     screen = zoom · R(rotation) · (world − target) + offset
//
// The two are different spellings of one thing, which is the point: a
// transposition is visible here and is invisible in a call count.
//
//   node canvas_apps/web/camera_check.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";

const here = new URL(".", import.meta.url).pathname;

// A frame is shapes now, not words -- the reader that used to turn one into
// the other is generated. So this says the shapes directly, in the shape the
// generated reader answers.
const viewMark = (camera) => ({ tag: "View", value: { tag: "World", value: camera } });
const aRect = { tag: "Rect", value: { x: 0, y: 0, w: 0, h: 0, fill: { tag: "Flat", value: { r: 255, g: 255, b: 255, a: 1 } } } };

function transformFor(shapes) {
  // **THE LAST setTransform IS THE ONE THAT RESETS THE CANVAS** when the frame
  // ends, so the mark's own is the first.
  const seen = [];
  const ctx = new Proxy({}, {
    get: (_t, k) => {
      if (k === "createLinearGradient" || k === "createRadialGradient") return () => ({ addColorStop() {} });
      if (k === "setTransform") return (...a) => { seen.push(a); };
      return () => undefined;
    },
    set: () => true,
  });
  const sandbox = { Math, Error, Array, Uint32Array, Float32Array, DataView };
  vm.createContext(sandbox);
  // shapewire.js answers one name and answers it as a `const`, which a vm
  // context does not expose as a property, so the script says so itself.
  vm.runInContext(`${readFileSync(`${here}shapewire.js`, "utf8")}\nglobalThis.wire = ShapeWire;`, sandbox);
  sandbox.wire.paint(ctx, shapes);
  return seen[0] ?? null;
}

// Camera.roc's own arithmetic, in its own shape.
const place = (c, world) => {
  const radians = (c.rotation * Math.PI) / 180;
  const cos = Math.cos(radians);
  const sin = Math.sin(radians);
  const dx = world.x - c.target.x;
  const dy = world.y - c.target.y;
  return {
    x: (dx * cos - dy * sin) * c.zoom + c.offset.x,
    y: (dx * sin + dy * cos) * c.zoom + c.offset.y,
  };
};

const through = ([a, b, c, d, e, f], p) => ({ x: a * p.x + c * p.y + e, y: b * p.x + d * p.y + f });

const CAMERAS = [
  { target: { x: 0, y: 0 }, offset: { x: 0, y: 0 }, rotation: 0, zoom: 1 },
  { target: { x: 400, y: 300 }, offset: { x: 400, y: 300 }, rotation: 0, zoom: 2.5 },
  { target: { x: -120, y: 640 }, offset: { x: 400, y: 300 }, rotation: 37, zoom: 0.5 },
  // A mirrored camera, where a transposed pair looks most like a rotation.
  { target: { x: 40, y: 40 }, offset: { x: 100, y: 0 }, rotation: -90, zoom: -1.25 },
];
const POINTS = [{ x: 0, y: 0 }, { x: 800, y: 0 }, { x: 0, y: 600 }, { x: 1600, y: -600 }];

let worst = 0;
for (const camera of CAMERAS) {
  const matrix = transformFor([viewMark(camera), aRect]);
  if (!matrix) throw new Error(`camera_check: no transform for ${JSON.stringify(camera)}`);
  for (const point of POINTS) {
    const canvas = through(matrix, point);
    const roc = place(camera, point);
    worst = Math.max(worst, Math.abs(canvas.x - roc.x), Math.abs(canvas.y - roc.y));
  }
}
// The settings cross as F64 now, so these agree to a double's precision.
if (worst > 1e-9) {
  console.error(`camera_check: the canvas and Camera.roc disagree by ${worst} px`);
  process.exit(1);
}

// And the screen mark is the identity, or a HUD is drawn through the world.
const identity = transformFor([{ tag: "View", value: { tag: "Screen" } }, aRect]);
if (String(identity) !== "1,0,0,1,0,0") {
  console.error(`camera_check: the screen mark is ${identity}, not the identity`);
  process.exit(1);
}

console.log(`camera_check: ${CAMERAS.length} cameras x ${POINTS.length} points agree within ${worst.toExponential(1)} px`);
