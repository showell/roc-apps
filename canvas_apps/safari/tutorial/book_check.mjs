// This drives the staged book in headless Chromium, the way a reader would,
// and exits non-zero if any page is wrong. It holds every page to five things:
// no console errors, no failed requests, every widget running in its frame,
// every diagram drawn, and every link in the book reaching a real place.
//
//   node book_check.mjs http://127.0.0.1:9210/tutorial.staging/ <shots folder>
//
// There is no Playwright package on the box, so this speaks the browser's
// DevTools protocol over the WebSocket that Node has built in.
import { spawn } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const CHROME = `${process.env.HOME}/.cache/ms-playwright/chromium-1140/chrome-linux/chrome`;
const WIDTH = 1400;
const HEIGHT = 900;
const [base, shots] = process.argv.slice(2);
if (!base || !shots) { console.error("usage: book_check.mjs <book url> <shots folder>"); process.exit(2); }
mkdirSync(shots, { recursive: true });

const sleep = (ms) => new Promise((done) => setTimeout(done, ms));
const failures = [];
const fail = (page, why) => failures.push(`${page}: ${why}`);

function startBrowser(profile) {
  const browser = spawn(CHROME, [
    "--headless=new", "--no-sandbox", "--disable-gpu", "--hide-scrollbars", "--mute-audio",
    "--remote-debugging-port=0", `--user-data-dir=${profile}`, `--window-size=${WIDTH},${HEIGHT}`, "about:blank",
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

// One DevTools connection: `send` answers a command, and `on` hears an event.
async function connect(address) {
  const socket = new WebSocket(address);
  await new Promise((open, refused) => {
    socket.onopen = open;
    socket.onerror = () => refused(new Error("no DevTools socket"));
  });
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

// What this page holds, read in the page. A frame's canvas is same-origin, so
// its pixels can be read from here.
const READ_PAGE = `(() => ({
  links: [...document.querySelectorAll('a[href]')].map((a) => a.getAttribute('href')),
  ids: [...document.querySelectorAll('[id]')].map((e) => e.id),
  scrollWidth: document.documentElement.scrollWidth,
  clientWidth: document.documentElement.clientWidth,
  diagrams: [...document.querySelectorAll('svg.diagram')].map((svg) => ({
    width: svg.getBoundingClientRect().width,
    height: svg.getBoundingClientRect().height,
    shapes: svg.querySelectorAll('.node').length,
  })),
  frames: document.querySelectorAll('iframe.canvas-app').length,
  draftNotes: document.querySelectorAll('.draft-note').length,
  pres: [...document.querySelectorAll('pre')].filter((pre) => pre.scrollWidth > pre.clientWidth + 1).length,
  overflowingBlocks: [...document.querySelectorAll('pre, table, svg.diagram, figure')]
    .filter((block) => block.getBoundingClientRect().right > document.documentElement.clientWidth).length,
}))()`;

const SEE_FRAME = (i) => `(async () => {
  const frame = document.querySelectorAll('iframe.canvas-app')[${i}];
  frame.scrollIntoView({ block: 'center' });
  const started = Date.now();
  const canvasOf = () => { try { return frame.contentDocument?.querySelector('canvas'); } catch { return null; } };
  while (Date.now() - started < 20000) {
    const canvas = canvasOf();
    if (canvas && canvas.width > 0) {
      const box = frame.getBoundingClientRect();
      const { data } = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
      const colours = new Set();
      for (let at = 0; at < data.length; at += 4 * 97) colours.add((data[at] << 16) | (data[at + 1] << 8) | data[at + 2]);
      if (colours.size > 3) {
        return { src: frame.getAttribute('src'), left: box.left, top: box.top, width: box.width, height: box.height,
                 canvasWidth: canvas.getBoundingClientRect().width, colours: colours.size };
      }
    }
    await new Promise((later) => setTimeout(later, 100));
  }
  return { src: frame.getAttribute('src'), missing: true };
})()`;

const PICTURE_OF_FRAME = (i) => `(() => {
  const canvas = document.querySelectorAll('iframe.canvas-app')[${i}].contentDocument.querySelector('canvas');
  const { data } = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
  let hash = 0;
  for (let at = 0; at < data.length; at += 4 * 31) hash = (hash * 31 + data[at] + data[at + 1] * 3 + data[at + 2] * 7) | 0;
  return hash;
})()`;

// Where the frame stands now against where the drag aimed, for a failure's line.
const WHERE_THE_DRAG_WENT = (i, frame, y) => `(() => {
  const box = document.querySelectorAll('iframe.canvas-app')[${i}].getBoundingClientRect();
  const under = document.elementFromPoint(${frame.left + frame.width / 2}, ${y});
  return 'aimed at y ' + ${Math.round(y)} + ' for a frame measured at top ' + ${Math.round(frame.top)} + ', now at top ' + Math.round(box.top)
    + ', height ' + Math.round(box.height) + ', window height ' + innerHeight + ', and that point holds ' + (under ? under.tagName : 'nothing');
})()`;

async function evaluate(page, expression) {
  const { result, exceptionDetails } = await page.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true }, page.session);
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

// Whether the frame's picture leaves `before` within a few seconds.
async function pictureChanges(page, i, before) {
  for (let tries = 0; tries < 50; tries++) {
    if ((await evaluate(page, PICTURE_OF_FRAME(i))) !== before) return true;
    await sleep(100);
  }
  return false;
}

// Where a widget that's clicked and not dragged wants its click, as shares of
// the frame. This is rehearsal's third mark.
const CLICKED_AT = { "../rehearsal_widget/": { x: 0.12, y: 0.644 } };

// A widget proves it runs by changing its picture: a drag moves a widget, a
// click moves one that's clicked, and the ride moves by itself. A widget reads a held pointer once a frame, so the
// drag stays held until the picture answers, however slow the box is.
async function checkFrame(page, file, i) {
  const frame = await evaluate(page, SEE_FRAME(i));
  if (frame.missing) { fail(file, `the widget ${frame.src} drew nothing`); return frame.src; }
  if (Math.abs(frame.canvasWidth - frame.width) > 2) fail(file, `the widget ${frame.src} is ${frame.canvasWidth} wide in a frame ${frame.width} wide`);
  const before = await evaluate(page, PICTURE_OF_FRAME(i));
  const clicked = CLICKED_AT[frame.src];
  const y = frame.top + frame.height * (clicked?.y ?? 0.5);
  const mouse = (type, share, buttons) => page.send("Input.dispatchMouseEvent",
    { type, x: frame.left + frame.width * share, y, button: "left", buttons, clickCount: 1 }, page.session);
  const isRide = frame.src === "../safari/";
  if (clicked) {
    await mouse("mousePressed", clicked.x, 1);
  } else if (!isRide) {
    await mouse("mousePressed", 0.2, 1);
    await mouse("mouseMoved", 0.5, 1);
    await mouse("mouseMoved", 0.8, 1);
  }
  if (!(await pictureChanges(page, i, before))) fail(file, `the widget ${frame.src} didn't move: ${await evaluate(page, WHERE_THE_DRAG_WENT(i, frame, y))}`);
  if (!isRide) await mouse("mouseReleased", 0.8, 0);
  return frame.src;
}

async function checkPage(link, file, seen) {
  const { targetId } = await link.send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await link.send("Target.attachToTarget", { targetId, flatten: true });
  const page = { send: link.send, session: sessionId };
  const hear = (method, handle) => link.on(method, handle);
  hear("Runtime.exceptionThrown", ({ exceptionDetails }) => fail(file, `exception: ${exceptionDetails.exception?.description ?? exceptionDetails.text}`));
  hear("Runtime.consoleAPICalled", ({ type, args }) => {
    if (type === "error" || type === "warning") fail(file, `console ${type}: ${args.map((a) => a.value ?? a.description).join(" ")}`);
  });
  hear("Log.entryAdded", ({ entry }) => {
    if (entry.level === "error") fail(file, `log: ${entry.text} ${entry.url ?? ""}`);
  });
  hear("Network.responseReceived", ({ response }) => {
    if (response.status >= 400) fail(file, `${response.status} for ${response.url}`);
    else if (!response.url.startsWith(new URL("..", base).href) && !response.url.startsWith("data:")) fail(file, `an outside request: ${response.url}`);
  });
  hear("Network.loadingFailed", ({ canceled, errorText }) => {
    if (!canceled) fail(file, `a request failed: ${errorText}`);
  });
  for (const domain of ["Page", "Runtime", "Log", "Network"]) await page.send(`${domain}.enable`, {}, page.session);
  await page.send("Emulation.setDeviceMetricsOverride", { width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: false }, page.session);
  const loaded = new Promise((done) => hear("Page.loadEventFired", done));
  await page.send("Page.navigate", { url: new URL(file, base).href }, page.session);
  await loaded;

  const held = await evaluate(page, READ_PAGE);
  seen.set(file, held);
  if (held.scrollWidth > held.clientWidth) fail(file, `the page scrolls sideways: ${held.scrollWidth} in ${held.clientWidth}`);
  if (held.overflowingBlocks > 0) fail(file, `${held.overflowingBlocks} blocks run past the window`);
  for (const diagram of held.diagrams) {
    if (diagram.width < 50 || diagram.height < 20 || diagram.shapes === 0) fail(file, `a diagram didn't draw: ${JSON.stringify(diagram)}`);
  }
  const widgets = [];
  for (let i = 0; i < held.frames; i++) widgets.push(await checkFrame(page, file, i));
  await evaluate(page, "scrollTo(0, 0)");
  await sleep(200);
  const { data } = await page.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true }, page.session);
  writeFileSync(join(shots, file.replace(/\.html$/, ".png")), Buffer.from(data, "base64"));
  await link.send("Target.closeTarget", { targetId });
  console.log(`${file}: ${held.diagrams.length} diagrams, ${held.frames} widgets ${widgets.join(" ")}, ${held.draftNotes} draft notes, ${held.pres} code blocks that scroll`);
  return held;
}

// Every link inside the book must reach a page, and an anchor an element on it.
function checkLinks(seen) {
  let reached = 0;
  for (const [file, held] of seen) {
    for (const href of held.links) {
      if (/^[a-z]+:/.test(href)) continue;
      const [target, anchor] = href.split("#");
      const page = seen.get(target || file);
      if (!page) fail(file, `a link to a page that isn't there: ${href}`);
      else if (anchor && !page.ids.includes(anchor)) fail(file, `a link to an anchor that isn't there: ${href}`);
      else reached++;
    }
  }
  return reached;
}

const profile = mkdtempSync(join(tmpdir(), "book-check-"));
const { browser, address } = startBrowser(profile);
let exitCode = 1;
try {
  const link = await connect(await address);
  const seen = new Map();
  const queue = ["index.html"];
  while (queue.length) {
    const file = queue.shift();
    const held = await checkPage(link, file, seen);
    for (const href of held.links) {
      const target = href.split("#")[0];
      if (target && !/^[a-z]+:/.test(target) && !seen.has(target) && !queue.includes(target)) queue.push(target);
    }
  }
  const reached = checkLinks(seen);
  console.log(`book_check: ${seen.size} pages, ${reached} links reached`);
  for (const failure of failures) console.log(`FAIL ${failure}`);
  exitCode = failures.length ? 1 : 0;
  link.socket.close();
} finally {
  browser.removeAllListeners("exit");
  browser.kill("SIGKILL");
  await sleep(300);
  rmSync(profile, { recursive: true, force: true });
}
process.exit(exitCode);
