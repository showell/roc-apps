// This drives the staged book in headless Chromium, the way a reader would,
// and exits non-zero if any page is wrong. It holds every page to six things:
// no console errors, no failed requests, every widget running in its frame,
// every diagram drawn, every link in the book reaching a real place, and at each
// of VIEWS, nothing running past the window and no code block scrolling. The book
// is made for the desktop (MISSION.md), so the views are desktop, tablet and print
// widths; a phone is extremely low priority and isn't checked.
//
//   node book_builder/tools/book_check.mjs http://127.0.0.1:9210/tutorial.staging/ none
//   node book_builder/tools/book_check.mjs http://127.0.0.1:9210/tutorial.staging/ <shots folder>
//
// The Safari tutorial's book.shale, the books book's and the JavaScript
// book's run it. A book with no widgets is held to the same checks, and its widget count is zero.
//
// The browser is the binary BOOK_CHECK_CHROMIUM names, when it's set, and
// otherwise tools/chromium.mjs's, which also starts it; when neither is
// there, the check stops before it starts, saying where it looked.
//
// The checks are the same either way. The second argument says whether to
// take shots, which no check reads. They're for a person or an agent to look
// at, and taking them is most of the run's time: a full-page shot of a long
// page in each of five views. So `none` is the inner loop, half a minute for
// the whole book on a quiet box, and a shots folder is the pre-publish tier,
// which book.shale runs before it replaces the channel's book: a shot of each
// page goes in the folder, and one for each view in the folder named for it,
// three or four minutes. A third argument, `looks`, reads the pages without
// driving their widgets, for a quick look at a change to the styling.
//
// PAGES_AT_ONCE pages are open at a time, each in a window of its own so none
// is a background tab the browser slows down. Each page's events reach only
// its own checks, by its DevTools session. The last lines say how long each
// phase took, summed over the pages, so a slow run says where its time went.
//
// The DevTools connection below is this check's own, so pages open at once
// never hear each other's events.
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { chromiumPath, sleep, startBrowser } from "../../tools/chromium.mjs";

function bookChromium() {
  const named = process.env.BOOK_CHECK_CHROMIUM;
  if (!named) return chromiumPath();
  if (!existsSync(named)) { console.error(`book_check: BOOK_CHECK_CHROMIUM names ${named}, and nothing is there`); process.exit(2); }
  return named;
}
const CHROME = bookChromium();
const WIDTH = 1400;
const HEIGHT = 900;
// The ways a reader sees a page besides the desktop window it's driven in.
const VIEWS = [
  { name: "tablet", width: 820, height: 1100 },
  { name: "narrow", width: 1000, height: 800 },
  { name: "dark", width: WIDTH, height: HEIGHT, scheme: "dark" },
  { name: "print", width: 794, height: 1123, media: "print" },
];
// Two cores, and a page spends much of its time waiting on its own loads.
const PAGES_AT_ONCE = 2;
const [base, shotsArgument, mode] = process.argv.slice(2);
if (!base || !shotsArgument || (mode && mode !== "looks")) { console.error("usage: book_check.mjs <book url> <shots folder | none> [looks]"); process.exit(2); }
const shots = shotsArgument === "none" ? null : shotsArgument;
if (shots) for (const folder of [shots, ...VIEWS.map((view) => join(shots, view.name))]) mkdirSync(folder, { recursive: true });

const failures = [];
const fail = (page, why) => failures.push(`${page}: ${why}`);

// Each phase's time, summed over the pages.
const phases = new Map();
async function timed(phase, work) {
  const started = Date.now();
  const answer = await work();
  phases.set(phase, (phases.get(phase) ?? 0) + Date.now() - started);
  return answer;
}

