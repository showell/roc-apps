// wasm_bench.ts — times the page's solve in the browser's engine: node
// drives two solver.wasm modules, the Zig reference's (zig/wasm.zig) and the
// Roc one the page serves (src/wasm.zig), through the same door main.ts
// calls, solveShift(seed), over the gold's 20 seeds, each solved `rounds`
// times after one warm-up pass, and prints each one's milliseconds a shift
// and their ratio. Run by `zig build wasm-bench` in delivery/:
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

function msPerShift(solver: SolverWasm): number {
  for (const seed of seeds) solver.solveShift(seed);
  const t0 = performance.now();
  for (let r = 0; r < rounds; r++) for (const seed of seeds) solver.solveShift(seed);
  return (performance.now() - t0) / (rounds * seeds.length);
}

const reference = await load(process.argv[2]);
const roc = await load(process.argv[3]);
const zigMs = msPerShift(reference);
const rocMs = msPerShift(roc);
console.log(`wasm under node, ${rounds * seeds.length} solves each: Zig ${zigMs.toFixed(1)} ms a shift, Roc ${rocMs.toFixed(1)} ms a shift, Roc/Zig ${(rocMs / zigMs).toFixed(2)}x`);
