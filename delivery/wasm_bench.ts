// wasm_bench.ts — times the page's solve in the browser's engine: node
// drives the solver.wasm the page serves (src/wasm.zig) through the same
// door main.ts calls, solveShift(seed), over the gold's 20 seeds, each solved
// `rounds` times after one warm-up pass. It prints the milliseconds a shift,
// the sum over the seeds of each seed's fastest solve (the least disturbed
// by other work). Run by `zig build wasm-bench` in delivery/:
//
//   node wasm_bench.mjs <solver.wasm> [rounds]

import { readFileSync } from "node:fs";

type SolverWasm = { memory: WebAssembly.Memory; solveShift: (seed: number) => number; outPtr: () => number };

const gold = JSON.parse(readFileSync("solver_gold.json", "utf8"));
const seeds: number[] = gold.shifts.map((s: { seed: number }) => s.seed);
const rounds = Number(process.argv[3] ?? "3");

async function load(path: string): Promise<SolverWasm> {
  const { instance } = await WebAssembly.instantiate(readFileSync(path), {});
  return instance.exports as unknown as SolverWasm;
}

function timed(solver: SolverWasm, seed: number): number {
  const t0 = performance.now();
  solver.solveShift(seed);
  return performance.now() - t0;
}

const roc = await load(process.argv[2]);
for (const seed of seeds) roc.solveShift(seed);
const rocBest = seeds.map(() => Infinity);
for (let r = 0; r < rounds; r++) {
  seeds.forEach((seed, i) => {
    rocBest[i] = Math.min(rocBest[i], timed(roc, seed));
  });
}
const rocMs = rocBest.reduce((s, x) => s + x, 0) / seeds.length;
console.log(`wasm under node, best of ${rounds} per seed: Roc ${rocMs.toFixed(1)} ms a shift`);
