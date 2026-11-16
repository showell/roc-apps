// Headless Chromium for the page's own check (tools/page_check.mjs). There
// is no Playwright package on the box, so this speaks the browser's DevTools
// protocol over the WebSocket that Node has built in. A copy, cut down, of
// dog-park/tools/lib/chromium.mjs, kept here so each game's folder stands
// alone.
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
  const profile = mkdtempSync(join(tmpdir(), "delivery-chromium-"));
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

/** A fresh tab `width` by `height`: its console said into `said`, its uncaught exceptions into `thrown`. */
export async function tab(link, { width, height }) {
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

/** A key pressed and let go. */
export async function press(page, key, code) {
  await page.send("Input.dispatchKeyEvent", { type: "keyDown", key, code });
  await page.send("Input.dispatchKeyEvent", { type: "keyUp", key, code });
}

/** The tab as it shows now, saved as a PNG at `file`. */
export async function shot(page, file) {
  const { data } = await page.send("Page.captureScreenshot", { format: "png" });
  writeFileSync(file, Buffer.from(data, "base64"));
}
