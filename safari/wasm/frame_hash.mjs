#!/usr/bin/env node
// Hash what the safari wasm module draws over a fixed ride, so a change that
// should not move a pixel can be held to exactly that. Each frame is its
// SHAPE bytes and every readout the page binds; the ride advances `stride`
// steps between frames, then steps back three times and draws again. One
// line per frame, then the digest of them all (FNV-1a, 32 bits).
//
//   safari/wasm/frame_hash.mjs <safari.wasm> [frames] [stride]    defaults 60 and 100
import { readFileSync } from "node:fs";

const [path, framesArg = "60", strideArg = "100"] = process.argv.slice(2);
if (!path) { console.error("usage: frame_hash.mjs <safari.wasm> [frames] [stride]"); process.exit(2); }
const mod = new WebAssembly.Module(readFileSync(path));
let memory = null;
const text = (p, n) => new TextDecoder().decode(new Uint8Array(memory.buffer, p, n));
const env = {};
for (const imp of WebAssembly.Module.imports(mod)) {
  env[imp.name] = imp.name === "roc_panic" ? (p, n) => { throw new Error("roc_panic: " + text(p, n)); }
    : (...a) => { throw new Error(`unexpected import env.${imp.name}(${a.join(", ")})`); };
}
const x = new WebAssembly.Instance(mod, { env }).exports;
memory = x.memory;

const fnv = (h, bytes) => {
  for (let i = 0; i < bytes.length; i++) h = Math.imul(h ^ bytes[i], 16777619) >>> 0;
  return h;
};
const OFFSET = 2166136261;
const U32 = ["clock", "riderSeg"];
const F32 = ["riderTilt", "camFocal", "gazeYaw", "riderV", "truckLead", "truckV"];

function frame(label) {
  const len = x.renderFrame();
  let h = fnv(OFFSET, new Uint8Array(memory.buffer, x.bufPtr(), len));
  const words = new DataView(new ArrayBuffer(4 * (U32.length + F32.length)));
  U32.forEach((name, i) => words.setUint32(4 * i, x[name](), true));
  F32.forEach((name, i) => words.setFloat32(4 * (U32.length + i), x[name](), true));
  h = fnv(h, new Uint8Array(words.buffer));
  console.log(`${label} clock ${x.clock()} seg ${x.riderSeg()} bytes ${len} hash ${h.toString(16).padStart(8, "0")}`);
  return h;
}

let digest = OFFSET;
const fold = (h) => { digest = fnv(digest, new Uint8Array(new Uint32Array([h]).buffer)); };
for (let f = 0; f < Number(framesArg); f++) {
  fold(frame(`frame ${f}`));
  for (let s = 0; s < Number(strideArg); s++) x.advance();
}
for (let i = 0; i < 3; i++) x.back();
fold(frame("back 3"));
console.log(`digest ${digest.toString(16).padStart(8, "0")}`);
