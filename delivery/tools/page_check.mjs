// page_check.mjs plays the served page in headless Chromium. It loads it
// and checks that the solver.wasm the page fetched is the one the gold
// judged (its SHA-256 is `wasm`'s), that the first shift's map is drawn,
// that S shuffles to a new shift (a second solve), that A steps the solve's
// replay and that space plays the day; and it fails on any console error or
// uncaught exception. It saves a shot after each step.
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
// How many of the canvas's pixels differ from its corner's: a drawn map has
// many, a blank canvas none.
const drawn = (page) => evaluate(page, `(() => {
  const c = document.querySelector("canvas");
  if (!c) return -1;
  const d = c.getContext("2d").getImageData(0, 0, c.width, c.height).data;
  let n = 0;
  for (let i = 0; i < d.length; i += 4 * 97) if (d[i] !== d[0] || d[i + 1] !== d[1] || d[i + 2] !== d[2]) n++;
  return n;
})()`);

const want = createHash("sha256").update(readFileSync(wasm)).digest("hex");
await withBrowser(async (link) => {
  const page = await tab(link, { width: 1100, height: 780 });
  await load(link, page, url);
  const served = await evaluate(page, `(async () => {
    const bytes = await (await fetch("solver.wasm")).arrayBuffer();
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
  })()`);
  const fetched = await evaluate(page, `performance.getEntriesByType("resource").map((e) => e.name).filter((n) => n.endsWith("solver.wasm"))`);
  check(served === want, `the page's solver.wasm is the gold-judged one (sha256 ${want.slice(0, 16)})`);
  check(fetched.length === 1 && fetched[0] === new URL("solver.wasm", url).href, `the page fetched it from beside itself (${fetched.join(", ") || "none"})`);
  const first = await drawn(page);
  check(first > 100, `the first shift's map is drawn (${first} sampled pixels off the background)`);
  await shot(page, join(shots, "first.png"));

  await press(page, "s", "KeyS");
  await sleep(2500);
  const second = await drawn(page);
  check(second > 100, `S shuffles, and the second shift's map is drawn (${second})`);
  await shot(page, join(shots, "shuffled.png"));

  for (let k = 0; k < 3; k++) {
    await press(page, "a", "KeyA");
    await sleep(200);
  }
  check((await drawn(page)) > 100, "A steps the solve's replay");
  await shot(page, join(shots, "replay.png"));

  await press(page, "b", "KeyB");
  await press(page, " ", "Space");
  await sleep(2500);
  check((await drawn(page)) > 100, "space plays the day");
  await shot(page, join(shots, "playing.png"));
  check(errorsOf(page).length === 0, `no console error or exception (${errorsOf(page).join(" | ") || "none"})`);
});
console.log(`page_check: ${failures.length ? `${failures.length} failed` : "every check passed"}; shots in ${shots}`);
process.exit(failures.length ? 1 : 0);
