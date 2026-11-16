// wasm_bench.ts — times the page's solve in the browser's engine: node
// drives two solver.wasm modules, the Zig reference's (zig/wasm.zig) and the
// Roc one the page serves (src/wasm.zig), through the same door main.ts
// calls, solveShift(seed), over the gold's 20 seeds, each solved `rounds`
// times after one warm-up pass, the two modules taking turns seed by seed so
// a busy box slows both alike. It prints each one's milliseconds a shift,
// the sum over the seeds of each seed's fastest solve (the least disturbed
// by other work), and their ratio. Run by `zig build wasm-bench` in
// delivery/:
//
//   node wasm_bench.mjs <reference.wasm> <roc.wasm> [rounds]

import { readFileSync } from "node:fs";

type SolverWasm = { memory: WebAssembly.Memory; solveShift: (seed: number) => number; outPtr: () => number };

const gold = JSON.parse(readFileSync("solver_gold.json", "utf8"));
const seeds: number[] = gold.shifts.map((s: { seed: number }) => s.seed);
const rounds = Number(process.argv[4] ?? "3");

async function load(path: string): Promise<SolverWasm> {
  const { instance } = await WebAssembly.instantiate(readFileSync(path), {});
  return instance.exports as unknown as SolverWasm;
}

function timed(solver: SolverWasm, seed: number): number {
  const t0 = performance.now();
  solver.solveShift(seed);
  return performance.now() - t0;
}

const reference = await load(process.argv[2]);
const roc = await load(process.argv[3]);
for (const seed of seeds) {
  reference.solveShift(seed);
  roc.solveShift(seed);
}
const zigBest = seeds.map(() => Infinity);
const rocBest = seeds.map(() => Infinity);
for (let r = 0; r < rounds; r++) {
  seeds.forEach((seed, i) => {
    zigBest[i] = Math.min(zigBest[i], timed(reference, seed));
    rocBest[i] = Math.min(rocBest[i], timed(roc, seed));
  });
}
const sum = (xs: number[]): number => xs.reduce((s, x) => s + x, 0);
const zigMs = sum(zigBest) / seeds.length;
const rocMs = sum(rocBest) / seeds.length;
console.log(`wasm under node, best of ${rounds} per seed: Zig ${zigMs.toFixed(1)} ms a shift, Roc ${rocMs.toFixed(1)} ms a shift, Roc/Zig ${(rocMs / zigMs).toFixed(2)}x`);