// One DevTools connection: `send` answers a command, and `on` hears an event
// of one session, a page's, so pages open at once never hear each other's.
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
      hearers.get(`${message.sessionId} ${message.method}`)?.(message.params);
    }
  };
  return {
    socket,
    on: (sessionId, method, hear) => hearers.set(`${sessionId} ${method}`, hear),
    forget: (sessionId) => {
      for (const key of [...hearers.keys()]) if (key.startsWith(`${sessionId} `)) hearers.delete(key);
    },
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
  diagrams: [...document.querySelectorAll('figure.diagram')].map((figure) => {
    const shown = [...figure.querySelectorAll('svg.diagram')].filter((svg) => getComputedStyle(svg).display !== 'none');
    const box = shown[0]?.getBoundingClientRect();
    return {
      drawings: shown.length,
      width: box?.width ?? 0,
      height: box?.height ?? 0,
      shapes: shown[0]?.querySelectorAll('.node').length ?? 0,
    };
  }),
  frames: document.querySelectorAll('iframe.canvas-app').length,
  draftNotes: document.querySelectorAll('.draft-note').length,
  pres: [...document.querySelectorAll('pre')].filter((pre) => pre.scrollWidth > pre.clientWidth + 1).length,
  // A block runs past the window when its right edge does, unless a box
  // around it scrolls sideways and itself fits the window: then the block
  // is that box's to scroll (a drawing kept at its own size), and the page
  // still never scrolls sideways.
  overflowingBlocks: [...document.querySelectorAll('pre, table, svg.diagram, figure')]
    .filter((block) => {
      const width = document.documentElement.clientWidth;
      if (block.getBoundingClientRect().right <= width) return false;
      for (let box = block.parentElement; box; box = box.parentElement) {
        const scrolls = ['auto', 'scroll'].includes(getComputedStyle(box).overflowX);
        if (scrolls && box.getBoundingClientRect().right <= width) return false;
      }
      return true;
    }).length,
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
      canvas.addEventListener('pointerdown', () => { canvas.dataset.pressed = 'yes'; });
      canvas.addEventListener('pointermove', () => { canvas.dataset.hovered = 'yes'; });
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

// Where the frame stands now against where the click aimed, for a failure's line.
const WHERE_THE_CLICK_WENT = (i, frame, y) => `(() => {
  const element = document.querySelectorAll('iframe.canvas-app')[${i}];
  const box = element.getBoundingClientRect();
  const under = document.elementFromPoint(${frame.left + frame.width / 2}, ${y});
  const pressed = element.contentDocument.querySelector('canvas').dataset.pressed === 'yes';
  return 'aimed at y ' + ${Math.round(y)} + ' for a frame measured at top ' + ${Math.round(frame.top)} + ', now at top ' + Math.round(box.top)
    + ', height ' + Math.round(box.height) + ', window height ' + innerHeight + ', that point holds ' + (under ? under.tagName : 'nothing')
    + ', and the canvas ' + (pressed ? 'felt' : 'never felt') + ' the press';
})()`;

async function evaluate(page, expression) {
  const { result, exceptionDetails } = await page.send("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true }, page.session);
  if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? exceptionDetails.text);
  return result.value;
}

// The page's next frame, which is a frame of its widgets too: a same-origin
// frame runs in the page's own event loop and renders with it.
const NEXT_FRAME = `new Promise(requestAnimationFrame)`;
const FELT = (i, what) => `document.querySelectorAll('iframe.canvas-app')[${i}].contentDocument.querySelector('canvas').dataset.${what} === 'yes'`;

// How long a widget has to answer, counted in the page's frames, not in time,
// so a busy box that renders slowly gives it the same chance: on a quiet box
// 300 frames is five seconds. A widget reads a press once a frame and draws the
// frame after, so one that hasn't answered in that many frames is broken.
const ANSWER_FRAMES = 300;
// How many frames the browser may take to route input to the place a scroll
// moved a widget's frame to.
const ROUTE_FRAMES = 300;
// The most frames any widget took for its input to reach it, for the report.
let mostRouteFrames = 0;

// Whether the frame's picture leaves `before` within ANSWER_FRAMES frames.
async function pictureChanges(page, i, before) {
  for (let frames = 0; frames < ANSWER_FRAMES; frames++) {
    if ((await evaluate(page, PICTURE_OF_FRAME(i))) !== before) return true;
    await evaluate(page, NEXT_FRAME);
  }
  return false;
}

// Whether `felt` holds within ROUTE_FRAMES frames, since an event the
// browser has taken reaches the page's handlers on its own schedule.
async function feltWithin(page, felt) {
  for (let frames = 0; frames < ROUTE_FRAMES; frames++) {
    if (await evaluate(page, felt)) return true;
    await evaluate(page, NEXT_FRAME);
  }
  return false;
}

// The browser routes input by where the last picture it was handed put each
// frame, so right after a scroll a press can land where the frame used to be,
// and more so the busier the box. A move to the press's point is harmless and
// says when routing has caught up: the canvas feels it. Gives how many frames
// that took, or nil if it never did.
async function routeTo(page, i, mouseAt) {
  for (let frames = 0; frames < ROUTE_FRAMES; frames++) {
    await mouseAt("mouseMoved", 0);
    if (await evaluate(page, FELT(i, "hovered"))) return frames;
    await evaluate(page, NEXT_FRAME);
  }
  return null;
}

// The play button of PlaybackButtons, as shares of the frame.
const PLAY = { x: 0.384, y: 0.65 };

// A widget that is a fixed picture has nothing to click, so it proves it runs
// by having drawn at all.
const FIXED_PICTURE = "fixed picture";

// Where a widget wants its click, as shares of the frame: the buttons, rehearsal's
// third mark, and the first bird among the stills.
const CLICKED_AT = {
  "../beacon_widget/": PLAY,
  "../bend_animals_widget/": FIXED_PICTURE,
  "../bends_widget/": FIXED_PICTURE,
  "../bird_widget/": PLAY,
  "../cat_widget/": PLAY,
  "../conifers_widget/": FIXED_PICTURE,
  "../cow_widget/": FIXED_PICTURE,
  "../far_tree_widget/": FIXED_PICTURE,
  "../frame_widget/": FIXED_PICTURE,
  "../gaze_widget/": PLAY,
  "../herd_widget/": FIXED_PICTURE,
  "../kinds_widget/": FIXED_PICTURE,
  "../pipeline_widget/": FIXED_PICTURE,
  "../rehearsal_widget/": { x: 0.12, y: 0.644 },
  "../route_widget/": FIXED_PICTURE,
  "../shapes_widget/": FIXED_PICTURE,
  "../sky_widget/": PLAY,
  "../step_widget/": PLAY,
  "../stills_widget/": { x: 0.114, y: 0.883 },
  "../truck_widget/": FIXED_PICTURE,
};

// A widget proves it runs by changing its picture: a click moves a widget, and the
// ride moves by itself. A widget reads a press once a frame, so the button stays
// held until the picture answers, however slow the box is.
async function checkFrame(page, file, i) {
  const frame = await evaluate(page, SEE_FRAME(i));
  if (frame.missing) { fail(file, `the widget ${frame.src} drew nothing`); return frame.src; }
  if (Math.abs(frame.canvasWidth - frame.width) > 2) fail(file, `the widget ${frame.src} is ${frame.canvasWidth} wide in a frame ${frame.width} wide`);
  const isRide = frame.src === "../safari/";
  const clicked = CLICKED_AT[frame.src.split("?")[0]];
  if (!isRide && !clicked) { fail(file, `CLICKED_AT doesn't say where to click ${frame.src}`); return frame.src; }
  if (clicked === FIXED_PICTURE) return frame.src;
  const y = frame.top + frame.height * (clicked?.y ?? 0.5);
  const mouseAt = (type, buttons) => page.send("Input.dispatchMouseEvent",
    { type, x: frame.left + frame.width * (clicked?.x ?? 0.5), y, button: buttons ? "left" : "none", buttons, clickCount: buttons ? 1 : 0 }, page.session);
  if (!isRide) {
    const frames = await routeTo(page, i, mouseAt);
    if (frames === null) { fail(file, `input never reached the widget ${frame.src} in ${ROUTE_FRAMES} frames: ${await evaluate(page, WHERE_THE_CLICK_WENT(i, frame, y))}`); return frame.src; }
    mostRouteFrames = Math.max(mostRouteFrames, frames);
  }
  // The picture before the press, taken once the pointer is over the widget, so
  // nothing the pointer's arrival drew counts as the press's answer.
  const before = await evaluate(page, PICTURE_OF_FRAME(i));
  if (!isRide) {
    await mouseAt("mousePressed", 1);
    if (!(await feltWithin(page, FELT(i, "pressed")))) fail(file, `the widget ${frame.src} never felt the press: ${await evaluate(page, WHERE_THE_CLICK_WENT(i, frame, y))}`);
  }
  if (!(await pictureChanges(page, i, before))) fail(file, `the widget ${frame.src} didn't move in ${ANSWER_FRAMES} frames: ${await evaluate(page, WHERE_THE_CLICK_WENT(i, frame, y))}`);
  if (!isRide) await mouseAt("mouseReleased", 0);
  return frame.src;
}

const shotName = (file) => file.replace(/\.html$/, ".png");

// A shot of the page as it is, for a run that takes shots. The pause first
// lets the page paint what the last step changed.
async function shoot(page, path, pause) {
  await timed("pausing to paint, for shots", () => sleep(pause));
  const { data } = await timed("shots", () => page.send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true }, page.session));
  writeFileSync(path, Buffer.from(data, "base64"));
}

