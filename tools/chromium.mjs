// Headless Chromium for every page tool in this repository: the mobile check
// (site/check_mobile.mjs), the books' check (book_builder/tools/book_check.mjs)
// and the games' page checks and landing-page pictures (delivery/tools/,
// dog-park/tools/). There is no Playwright package on the box, so a tool
// speaks the browser's DevTools protocol over the WebSocket that Node has
// built in. This file is the one home for how the browser is started.
//
//   withBrowser(async (link) => { const page = await tab(link, {...}); ... })
//
// or, for a tool with a DevTools connection of its own,
//
//   const browser = startBrowser({ args: ["--window-size=1400,900"] });
//   const socket = new WebSocket(await browser.address); ... await browser.close();
//
// Shale runs every program confined (Landlock): it may write only under its
// mounts, the run's own TMPDIR and build:cache. So everything the browser
// writes stays in one folder under TMPDIR, made for the launch and removed
// after it:
// - `--disable-dev-shm-usage` makes its shared memory in TMPDIR, not
//   /dev/shm, which is outside the confinement; without it the browser dies
//   on its first shared memory, by SIGTRAP.
// - HOME, for the browser alone, is a folder of that one, so its crash
//   reporter's database is never ~/.config/chromium's and its certificate
//   store never ~/.pki/nssdb (each a refused open without it). XDG_CONFIG_HOME
//   is set to that home's .config as well, so one inherited from the caller
//   can't lead it back. `--disable-crash-reporter` and `--disable-breakpad`
//   don't keep the crash reporter out of ~/.config.
// - `--user-data-dir` is a folder of that one too, a fresh profile each time.
// roc-screensaver's tools/web_shots.mjs keeps a copy of these flags and this
// environment, on purpose, since it is another repository.
import { spawn } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Playwright's browsers are where PLAYWRIGHT_BROWSERS_PATH says (Shale sets
// it, build:cache/ms-playwright, for every program it runs), else under
// ~/.cache/ms-playwright, where `npx playwright install chromium` puts them.
const BROWSERS = process.env.PLAYWRIGHT_BROWSERS_PATH || `${process.env.HOME}/.cache/ms-playwright`;

const FLAGS = [
  "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars", "--mute-audio",
  "--disable-dev-shm-usage", "--remote-debugging-port=0",
];

export const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

/** The newest Chromium Playwright installed in BROWSERS; the tool stops, saying where it looked, when there is none. */
export function chromiumPath() {
  const installed = existsSync(BROWSERS)
    ? readdirSync(BROWSERS)
      .map((name) => ({ name, build: Number((name.match(/^chromium-(\d+)$/) ?? [])[1]) }))
      .filter((entry) => entry.build > 0 && existsSync(`${BROWSERS}/${entry.name}/chrome-linux/chrome`))
      .sort((a, b) => b.build - a.build)
    : [];
  if (installed.length === 0) {
    console.error(`chromium: no Chromium in ${BROWSERS}: run \`npx playwright install chromium\` with PLAYWRIGHT_BROWSERS_PATH set to it`);
    process.exit(2);
  }
  return `${BROWSERS}/${installed[0].name}/chrome-linux/chrome`;
}

/**
 * A headless browser on a fresh profile, `args` added to its flags.
 * `address` is a promise of its DevTools WebSocket's address, refused if the
 * browser exits first; `close()` kills it and removes its folder.
 */
export function startBrowser({ chrome = chromiumPath(), args = [] } = {}) {
  const folder = mkdtempSync(join(tmpdir(), "chromium-"));
  const profile = join(folder, "profile");
  const home = join(folder, "home");
  mkdirSync(profile);
  mkdirSync(join(home, ".config"), { recursive: true });
  const browser = spawn(chrome, [...FLAGS, `--user-data-dir=${profile}`, ...args, "about:blank"], {
    stdio: ["ignore", "ignore", "pipe"],
    env: { ...process.env, HOME: home, XDG_CONFIG_HOME: join(home, ".config") },
  });
  const address = new Promise((found, refused) => {
    let said = "";
    browser.stderr.on("data", (chunk) => {
      said += chunk;
      const seen = said.match(/DevTools listening on (ws:\S+)/);
      if (seen) found(seen[1]);
    });
    browser.on("error", refused);
    browser.on("exit", (code, signal) => refused(new Error(`chromium exited ${code ?? signal}: ${said}`)));
  });
  const close = async () => {
    browser.removeAllListeners("exit");
    browser.kill("SIGKILL");
    await sleep(300);
    rmSync(folder, { recursive: true, force: true });
  };
  return { address, close };
}

/**
 * One DevTools connection: `send(method, params, sessionId)` answers a
 * command, and `on(method, hear)` hears every event of that method, as
 * `hear(params, sessionId)`.
 */
export async function connect(address) {
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

/** A browser for `use(link)`, killed and its folder removed after. */
export async function withBrowser(use, options) {
  const browser = startBrowser(options);
  try {
    const link = await connect(await browser.address);
    await use(link);
    link.socket.close();
  } finally {
    await browser.close();
  }
}

/**
 * A fresh tab `width` by `height`, `before` a script run in each document it
 * loads before the page's own: its console said into `said` ({ level, text }),
 * its uncaught exceptions into `thrown`.
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
