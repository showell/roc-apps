// page_check.mjs plays the served page in headless Chromium: it loads it,
// drags the dog nearest the screen's middle with the mouse, and checks that
// the browser kept the park and that a reload picks it up; then it loads it
// again with localStorage refusing every use, and checks that the game
// plays all the same. It fails on any console error or uncaught exception,
// and saves a shot of the page after the drag (dragged.png) and with
// storage blocked (blocked.png).
//
//   node dog_park/tools/page_check.mjs <page url> <shots folder>
//
// dog_park/build.shale runs it on the dev channel's /dog-park/ after the
// page is published there. There is no Playwright package on the box, so
// this speaks the browser's DevTools protocol over the WebSocket that Node
// has built in, as site/check_mobile.mjs does.
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CHROME = `${process.env.HOME}/.cache/ms-playwright/chromium-1140/chrome-linux/chrome`;
const [url, shots] = process.argv.slice(2);
if (!url || !shots) {
  console.error("usage: page_check.mjs <page url> <shots folder>");
  process.exit(2);
}
mkdirSync(shots, { recursive: true });
const sleep = (ms) => new Promise((done) => setTimeout(done, ms));
const width = 1000;
const height = 700;

function startBrowser(profile) {
  const browser = spawn(CHROME, [
    "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars", "--mute-audio",
    "--remote-debugging-port=0", `--user-data-dir=${profile}`, "about:blank",
  ], { stdio: ["ignore", "ignore", "pipe"] });
  const address = new Promise((found, refused) => {
    let said = "";
    browser.stderr.on("data", (chunk) => {
      said += chunk;
      const seen = said.match(/DevTools listening on (ws:\S+)/);
      if (seen) found(seen[1]);
    });
    browser.on("error", refused);
    browser.on("exit", (code) => refused(new Error(`chromium exited ${code}: ${said}`)));
  });
  return { browser, address };
}

async function connect(address) {
  const socket = new WebSocket(address);
  await new Promise((open, refused) => { socket.onopen = open; socket.onerror = () => refused(new Error("no DevTools socket")); });
  let lastId = 0;
  const waiting = new Map();
  const hearers = new Map();
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    if (message.id) {
      const { answer, refuse } = waiting.get(message.id);
      waiting.delete(message.id);
      message.error ? refuse(new Error(JSON.stringify(message.error))) : answer(message.result);
    } else {
      for (const hear of hearers.get(message.method) ?? []) hear(message.params, message.sessionId);
    }
  };
  return {
    socket,
    on: (method, hear) => hearers.set(method, [...(hearers.get(method) ?? []), hear]),
    send: (method, params = {}, sessionId) => new Promise((answer, refuse) => {
      const id = ++lastId;
      waiting.set(id, { answer, refuse });
      socket.send(JSON.stringify({ id, method, params, sessionId }));
    }),
  };
}

// A fresh tab: its console said into `said` ({ level, text }), its uncaught
// exceptions into `thrown`.
async function tab(link, before) {
  const { targetId } = await link.send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await link.send("Target.attachToTarget", { targetId, flatten: true });
  const page = { session: sessionId, send: (m, p = {}) => link.send(m, p, sessionId), said: [], thrown: [] };
  link.on("Runtime.consoleAPICalled", (p, from) => {
    if (from === sessionId) page.said.push({ level: p.type, text: p.args.map((a) => a.value ?? a.description ?? "").join(" ") });
  });
  link.on("Runtime.exceptionThrown", (p, from) => {
    if (from === sessionId) page.thrown.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text);
  });
  for (const domain of ["Page", "Runtime"]) await page.send(`${domain}.enable`);
  await page.send("Emulation.setDeviceMetricsOverride", { width, height, deviceScaleFactor: 1, mobile: false });
  if (before) await page.send("Page.addScriptToEvaluateOnNewDocument", { source: before });
  return page;
}

