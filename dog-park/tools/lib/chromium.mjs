// Headless Chromium for the page's own checks (tools/page_check.mjs) and
// its landing-page picture (tools/card_shot.mjs). There is no Playwright
// package on the box, so this speaks the browser's DevTools protocol over
// the WebSocket that Node has built in, as site/check_mobile.mjs does.
//
//   withBrowser(async (link) => { const page = await tab(link, {...}); ... })
import { spawn } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CHROME = `${process.env.HOME}/.cache/ms-playwright/chromium-1140/chrome-linux/chrome`;

export const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

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

/** A browser on a fresh profile for `use(link)`, killed and its profile removed after. */
export async function withBrowser(use) {
  const profile = mkdtempSync(join(tmpdir(), "dog-park-chromium-"));
  const { browser, address } = startBrowser(profile);
  try {
    const link = await connect(await address);
    await use(link);
    link.socket.close();
  } finally {
    browser.removeAllListeners("exit");
    browser.kill("SIGKILL");
    await sleep(300);
    rmSync(profile, { recursive: true, force: true });
  }
}

/**
 * A fresh tab `width` by `height`, `before` a script run in each document
 * it loads before the page's own: its console said into `said` ({ level,
 * text }), its uncaught exceptions into `thrown`.
 */
export async function tab(link, { width, height, before }) {
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

export async function evaluate(page, expression) {
  const { result, exceptionDetails } = await page.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

/** `url` loaded in the tab, and a moment for the page to start. */
export async function load(link, page, url) {
  let done = null;
  const loaded = new Promise((d) => { done = d; });
  link.on("Page.loadEventFired", (_, from) => { if (from === page.session) done(); });
  await page.send("Page.navigate", { url });
  await loaded;
  await sleep(1500);
}

/**
 * The dog of `level`'s first layout (1-based) nearest the screen's middle,
 * on screen, { id, x, y }: the page opens on the world's centre, and its own
 * physics.js says where the layout puts each dog.
 */
export const nearestDog = (page, level) => evaluate(page, `(async () => {
  const { instantiatePhysics } = await import("./physics.js");
  const p = await instantiatePhysics(await fetch("physics.wasm"));
  p.reset(${level - 1});
  const world = p.raw.tilePx() * p.raw.worldTiles();
  const left = Math.round(world / 2 - innerWidth / 2);
  const top = Math.round(world / 2 - innerHeight / 2);
  const dogs = p.critters().dogs.map((d) => ({ id: d.id, x: d.x / 256 - left, y: d.y / 256 - top }));
  dogs.sort((a, b) => Math.hypot(a.x - innerWidth / 2, a.y - innerHeight / 2) - Math.hypot(b.x - innerWidth / 2, b.y - innerHeight / 2));
  return dogs[0];
})()`);

/** A mouse drag from `from` along `path`, a list of { dx, dy } from it, a step every 70 ms. */
export async function drag(page, from, path) {
  const mouse = (type, x, y) => page.send("Input.dispatchMouseEvent", { type, x, y, button: "left", buttons: type === "mouseReleased" ? 0 : 1, clickCount: 1 });
  await mouse("mousePressed", from.x, from.y);
  for (const p of path) {
    await mouse("mouseMoved", from.x + p.dx, from.y + p.dy);
    await sleep(70);
  }
  const end = path.at(-1) ?? { dx: 0, dy: 0 };
  await mouse("mouseReleased", from.x + end.dx, from.y + end.dy);
}

/** A straight line of `steps` steps to (dx, dy), for `drag`. */
export const line = (dx, dy, steps) => Array.from({ length: steps }, (_, k) => ({ dx: (dx * (k + 1)) / steps, dy: (dy * (k + 1)) / steps }));

/** The tab as it shows now, saved as a PNG at `file`. */
export async function shot(page, file) {
  const { data } = await page.send("Page.captureScreenshot", { format: "png" });
  writeFileSync(file, Buffer.from(data, "base64"));
}
