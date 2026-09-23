// race -- two computers with different weights, over many deals.
//
//   A=danger=40 B=danger=0 DEALS=40 node fasttrack/web/race.mjs <build-dir>
//
// A weight spec is `danger=<n>,out=<n>,home=<n>,hop=<n>,pen=<n>,back4=<n>`
// (Agent.Weights, in the agent's units: a step is 4, except hop, pen and
// back4, which are steps, back4 0 meaning no backwards 4); a factor left out
// is Agent.default_weights' (danger 0, out 0, home 10, hop 1, pen 4, back4 6,
// and Agent.default_regions). `regions=1` plays by Steve's regions of the
// board instead of by steps left; `r_pen`, `r_out`, `r_l34`, `r_ft`,
// `r_bull`, `r_enemy`, `r_range`, `r_safe` and `r_tuck` are their values.
// Every deal is played twice, as abab and baba, so neither side keeps the
// seats that move first; with DEALS=40 that is 80 games. The games are split
// between two worker threads, one per core. A game past CAP clicks is a draw.
//
// It prints A's share of the decided games, with its standard error.
import { readFileSync } from "node:fs";
import { Worker, isMainThread, parentPort, workerData } from "node:worker_threads";
import vm from "node:vm";

const FACTORS = {
  danger: 0, out: 1, home: 2, hop: 3, pen: 4, back4: 5,
  // Agent.Regions, in order: on (1 for the regions, 0 for the distance), then
  // each region's value.
  regions: 6, r_pen: 7, r_out: 8, r_l34: 9, r_ft: 10, r_bull: 11, r_enemy: 12, r_range: 13, r_safe: 14, r_tuck: 15,
};
const COLORS = ["red", "blue", "green", "purple"];

function parse(spec) {
  const w = [0, 0, 10, 1, 4, 6, 0, -68, -44, -62, -50, -72, -76, -28, -2, 4];
  for (const part of (spec ?? "").split(",").filter(Boolean)) {
    const [name, value] = part.split("=");
    if (!(name in FACTORS)) throw new Error(`race: no factor ${name}`);
    w[FACTORS[name]] = Number(value);
  }
  return w;
}

// One game: seats 0..3 take the weights `order` names, "abab" or "baba".
function play(FastTrack, module, seed, order, weights, cap) {
  const g = FastTrack.game(new WebAssembly.Instance(module, {}));
  g.start(seed, 0, FastTrack.seatBits("cccc"));
  [...order].forEach((side, seat) => weights[side].forEach((v, factor) => g.tune(seat, factor, v)));
  let view = g.view();
  let clicks = 0;
  while (view.winner === "" && clicks < cap) {
    g.click(view.tick);
    view = g.view();
    clicks++;
  }
  return view.winner === "" ? "draw" : order[COLORS.indexOf(view.winner)];
}

if (isMainThread) {
  const dir = process.argv[2];
  if (!dir) { console.error("usage: A=<spec> B=<spec> node race.mjs <build-dir>"); process.exit(2); }
  const deals = Number(process.env.DEALS ?? 40);
  const first = Number(process.env.FIRST ?? 1);
  const weights = { a: parse(process.env.A), b: parse(process.env.B) };
  const jobs = [];
  for (let seed = first; seed < first + deals; seed++) for (const order of ["abab", "baba"]) jobs.push({ seed, order });
  const started = Date.now();
  const halves = [jobs.filter((_, i) => i % 2 === 0), jobs.filter((_, i) => i % 2 === 1)];
  const results = (await Promise.all(halves.map((part) => new Promise((resolve, reject) => {
    const w = new Worker(new URL(import.meta.url), { workerData: { dir, jobs: part, weights, cap: Number(process.env.CAP ?? 20000) } });
    w.on("message", resolve);
    w.on("error", reject);
  })))).flat();
  const count = (x) => results.filter((r) => r === x).length;
  const a = count("a"), b = count("b"), draws = count("draw");
  const n = a + b;
  const p = n ? a / n : 0;
  const se = n ? Math.sqrt(p * (1 - p) / n) : 0;
  console.log(`A {${process.env.A ?? ""}} vs B {${process.env.B ?? ""}}: A won ${a}, B won ${b}, ${draws} draws -- A ${(100 * p).toFixed(1)}% +- ${(100 * se).toFixed(1)} (${((Date.now() - started) / 1000).toFixed(0)} s)`);
} else {
  const { dir, jobs, weights, cap } = workerData;
  const context = vm.createContext({ TextDecoder, DataView, Uint8Array, console });
  vm.runInContext(readFileSync(`${dir}/roc_glue.js`, "utf8") + "\nglobalThis.RocGlue = RocGlue;", context);
  vm.runInContext(readFileSync(new URL("./fasttrack.js", import.meta.url), "utf8") + "\nglobalThis.FastTrack = FastTrack;", context);
  const module = new WebAssembly.Module(readFileSync(`${dir}/fasttrack.wasm`));
  parentPort.postMessage(jobs.map(({ seed, order }) => play(context.FastTrack, module, seed, order, weights, cap)));
}
