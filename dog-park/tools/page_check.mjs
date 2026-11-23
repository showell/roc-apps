// page_check.mjs plays the served page in headless Chromium: it loads it,
// drags the dog nearest the screen's middle with the mouse, and checks that
// the browser kept the park and that a reload picks it up; then it loads it
// again with localStorage refusing every use, and checks that the game
// plays all the same. It fails on any console error or uncaught exception,
// and saves a shot of the page after the drag (dragged.png) and with
// storage blocked (blocked.png).
//
//   node dog-park/tools/page_check.mjs <page url> <shots folder>
//
// dog-park/build.shale runs it on the page it stages in the dev channel,
// before the page is swapped in. The browser is the repository's tools/chromium.mjs.
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { withBrowser, tab, evaluate, load, nearestDog, drag, line, shot, sleep } from "./lib/chromium.mjs";

const [url, shots] = process.argv.slice(2);
if (!url || !shots) {
  console.error("usage: page_check.mjs <page url> <shots folder>");
  process.exit(2);
}
mkdirSync(shots, { recursive: true });
const screen = { width: 1000, height: 700 };

const failures = [];
const check = (ok, what) => {
  console.log(`${ok ? "PASS" : "FAIL"} ${what}`);
  if (!ok) failures.push(what);
};
const errorsOf = (page) => [...page.thrown, ...page.said.filter((s) => s.level === "error").map((s) => s.text)];
const keptPark = (page) => evaluate(page, `localStorage.getItem("dogpark.park.1")`);
const tickOf = (park) => Number(/\ntick (\d+)\n/.exec(park ?? "")?.[1]);

await withBrowser(async (link) => {
  // ── storage kept ─────────────────────────────────────────────────────────
  const page = await tab(link, screen);
  await load(link, page, url);
  check(page.said.some((s) => /level 1 of 1: a new park, 16 dogs and 2 cows/.test(s.text)), "a first load lays out Level One");
  const dog = await nearestDog(page, 1);
  await drag(page, dog, line(120, 40, 12));
  await sleep(1500);
  const kept = await keptPark(page);
  check(typeof kept === "string" && kept.startsWith("dogpark park 1\nlevel 1\n"), "the drag's park is kept in localStorage");
  const dogLine = (park) => (park ?? "").split("\n").find((l) => l.startsWith(`dog ${dog.id} `));
  const laidOut = await evaluate(page, `(async () => { const { instantiatePhysics } = await import("./physics.js"); const p = await instantiatePhysics(await fetch("physics.wasm")); p.reset(0); return p.writePark(0); })()`);
  check(dogLine(kept) !== undefined && dogLine(kept) !== dogLine(laidOut), `dog ${dog.id} was dragged: "${dogLine(laidOut)}" is now "${dogLine(kept)}"`);
  await shot(page, join(shots, "dragged.png"));
  page.said.length = 0;
  // The reload keeps the park once more as the page goes (pagehide), at a
  // later tick (the let-go timer ran on), with nothing moved since.
  await load(link, page, url);
  const again = await keptPark(page);
  check(tickOf(again) >= tickOf(kept) && page.said.some((s) => s.text.includes(`the park kept at tick ${tickOf(again)}`)), `a reload picks the park up, kept at tick ${tickOf(again)} (the drag's at ${tickOf(kept)})`);
  check(dogLine(again) === dogLine(kept), `after the reload dog ${dog.id} is where the drag left it`);
  check(errorsOf(page).length === 0, `no console error or exception (${errorsOf(page).join(" | ") || "none"})`);

  // ── storage blocked ─────────────────────────────────────────────────────
  const blocked = await tab(link, { ...screen, before: `Object.defineProperty(window, "localStorage", { get() { throw new DOMException("blocked", "SecurityError"); } });` });
  await load(link, blocked, url);
  check(blocked.said.some((s) => /level 1 of 1: a new park, 16 dogs and 2 cows/.test(s.text)), "with storage blocked, a load lays out Level One");
  check(blocked.said.filter((s) => s.text.includes("can't read the browser's storage")).length === 1, "with storage blocked, the page says so once");
  const before = await evaluate(blocked, `document.getElementById("score").textContent`);
  await drag(blocked, dog, line(120, 40, 12));
  await sleep(800);
  await shot(blocked, join(shots, "blocked.png"));
  check(errorsOf(blocked).length === 0, `with storage blocked, no console error or exception (${errorsOf(blocked).join(" | ") || "none"})`);
  check(typeof before === "string" && before.length > 0, `the score shows ("${before}")`);
});
console.log(`page_check: ${failures.length ? `${failures.length} failed` : "every check passed"}; shots in ${shots}`);
process.exit(failures.length ? 1 : 0);
