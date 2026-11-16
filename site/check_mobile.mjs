// check_mobile.mjs loads a page in headless Chromium as a phone would, at
// 320, 360, 390 and 414 px wide (mobile emulation, deviceScaleFactor 3), and
// fails when anything on it is wider than the screen: the page scrolls
// sideways (scrollWidth past clientWidth), or an element's box or a run of its
// text passes the screen's right or left edge. What sits inside a box that
// scrolls or clips on its own (a code sample with overflow-x: auto) is held to
// that box, not to the screen, since the page itself doesn't move. Each
// offender is named by its tag, class and first words, with how far past the
// edge it reaches. A page without a viewport meta tag fails too, and so does
// one with a picture that didn't load: an <img> whose naturalWidth is 0 once
// loaded (a card's black rectangle, since the .shot style's background hides
// a 404), or an image request that failed or answered 400 or more, each named
// by its src. Each width's
// whole page is saved as phone-<width>.png, its first screen as
// phone-<width>-top.png, and with `desktop` a 1280 px shot
// (desktop-1280.png) is saved as well, for comparing a change by eye.
//
//   node site/check_mobile.mjs <page url> <shots folder> [desktop]
//
// site/check_mobile.shale runs it on the dev or staging landing page. There is
// no Playwright package on the box, so this speaks the browser's DevTools
// protocol over the WebSocket that Node has built in, as roc-screensaver's
// tools/web_shots.mjs does.
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CHROME = `${process.env.HOME}/.cache/ms-playwright/chromium-1140/chrome-linux/chrome`;
const WIDTHS = [320, 360, 390, 414];
const [url, shots, extra] = process.argv.slice(2);
if (!url || !shots || (extra !== undefined && extra !== "desktop")) {
  console.error("usage: check_mobile.mjs <page url> <shots folder> [desktop]");
  process.exit(2);
}
mkdirSync(shots, { recursive: true });
const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

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
      hearers.get(message.method)?.(message.params);
    }
  };
  return {
    socket,
    on: (method, hear) => hearers.set(method, hear),
    send: (method, params = {}, sessionId) => new Promise((answer, refuse) => {
      const id = ++lastId;
      waiting.set(id, { answer, refuse });
      socket.send(JSON.stringify({ id, method, params, sessionId }));
    }),
  };
}

// Every element and every run of text whose visible part passes the screen's
// edge. An ancestor that scrolls or clips sideways bounds what is visible of
// its contents, so a wide line inside a scrolling code sample isn't counted,
// but the sample itself is if it is wider than the screen. Only the outermost
// offender of a nested chain is reported, since its children overflow with it.
const MEASURE = `(() => {
  const screen = document.documentElement.clientWidth;
  const clips = (el) => { const o = getComputedStyle(el).overflowX; return o !== 'visible'; };
  const name = (el) => el.tagName.toLowerCase() + (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\\s+/).join('.') : '');
  const words = (text) => text.replace(/\\s+/g, ' ').trim().slice(0, 50);
  const visible = (from, left, right) => {
    for (let up = from; up && up !== document.documentElement && up !== document.body; up = up.parentElement) {
      if (clips(up)) {
        const box = up.getBoundingClientRect();
        left = Math.max(left, box.left);
        right = Math.min(right, box.right);
      }
    }
    return { left, right };
  };
  const found = [];
  const flagged = new Set();
  const report = (el, what, left, right, isText) => {
    const v = visible(isText ? el : el.parentElement, left, right);
    if (v.right <= v.left) return;
    const past = Math.max(v.right - screen, -v.left);
    if (past <= 0.5) return;
    for (let up = isText ? el : el.parentElement; up; up = up.parentElement) if (flagged.has(up)) return;
    flagged.add(el);
    found.push({ what, past: Math.round(past), left: Math.round(v.left), right: Math.round(v.right) });
  };
  for (const el of document.body.querySelectorAll('*')) {
    const box = el.getBoundingClientRect();
    if (box.width === 0 && box.height === 0) continue;
    report(el, name(el) + ' "' + words(el.textContent) + '"', box.left, box.right);
  }
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let text = walker.nextNode(); text; text = walker.nextNode()) {
    if (!text.textContent.trim()) continue;
    const range = document.createRange();
    range.selectNodeContents(text);
    for (const line of range.getClientRects()) {
      const before = found.length;
      report(text.parentElement, 'text in ' + name(text.parentElement) + ' "' + words(text.textContent) + '"', line.left, line.right, true);
      if (found.length > before) break;
    }
  }
  const viewport = document.querySelector('meta[name=viewport]');
  return {
    screen,
    scrollWidth: document.documentElement.scrollWidth,
    viewport: viewport ? viewport.getAttribute('content') : null,
    height: document.documentElement.scrollHeight,
    found,
  };
})()`;

