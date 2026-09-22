// arena -- the computer against the naive player, over many deals.
//
//   GAMES=40 node fasttrack/web/arena.mjs <build-dir>
//   GAMES=20 SEATS=cccc node fasttrack/web/arena.mjs <build-dir>
//
// Every game is played out through the built wasm and the generated reader,
// the way the page plays a computer's seat: send the view's tick until
// someone wins. With no SEATS, each deal is played twice, as cncn and ncnc
// (c the computer, n the naive player that takes the first choice offered),
// so neither side keeps the seats that move first. A game that runs past
// CAP clicks is a draw.
//
// It prints who won how often, how long games ran, and the time a click
// takes, on average and at worst -- a computer click includes the whole
// turn's search.
import { readFileSync } from "node:fs";
import vm from "node:vm";

const dir = process.argv[2];
if (!dir) { console.error("usage: node arena.mjs <build-dir>"); process.exit(2); }
const GAMES = Number(process.env.GAMES ?? 20);
const CAP = Number(process.env.CAP ?? 20000);
const PATTERNS = process.env.SEATS ? [process.env.SEATS] : ["cncn", "ncnc"];
const COLORS = ["red", "blue", "green", "purple"];

const context = vm.createContext({ TextDecoder, DataView, Uint8Array, console });
vm.runInContext(readFileSync(`${dir}/roc_glue.js`, "utf8") + "\nglobalThis.RocGlue = RocGlue;", context);
vm.runInContext(readFileSync(new URL("./fasttrack.js", import.meta.url), "utf8") + "\nglobalThis.FastTrack = FastTrack;", context);
const { FastTrack } = context;
const module = new WebAssembly.Module(readFileSync(`${dir}/fasttrack.wasm`));

const wins = {};
const clickTime = { c: 0, n: 0 };
const clickCount = { c: 0, n: 0 };
const slowest = { c: 0, n: 0 };
let draws = 0;
const lengths = [];

for (let seed = 1; seed <= GAMES; seed++) {
  for (const seats of PATTERNS) {
    // A fresh instance a game, so one game's memory is not the next's.
    const g = FastTrack.game(new WebAssembly.Instance(module, {}));
    g.start(seed, 0, FastTrack.seatBits(seats));
    let view = g.view();
    let clicks = 0;
    while (view.winner === "" && clicks < CAP) {
      if (!view.tick) throw new Error(`seed ${seed} ${seats}: no tick and no winner`);
      const kind = seats[FastTrack_active(view)];
      const t0 = performance.now();
      g.click(view.tick);
      view = g.view();
      const ms = performance.now() - t0;
      clickTime[kind] += ms;
      slowest[kind] = Math.max(slowest[kind], ms);
      clickCount[kind]++;
      clicks++;
    }
    if (view.winner === "") { draws++; continue; }
    const kind = seats[COLORS.indexOf(view.winner)];
    wins[kind] = (wins[kind] ?? 0) + 1;
    lengths.push(clicks);
  }
}

// Whose turn it is, read off the page: the console names the color.
function FastTrack_active(view) {
  const line = view.nodes.find((n) => n.tag === "" && n.text.startsWith("the computer is playing "));
  if (!line) throw new Error("arena: no seat named on the page");
  return COLORS.indexOf(line.text.slice("the computer is playing ".length));
}

const games = PATTERNS.length * GAMES;
const avg = (xs) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
const name = { c: "computer", n: "naive" };
for (const kind of Object.keys(name)) {
  if (!clickCount[kind]) continue;
  console.log(`${name[kind]}: ${wins[kind] ?? 0} of ${games} games won, ${(clickTime[kind] / clickCount[kind]).toFixed(2)} ms a click, slowest ${slowest[kind].toFixed(1)} ms`);
}
console.log(`${draws} draws; a game took ${avg(lengths).toFixed(0)} clicks on average`);