async function evaluate(page, expression) {
  const { result, exceptionDetails } = await page.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

async function load(link, page) {
  let done = null;
  const loaded = new Promise((d) => { done = d; });
  link.on("Page.loadEventFired", (_, from) => { if (from === page.session) done(); });
  await page.send("Page.navigate", { url });
  await loaded;
  await sleep(1500);
}

// The dog of Level One's first layout nearest the screen's middle, on
// screen: the page opens on the world's centre, and its own physics.js
// says where the layout puts each dog.
const nearestDog = `(async () => {
  const { instantiatePhysics } = await import("./physics.js");
  const p = await instantiatePhysics(await fetch("physics.wasm"));
  p.reset(0);
  const world = p.raw.tilePx() * p.raw.worldTiles();
  const left = Math.round(world / 2 - innerWidth / 2);
  const top = Math.round(world / 2 - innerHeight / 2);
  const dogs = p.critters().dogs.map((d) => ({ id: d.id, x: d.x / 256 - left, y: d.y / 256 - top }));
  dogs.sort((a, b) => Math.hypot(a.x - innerWidth / 2, a.y - innerHeight / 2) - Math.hypot(b.x - innerWidth / 2, b.y - innerHeight / 2));
  return dogs[0];
})()`;

async function drag(page, from, dx, dy, steps) {
  const mouse = (type, x, y) => page.send("Input.dispatchMouseEvent", { type, x, y, button: "left", buttons: type === "mouseReleased" ? 0 : 1, clickCount: 1 });
  await mouse("mousePressed", from.x, from.y);
  for (let k = 1; k <= steps; k++) {
    await mouse("mouseMoved", from.x + (dx * k) / steps, from.y + (dy * k) / steps);
    await sleep(70);
  }
  await mouse("mouseReleased", from.x + dx, from.y + dy);
}

async function shot(page, name) {
  const { data } = await page.send("Page.captureScreenshot", { format: "png" });
  writeFileSync(join(shots, name), Buffer.from(data, "base64"));
}

const failures = [];
const check = (ok, what) => {
  console.log(`${ok ? "PASS" : "FAIL"} ${what}`);
  if (!ok) failures.push(what);
};
const errorsOf = (page) => [...page.thrown, ...page.said.filter((s) => s.level === "error").map((s) => s.text)];
const keptPark = (page) => evaluate(page, `localStorage.getItem("dogpark.park.1")`);

const profile = mkdtempSync(join(tmpdir(), "dog-park-check-"));
const { browser, address } = startBrowser(profile);
try {
  const link = await connect(await address);

  // ── storage kept ─────────────────────────────────────────────────────────
  const page = await tab(link);
  await load(link, page);
  check(page.said.some((s) => /level 1 of 1: a new park, 16 dogs and 2 cows/.test(s.text)), "a first load lays out Level One");
  const dog = await evaluate(page, nearestDog);
  await drag(page, dog, 120, 40, 12);
  await sleep(1500);
  const kept = await keptPark(page);
  check(typeof kept === "string" && kept.startsWith("dogpark park 1\nlevel 1\n"), "the drag's park is kept in localStorage");
  const dogLine = (park) => (park ?? "").split("\n").find((l) => l.startsWith(`dog ${dog.id} `));
  const laidOut = await evaluate(page, `(async () => { const { instantiatePhysics } = await import("./physics.js"); const p = await instantiatePhysics(await fetch("physics.wasm")); p.reset(0); return p.writePark(0); })()`);
  check(dogLine(kept) !== undefined && dogLine(kept) !== dogLine(laidOut), `dog ${dog.id} was dragged: "${dogLine(laidOut)}" is now "${dogLine(kept)}"`);
  await shot(page, "dragged.png");
  const tickOf = (park) => Number(/\ntick (\d+)\n/.exec(park ?? "")?.[1]);
  page.said.length = 0;
  // The reload keeps the park once more as the page goes (pagehide), at a
  // later tick (the let-go timer ran on), with nothing moved since.
  await load(link, page);
  const again = await keptPark(page);
  check(tickOf(again) >= tickOf(kept) && page.said.some((s) => s.text.includes(`the park kept at tick ${tickOf(again)}`)), `a reload picks the park up, kept at tick ${tickOf(again)} (the drag's at ${tickOf(kept)})`);
  check(dogLine(again) === dogLine(kept), `after the reload dog ${dog.id} is where the drag left it`);
  check(errorsOf(page).length === 0, `no console error or exception (${errorsOf(page).join(" | ") || "none"})`);

  // ── storage blocked ─────────────────────────────────────────────────────
  const blocked = await tab(link, `Object.defineProperty(window, "localStorage", { get() { throw new DOMException("blocked", "SecurityError"); } });`);
  await load(link, blocked);
  check(blocked.said.some((s) => /level 1 of 1: a new park, 16 dogs and 2 cows/.test(s.text)), "with storage blocked, a load lays out Level One");
  check(blocked.said.filter((s) => s.text.includes("can't read the browser's storage")).length === 1, "with storage blocked, the page says so once");
  const before = await evaluate(blocked, `document.getElementById("score").textContent`);
  await drag(blocked, dog, 120, 40, 12);
  await sleep(800);
  await shot(blocked, "blocked.png");
  check(errorsOf(blocked).length === 0, `with storage blocked, no console error or exception (${errorsOf(blocked).join(" | ") || "none"})`);
  check(typeof before === "string" && before.length > 0, `the score shows ("${before}")`);
  link.socket.close();
} finally {
  browser.removeAllListeners("exit");
  browser.kill("SIGKILL");
  await sleep(300);
  rmSync(profile, { recursive: true, force: true });
}
console.log(`page_check: ${failures.length ? `${failures.length} failed` : "every check passed"}; shots in ${shots}`);
process.exit(failures.length ? 1 : 0);