// Whether the page has taken on the view: its width, its media and its colour
// scheme. Emulation reaches the page apart from what is evaluated in it, so a
// read made too soon could measure the view before.
const TAKES_VIEW = (view) => `(async () => {
  const taken = () => innerWidth === ${view.width}
    && matchMedia('print').matches === ${view.media === "print"}
    && matchMedia('(prefers-color-scheme: dark)').matches === ${view.scheme === "dark"};
  const started = Date.now();
  while (!taken()) {
    if (Date.now() - started > 5000) return false;
    await new Promise((later) => setTimeout(later, 10));
  }
  return true;
})()`;

// One view of a page that's already loaded: what overflows, and a shot of it.
async function checkView(page, file, view) {
  await timed("views: switching", async () => {
    await page.send("Emulation.setDeviceMetricsOverride", { width: view.width, height: view.height, deviceScaleFactor: 1, mobile: view.mobile ?? false }, page.session);
    await page.send("Emulation.setEmulatedMedia", { media: view.media ?? "", features: [{ name: "prefers-color-scheme", value: view.scheme ?? "light" }] }, page.session);
  });
  if (!(await timed("views: switching", () => evaluate(page, TAKES_VIEW(view))))) fail(file, `the page never took on the ${view.name} view`);
  const held = await timed("views: reading", () => evaluate(page, READ_PAGE));
  if (held.scrollWidth > held.clientWidth) fail(file, `the page scrolls sideways in ${view.name}: ${held.scrollWidth} in ${held.clientWidth}`);
  if (held.overflowingBlocks > 0) fail(file, `${held.overflowingBlocks} blocks run past the window in ${view.name}`);
  if (held.pres > 0) fail(file, `${held.pres} code blocks scroll in ${view.name}`);
  for (const diagram of held.diagrams) {
    if (diagram.drawings !== 1) fail(file, `${diagram.drawings} drawings of a diagram show in ${view.name}`);
  }
  if (shots) await shoot(page, join(shots, view.name, shotName(file)), 100);
  return held;
}

