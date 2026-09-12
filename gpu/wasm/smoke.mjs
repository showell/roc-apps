#!/usr/bin/env node
// Drive the gallery wasm module from Node: every demo's first frames, its
// word count, checksum and time, so a demo that traps or answers nothing is
// found here and not in the browser.
//
//   gpu/wasm/smoke.mjs <gallery.wasm> [frames] [page...]   frames per demo, default 3; the named demos, default all
import { readFileSync } from "node:fs";
const [path, framesArg = "3", ...only] = process.argv.slice(2);
if (!path) { console.error("usage: smoke.mjs <gallery.wasm> [frames]"); process.exit(2); }
const all = (await import(new URL("../web/gallery.js", import.meta.url))).kernels;
const kernels = only.length ? all.filter(k => only.includes(k.page)) : all;
const mod = new WebAssembly.Module(readFileSync(path));
const imports = WebAssembly.Module.imports(mod);
if (imports.length) { console.error("module has imports:", imports); process.exit(1); }
const x = new WebAssembly.Instance(mod, {}).exports;
const n = Number(framesArg);
let bad = 0;
for (const k of kernels) {
  const want = k.draw.kind === "pixels" ? k.w * k.h : null;
  try {
    const t0 = performance.now();
    let bytes = 0, sum = 0n;
    for (let f = 0; f < n; f++) {
      x.step(k.id, f);
      bytes = x.view();
      if (f === 0) for (const w of new Uint32Array(x.memory.buffer, x.bufPtr(), bytes / 4)) sum += BigInt(w);
    }
    const ms = (performance.now() - t0) / n;
    const ok = want === null ? bytes > 0 : bytes / 4 === want;
    if (!ok) bad++;
    console.log(`${ok ? "ok  " : "BAD "} ${k.page.padEnd(12)} ${String(bytes / 4).padStart(7)} words  checksum ${String(sum).padStart(14)}  ${ms.toFixed(1).padStart(7)} ms/frame`);
  } catch (e) { bad++; console.log(`TRAP ${k.page}: ${e.message}`); }
}
console.log(`${kernels.length - bad} of ${kernels.length} demos render`);
process.exit(bad ? 1 : 0);
