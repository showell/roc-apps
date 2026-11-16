// page_check.mjs plays the served page in headless Chromium. It loads it
// and checks that the solver.wasm the page fetched is the one the gold
// judged (its SHA-256 is `wasm`'s) and that the page's plans are that
// module's (each solveShift call is counted), that the first shift's map is
// drawn, that S shuffles to a new shift (a second solve, a different map),
// that A steps the solve's replay and that space plays the day; and it fails
// on any console error or uncaught exception. It saves a shot after each
// step.
//
//   node delivery/tools/page_check.mjs <page url> <solver.wasm> <shots folder>
//
// delivery/build.shale runs it on the page it stages in the dev channel,
// before the page is swapped in.
import { createHash } from "node:crypto";
import { mkdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { withBrowser, tab, evaluate, load, press, shot, sleep } from "./chromium.mjs";

const [url, wasm, shots] = process.argv.slice(2);
if (!url || !wasm || !shots) {
  console.error("usage: page_check.mjs <page url> <solver.wasm> <shots folder>");
  process.exit(2);
}
mkdirSync(shots, { recursive: true });

const failures = [];
const check = (ok, what) => {
  console.log(`${ok ? "PASS" : "FAIL"} ${what}`);
  if (!ok) failures.push(what);
};
const errorsOf = (page) => [...page.thrown, ...page.said.filter((s) => s.level === "error").map((s) => s.text)];
// How many of the canvas's pixels differ from its corner's (a drawn map has
// many, a blank canvas none), and a hash of every pixel, to tell two maps
// apart.
const drawn = (page) => evaluate(page, `(() => {
  const c = document.querySelector("canvas");
  if (!c) return { off: -1, hash: 0 };
  const d = c.getContext("2d").getImageData(0, 0, c.width, c.height).data;
  let off = 0;
  let hash = 0;
  for (let i = 0; i < d.length; i += 4) {
    if (d[i] !== d[0] || d[i + 1] !== d[1] || d[i + 2] !== d[2]) off++;
    hash = (Math.imul(hash, 31) + d[i] + d[i + 1] * 7 + d[i + 2] * 13) | 0;
  }
  return { off, hash };
})()`);
// Counts the page's calls to the solver's solveShift, in window.__solves.
const counting = `(() => {
  window.__solves = 0;
  const instantiate = WebAssembly.instantiate;
  WebAssembly.instantiate = async (...args) => {
    const made = await instantiate(...args);
    const exports = { ...made.instance.exports };
    const solve = exports.solveShift;
    exports.solveShift = (seed) => { window.__solves++; return solve(seed); };
    return { ...made, instance: { exports } };
  };
})();`;

const want = createHash("sha256").update(readFileSync(wasm)).digest("hex");
await withBrowser(async (link) => {
  const page = await tab(link, { width: 1100, height: 780, before: counting });
  await load(link, page, url);
  const fetched = await evaluate(page, `performance.getEntriesByType("resource").map((e) => e.name).filter((n) => n.endsWith("solver.wasm"))`);
  const served = await evaluate(page, `(async () => {
    const bytes = await (await fetch("solver.wasm")).arrayBuffer();
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
  })()`);
  check(served === want, `the page's solver.wasm is the gold-judged one (sha256 ${want.slice(0, 16)})`);
  check(fetched.length === 1 && fetched[0] === new URL("solver.wasm", url).href, `the page fetched it from beside itself (${fetched.join(", ") || "none"})`);
  check((await evaluate(page, "window.__solves")) === 1, "the first shift's plan is the module's: one solveShift");
  const first = await drawn(page);
  check(first.off > 10000, `the first shift's map is drawn (${first.off} pixels off the background)`);
  await shot(page, join(shots, "first.png"));

  await press(page, "s", "KeyS");
  await sleep(2500);
  const second = await drawn(page);
  check((await evaluate(page, "window.__solves")) === 2, "S solves a second shift: two solveShifts");
  check(second.off > 10000 && second.hash !== first.hash, `S shuffles, and the second shift's map is drawn, a different one (${second.off})`);
  await shot(page, join(shots, "shuffled.png"));

  for (let k = 0; k < 3; k++) {
    await press(page, "a", "KeyA");
    await sleep(200);
  }
  check((await drawn(page)).off > 10000, "A steps the solve's replay");
  await shot(page, join(shots, "replay.png"));

  await press(page, "b", "KeyB");
  await press(page, " ", "Space");
  await sleep(2500);
  check((await drawn(page)).off > 10000, "space plays the day");
  await shot(page, join(shots, "playing.png"));
  check(errorsOf(page).length === 0, `no console error or exception (${errorsOf(page).join(" | ") || "none"})`);
});
console.log(`page_check: ${failures.length ? `${failures.length} failed` : "every check passed"}; shots in ${shots}`);
process.exit(failures.length ? 1 : 0);