// One page, held to every check, and what it holds, with its line for the
// report.
async function checkPage(link, file) {
  const { targetId } = await link.send("Target.createTarget", { url: "about:blank", newWindow: true });
  const { sessionId } = await link.send("Target.attachToTarget", { targetId, flatten: true });
  const page = { send: link.send, session: sessionId };
  const hear = (method, handle) => link.on(sessionId, method, handle);
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
  await timed("loading", async () => {
    for (const domain of ["Page", "Runtime", "Log", "Network"]) await page.send(`${domain}.enable`, {}, page.session);
    await page.send("Emulation.setDeviceMetricsOverride", { width: WIDTH, height: HEIGHT, deviceScaleFactor: 1, mobile: false }, page.session);
    const loaded = new Promise((done) => hear("Page.loadEventFired", done));
    await page.send("Page.navigate", { url: new URL(file, base).href }, page.session);
    await loaded;
  });

  const held = await timed("reading", () => evaluate(page, READ_PAGE));
  if (held.scrollWidth > held.clientWidth) fail(file, `the page scrolls sideways: ${held.scrollWidth} in ${held.clientWidth}`);
  if (held.overflowingBlocks > 0) fail(file, `${held.overflowingBlocks} blocks run past the window`);
  if (held.pres > 0) fail(file, `${held.pres} code blocks scroll`);
  for (const diagram of held.diagrams) {
    if (diagram.drawings !== 1 || diagram.width < 50 || diagram.height < 20 || diagram.shapes === 0) fail(file, `a diagram didn't draw: ${JSON.stringify(diagram)}`);
  }
  const widgets = [];
  if (mode !== "looks") for (let i = 0; i < held.frames; i++) widgets.push(await timed("widgets", () => checkFrame(page, file, i)));
  if (shots) {
    await evaluate(page, "scrollTo(0, 0)");
    await shoot(page, join(shots, shotName(file)), 200);
  }
  for (const view of VIEWS) await checkView(page, file, view);
  await link.send("Target.closeTarget", { targetId });
  link.forget(sessionId);
  return { held, line: `${file}: ${held.diagrams.length} diagrams, ${held.frames} widgets ${widgets.join(" ")}, ${held.draftNotes} draft notes` };
}