// Every <img> on the page that has no picture once it is done loading, by its
// src as the page writes it.
const UNLOADED = `[...document.images].filter((img) => img.naturalWidth === 0).map((img) => img.getAttribute('src'))`;

async function evaluate(page, expression) {
  const { result, exceptionDetails } = await page.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true }, page.session);
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

// Loads the page at one size, waits for its images, and answers MEASURE's
// findings with the images that didn't load, saving the whole page as a shot.
async function measure(link, page, width, mobile, shot) {
  const urls = new Map();
  const failed = new Map();
  link.on("Network.requestWillBeSent", (p) => urls.set(p.requestId, p.request.url));
  link.on("Network.responseReceived", (p) => { if (p.type === "Image" && p.response.status >= 400) failed.set(p.response.url, `answered ${p.response.status}`); });
  link.on("Network.loadingFailed", (p) => { if (p.type === "Image") failed.set(urls.get(p.requestId) ?? p.requestId, p.errorText); });
  await page.send("Emulation.setDeviceMetricsOverride", { width, height: mobile ? 800 : 900, deviceScaleFactor: mobile ? 3 : 1, mobile }, page.session);
  await page.send("Emulation.setTouchEmulationEnabled", { enabled: mobile }, page.session);
  const loaded = new Promise((done) => link.on("Page.loadEventFired", done));
  await page.send("Page.navigate", { url }, page.session);
  await loaded;
  // The pictures load lazily; eager and loaded, they are measured as a reader scrolling down sees them.
  await evaluate(page, "Promise.all([...document.images].map((img) => { img.loading = 'eager'; return img.complete ? null : new Promise((done) => { img.onload = img.onerror = done; }); }))");
  await sleep(300);
  const seen = await evaluate(page, MEASURE);
  seen.images = (await evaluate(page, UNLOADED)).map((src) => `${src} (naturalWidth 0)`);
  for (const [requested, why] of failed) seen.images.push(`${requested} (${why})`);
  const { data } = await page.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true, clip: { x: 0, y: 0, width, height: seen.height, scale: 1 } }, page.session);
  writeFileSync(join(shots, shot), Buffer.from(data, "base64"));
  const top = await page.send("Page.captureScreenshot", { format: "png" }, page.session);
  writeFileSync(join(shots, shot.replace(".png", "-top.png")), Buffer.from(top.data, "base64"));
  return seen;
}

const profile = mkdtempSync(join(tmpdir(), "check-mobile-"));
const { browser, address } = startBrowser(profile);
let exitCode = 1;
try {
  const link = await connect(await address);
  const { targetId } = await link.send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await link.send("Target.attachToTarget", { targetId, flatten: true });
  const page = { send: link.send, session: sessionId };
  for (const domain of ["Page", "Runtime", "Network"]) await page.send(`${domain}.enable`, {}, page.session);
  let failures = 0;
  for (const width of WIDTHS) {
    const seen = await measure(link, page, width, true, `phone-${width}.png`);
    const scrolls = seen.scrollWidth > seen.screen;
    const bad = scrolls || seen.found.length > 0 || seen.viewport === null || seen.images.length > 0;
    console.log(`${bad ? "FAIL" : "PASS"} ${width} px: scrollWidth ${seen.scrollWidth} of ${seen.screen}, ${seen.found.length} past the edge, viewport ${seen.viewport ?? "missing"}, ${seen.images.length} images not loaded`);
    for (const f of seen.found) console.log(`  ${f.past} px past: ${f.what} (${f.left} to ${f.right})`);
    for (const image of seen.images) console.log(`  image not loaded: ${image}`);
    if (bad) failures++;
  }
  if (extra === "desktop") {
    const seen = await measure(link, page, 1280, false, "desktop-1280.png");
    console.log(`desktop 1280 px: ${seen.height} px tall, scrollWidth ${seen.scrollWidth}`);
  }
  console.log(`check_mobile: ${WIDTHS.length - failures} of ${WIDTHS.length} widths pass${failures ? "" : ", nothing past the edge, every image loaded"}; shots in ${shots}`);
  exitCode = failures ? 1 : 0;
  link.socket.close();
} finally {
  browser.removeAllListeners("exit");
  browser.kill("SIGKILL");
  await sleep(300);
  rmSync(profile, { recursive: true, force: true });
}
process.exit(exitCode);
