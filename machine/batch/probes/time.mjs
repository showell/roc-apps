// time.mjs <wasm> <word>...: three fresh runs; the fastest, and whether a screen came back.
import { readFileSync } from "node:fs";
const [wasmPath, ...words] = process.argv.slice(2);
const bytes = readFileSync(wasmPath);
const line = new TextEncoder().encode(words.map((w) => w + "\0").join(""));
let best = Infinity, screen = 0;
for (let k = 0; k < 3; k++) {
  const { instance } = await WebAssembly.instantiate(bytes, {});
  const x = instance.exports;
  new Uint8Array(x.memory.buffer, x.argsBuffer(), line.length).set(line);
  const t0 = performance.now();
  x.run(line.length);
  best = Math.min(best, performance.now() - t0);
  screen = x.screenLen();
}
console.log(`${wasmPath.split("/").pop()}: ${best.toFixed(0)} ms, screen bytes ${screen}`);