// Every page the book links to, from its front page, PAGES_AT_ONCE at a time:
// each page's check gives the pages it links to, and the run ends when every
// page found has been checked. Gives each page, in the order found, with its
// line.
async function checkBook(link) {
  const found = ["index.html"];
  const checked = new Map();
  let taken = 0;
  let working = 0;
  const waiting = [];
  const wakeAll = () => { while (waiting.length) waiting.shift()(); };
  async function worker() {
    for (;;) {
      if (taken < found.length) {
        const file = found[taken++];
        working++;
        const page = await checkPage(link, file);
        checked.set(file, page);
        for (const href of page.held.links) {
          const target = href.split("#")[0];
          if (target && !/^[a-z]+:/.test(target) && !found.includes(target)) found.push(target);
        }
        working--;
        wakeAll();
      } else if (working === 0) {
        wakeAll();
        return;
      } else {
        await new Promise((wake) => waiting.push(wake));
      }
    }
  }
  await Promise.all(Array.from({ length: PAGES_AT_ONCE }, worker));
  return found.map((file) => [file, checked.get(file)]);
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

const browser = startBrowser({ chrome: CHROME, args: [`--window-size=${WIDTH},${HEIGHT}`] });
let exitCode = 1;
try {
  const link = await connect(await browser.address);
  const started = Date.now();
  const pages = await checkBook(link);
  const seen = new Map();
  for (const [file, page] of pages) {
    console.log(page.line);
    seen.set(file, page.held);
  }
  const reached = checkLinks(seen);
  const spent = [...phases].sort((a, b) => b[1] - a[1]).map(([phase, ms]) => `${phase} ${(ms / 1000).toFixed(1)} s`);
  console.log(`book_check: time by phase, over the pages: ${spent.join(", ")}`);
  console.log(`book_check: input reached every pressed widget within ${mostRouteFrames} frames of its scroll`);
  console.log(`book_check: ${seen.size} pages, ${reached} links reached, ${shots ? "with shots" : "no shots"}, ${PAGES_AT_ONCE} pages at a time, in ${((Date.now() - started) / 1000).toFixed(1)} s`);
  for (const failure of failures) console.log(`FAIL ${failure}`);
  exitCode = failures.length ? 1 : 0;
  link.socket.close();
} finally {
  await browser.close();
}
process.exit(exitCode);
