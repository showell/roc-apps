#!/usr/bin/env node
// Drive the safari wasm module from Node the way web/blitter.js does, without
// a canvas: render, decode the command stream's tags, read the readouts, and
// time a run of steps.
//
//   wasm/drive_smoke.mjs <safari.wasm> [steps]     steps defaults to 60
import { readFileSync } from "node:fs";

const [path, stepsArg = "60"] = process.argv.slice(2);
if (!path) { console.error("usage: drive_smoke.mjs <safari.wasm> [steps]"); process.exit(2); }
const steps = Number(stepsArg);
const mod = new WebAssembly.Module(readFileSync(path));
let memory = null;
const text = (p, n) => new TextDecoder().decode(new Uint8Array(memory.buffer, p, n));
const env = {};
for (const imp of WebAssembly.Module.imports(mod)) {
  env[imp.name] = imp.name === "roc_panic" ? (p, n) => { throw new Error("roc_panic: " + text(p, n)); }
    : imp.name === "roc_dbg" ? (p, n) => process.stderr.write("dbg: " + text(p, n) + "\n")
    : (...a) => console.error(`env.${imp.name}(${a.join(", ")})`);
}
const x = new WebAssembly.Instance(mod, { env }).exports;
memory = x.memory;

// The blitter's walk over the words: a kind, a brush, then the shape. **This
// is the round-trip check**: if the packer in ShapeWire.roc and the reader in
// blitter.js disagree by one word, the walk does not land exactly on the end.
const MODE_WORDS = { 0: 2, 1: 6, 2: 8, 3: 10, 4: 12, 5: 10 }; // colours + geometry, past the mode
function decode(base, len) {
  const u32 = new Uint32Array(memory.buffer, base, len / 4);
  const kinds = {}; const modes = {}; let w = 0, pts = 0, clips = 0;
  while (w * 4 < len) {
    const kind = u32[w++]; kinds[kind] = (kinds[kind] ?? 0) + 1;
    const mode = u32[w++]; modes[mode] = (modes[mode] ?? 0) + 1;
    const words = MODE_WORDS[mode];
    if (words === undefined) throw new Error(`unknown brush mode ${mode} at word ${w - 1}`);
    w += words;
    if (kind === 0) { const n = u32[w++]; pts += n; w += 2 * n; }
    else if (kind === 1) { w += 3; if (u32[w++]) { clips++; w += 4; } }
    else if (kind === 2) { w += 4; }
    else throw new Error(`unknown shape kind ${kind} at word ${w - 2}`);
  }
  if (w * 4 !== len) throw new Error(`the walk ended at ${w * 4} bytes, not ${len}`);
  return { kinds, modes, pts, clips };
}

const readouts = () => ({
  clock: x.clock(), seg: x.riderSeg(), tilt: x.riderTilt().toFixed(4), focal: x.camFocal().toFixed(2),
  gaze: x.gazeYaw().toFixed(4),
  v: x.riderV().toFixed(3), truckLead: x.truckLead().toFixed(2), truckV: x.truckV().toFixed(3),
});

let t0 = performance.now();
let len = x.renderFrame();
console.log(`first frame: ${len} bytes in ${(performance.now() - t0).toFixed(1)} ms`, decode(x.bufPtr(), len));
console.log("readouts:", readouts());
if (x.probeFrame) {
  const rep = 5; let tf = 0, te = 0, tp = 0, nf = 0, ne = 0;
  for (let i = 0; i < rep; i++) {
    t0 = performance.now(); nf = x.probeFrame(); tf += performance.now() - t0;
    t0 = performance.now(); ne = x.probeExpand(); te += performance.now() - t0;
    t0 = performance.now(); x.renderFrame(); tp += performance.now() - t0;
  }
  console.log(`stages: ride_frame ${(tf / rep).toFixed(1)} ms (${nf} cmds); +blit_expand ${(te / rep).toFixed(1)} ms (${ne} cmds); +pack ${(tp / rep).toFixed(1)} ms`);
}
let ta = 0, tr = 0;
for (let i = 0; i < steps; i++) {
  t0 = performance.now(); x.advance(); ta += performance.now() - t0;
  t0 = performance.now(); len = x.renderFrame(); tr += performance.now() - t0;
}
console.log(`${steps} steps: ${(ta / steps).toFixed(2)} ms per advance, ${(tr / steps).toFixed(2)} ms per render; last frame ${len} bytes, peak ${x.bufHighWater()} bytes`);
console.log("readouts:", readouts());
for (let i = 0; i < 3; i++) x.back();
console.log("after 3 back:", { clock: x.clock(), seg: x.riderSeg() });
