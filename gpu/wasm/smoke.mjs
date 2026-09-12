#!/usr/bin/env node
// Drive the gallery wasm module from Node: every kernel's frame 0, its word
// count, checksum and time, so a kernel that traps or answers nothing is
// found here and not in the browser.
//
//   gpu/wasm/smoke.mjs <gallery.wasm> [frames]     frames per kernel, default 3
import { readFileSync } from "node:fs";
const [path, framesArg = "3"] = process.argv.slice(2);
if (!path) { console.error("usage: smoke.mjs <gallery.wasm> [frames]"); process.exit(2); }
const { kernels } = await import(new URL("../web/gallery.js", import.meta.url));
const mod = new WebAssembly.Module(readFileSync(path));
const imports = WebAssembly.Module.imports(mod);
if (imports.length) { console.error("module has imports:", imports); process.exit(1); }
const x = new WebAssembly.Instance(mod, {}).exports;
const n = Number(framesArg);
let bad = 0;
for (const k of kernels) {
  try {
    const t0 = performance.now();
    let bytes = 0, sum = 0n;
    for (let f = 0; f < n; f++) {
      bytes = x.renderFrame(k.id, f);
      if (f === 0) for (const w of new Uint32Array(x.memory.buffer, x.bufPtr(), bytes / 4)) sum += BigInt(w);
    }
    const ms = (performance.now() - t0) / n;
    const ok = bytes / 4 === k.w * k.h;
    if (!ok) bad++;
    console.log(`${ok ? "ok  " : "BAD "} ${k.page.padEnd(12)} ${String(bytes / 4).padStart(7)} words  checksum ${String(sum).padStart(14)}  ${ms.toFixed(1).padStart(7)} ms/frame`);
  } catch (e) { bad++; console.log(`TRAP ${k.page}: ${e.message}`); }
}
console.log(`${kernels.length - bad} of ${kernels.length} kernels render`);
process.exit(bad ? 1 : 0);
