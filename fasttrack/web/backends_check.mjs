// backends_check -- the LLVM build and the dev build must play the same game.
//
//   node fasttrack/web/backends_check.mjs <llvm-dir> <dev-dir>
//
// Both builds come from the same source, so four computers dealt the same
// cards must make the same clicks. Each game here is played in lockstep, one
// build against the other, comparing the board and the page's text after
// every click, to the end: solo, then partnerships of each style.
//
// **WHY IT EXISTS.** The nightly this page is built with has miscompiled it
// both ways: the wasm32 LLVM build let a loop's pass write into a list the
// loop still compared against (the computer's distance tables came out all
// "far"), and the dev build dropped a string from an interpolation. Each
// produced a page that ran without complaint. A difference fails the build,
// and says after how many clicks and what each build showed.
import { readFileSync } from "node:fs";
import vm from "node:vm";

const [llvmDir, devDir] = process.argv.slice(2);
if (!devDir) { console.error("usage: node backends_check.mjs <llvm-dir> <dev-dir>"); process.exit(2); }

function load(dir) {
  const ctx = vm.createContext({ TextDecoder, DataView, Uint8Array, console });
  vm.runInContext(readFileSync(`${dir}/roc_glue.js`, "utf8") + "\nglobalThis.RocGlue = RocGlue;", ctx);
  vm.runInContext(readFileSync(new URL("./fasttrack.js", import.meta.url), "utf8") + "\nglobalThis.FastTrack = FastTrack;", ctx);
  return { F: ctx.FastTrack, module: new WebAssembly.Module(readFileSync(`${dir}/fasttrack.wasm`)) };
}

const text = (v) => v.nodes.filter((n) => n.tag === "").map((n) => n.text).join(" | ");
const board = (v) => v.slots.map((s, i) => (s.piece ? `${i}:${s.piece}` : "")).filter(Boolean).join(" ");

const builds = [load(llvmDir), load(devDir)];
let failed = false;
for (const [seed, teams] of [[1, 0], [2, 1], [3, 2]]) {
  const games = builds.map(({ F, module }) => {
    const g = F.game(new WebAssembly.Instance(module, {}));
    g.start(seed, 0, F.seatBits("cccc"), teams);
    return g;
  });
  let views = games.map((g) => g.view());
  let clicks = 0;
  for (; clicks < 20000; clicks++) {
    const [a, b] = views;
    if (board(a) !== board(b) || text(a) !== text(b)) {
      console.log(`FAIL: seed ${seed} teams ${teams}: the builds differ after ${clicks} clicks`);
      console.log(`  LLVM: ${text(a)}\n        ${board(a)}\n  dev:  ${text(b)}\n        ${board(b)}`);
      failed = true;
      break;
    }
    if (!a.tick) break;
    games.forEach((g, i) => g.click(views[i].tick));
    views = games.map((g) => g.view());
  }
  if (!failed) console.log(`seed ${seed} teams ${teams}: the same for ${clicks} clicks, ${views[0].winner || "no winner"}`);
  if (failed) break;
}
process.exit(failed ? 1 : 0);
