// THE BASIC RUNNER: basic.wasm, built once by basic/build-wasm.sh, runs
// corpus programs through the interpreter's batch door.
//
//   node basic/runner.mjs nbs P001 P002 ...
//   node basic/runner.mjs games bunny
//
// **EVERY TIME IS ONE PHASE.** Compiling the wasm module is reported once;
// each program's time is the runBatch call alone -- the BASIC interpreter
// splitting the listing, collecting its DATA and running its statements --
// with nothing of the Roc compiler in it. A program over a second is marked
// SLOW. One over the limit is stopped and marked TIMEOUT: it runs in a
// worker thread, and the worker is replaced.
//
// The listing and keystrokes are prepared exactly as basic/gen.py prepares
// them for its string literals, and the seed is the one its apps get.
import { readFileSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { Worker, isMainThread, parentPort, workerData } from "node:worker_threads";
import { fileURLToPath } from "node:url";
import path from "node:path";
import os from "node:os";

const HOME = os.homedir();
const WASM = process.env.BASIC_WASM || `${HOME}/build/roc-apps/gen/basic/basic.wasm`;
const SLOW_MS = 1000;
const LIMIT_MS = 2000;
// A generated app's seed is 1 plus the length of its argument list, which
// holds the program's own name.
const SEED = 2;

if (!isMainThread) {
  // Given a compiled module, instantiate answers the instance itself.
  const instance = await WebAssembly.instantiate(workerData.module, {});
  const x = instance.exports;
  parentPort.on("message", ({ src, keys, ecma }) => {
    const mem = () => new Uint8Array(x.memory.buffer);
    mem().set(src, x.srcPtr());
    mem().set(keys, x.keysPtr());
    const t0 = performance.now();
    let n, trapped = null;
    try {
      n = x.runBatch(src.length, keys.length, ecma, SEED);
    } catch (e) {
      trapped = String(e);
    }
    const ms = performance.now() - t0;
    const out = trapped ? "" : new TextDecoder().decode(new Uint8Array(x.memory.buffer, x.outPtr(), n).slice());
    parentPort.postMessage({ ms, out, trapped });
  });
} else {
  const HERE = path.dirname(fileURLToPath(import.meta.url));
  const [suite, ...names] = process.argv.slice(2);
  const corpus = `${process.env.BASIC_CORPUS || `${HOME}/build/basic-corpus`}/${suite}`;
  const outDir = `${HOME}/build/roc-apps/gen/basic-wasm/${suite}`;
  mkdirSync(outDir, { recursive: true });

  // basic/gen.py's lit(): a carriage return is dropped, a newline and a tab
  // kept, and any other character outside printable ASCII becomes a space.
  const lit = (text) => {
    let s = "";
    for (const ch of text) {
      const c = ch.codePointAt(0);
      if (ch === "\r") continue;
      s += ch === "\n" || ch === "\t" ? ch : c < 32 || c > 126 ? " " : ch;
    }
    return new TextEncoder().encode(s);
  };
  const read = (p) => new TextDecoder().decode(readFileSync(p));
  const first = (paths) => paths.find((p) => existsSync(p));

  const t0 = performance.now();
  const module = await WebAssembly.compile(readFileSync(WASM));
  console.log(`wasm module compiled in ${(performance.now() - t0).toFixed(1)} ms (${WASM})`);

  let worker = null;
  const fresh = () => (worker = new Worker(fileURLToPath(import.meta.url), { workerData: { module } }));
  fresh();

  const runOne = (job) =>
    new Promise((resolve) => {
      const timer = setTimeout(() => {
        worker.terminate();
        fresh();
        resolve({ ms: LIMIT_MS, out: "", timeout: true });
      }, LIMIT_MS);
      worker.once("message", (r) => {
        clearTimeout(timer);
        resolve(r);
      });
      worker.postMessage(job);
    });

  for (const name of names) {
    const listing = first([`${corpus}/${name}.bas`, `${corpus}/${name}.BAS`]);
    if (!listing) {
      console.log(`${name.padEnd(16)} no listing`);
      continue;
    }
    const ours = `${HERE}/nbs-input/${name}.in`;
    const keysPath = suite === "nbs" && existsSync(ours) && read(ours) !== "" ? ours : first([`${corpus}/${name}.input`, `${corpus}/${name}.in`]);
    const keys = keysPath ? lit(read(keysPath)) : new Uint8Array();
    const r = await runOne({ src: lit(read(listing)), keys, ecma: suite === "nbs" ? 1 : 0 });
    writeFileSync(`${outDir}/${name}.out`, r.out);
    const mark = r.timeout ? "TIMEOUT" : r.trapped ? `TRAP ${r.trapped}` : r.ms > SLOW_MS ? "SLOW" : "";
    console.log(`${name.padEnd(16)} ${r.ms.toFixed(1).padStart(9)} ms  ${String(Buffer.byteLength(r.out)).padStart(6)} bytes  ${mark}`);
  }
  await worker.terminate();
}
