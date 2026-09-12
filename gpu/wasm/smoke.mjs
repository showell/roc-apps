#!/usr/bin/env node
// Drive the gpu wasm module from Node: render frame 0, checksum its words,
// time a run of frames.
//
//   gpu/wasm/smoke.mjs <plasma.wasm> [frames]
import { readFileSync } from "node:fs";
const [path, framesArg = "10"] = process.argv.slice(2);
if (!path) { console.error("usage: smoke.mjs <plasma.wasm> [frames]"); process.exit(2); }
const mod = new WebAssembly.Module(readFileSync(path));
const imports = WebAssembly.Module.imports(mod);
if (imports.length) { console.error("module has imports:", imports); process.exit(1); }
const x = new WebAssembly.Instance(mod, {}).exports;
const bytes = x.renderFrame(0);
const words = new Uint32Array(x.memory.buffer, x.bufPtr(), bytes / 4);
let sum = 0n;
for (const w of words) sum += BigInt(w);
console.log(`frame 0: ${bytes / 4} words, checksum ${sum}`);
const n = Number(framesArg);
const t0 = performance.now();
for (let f = 1; f <= n; f++) x.renderFrame(f);
console.log(`${n} frames: ${((performance.now() - t0) / n).toFixed(1)} ms per frame`);
