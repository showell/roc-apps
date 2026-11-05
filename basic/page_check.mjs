// page_check -- types a session at BASIC's page, with no browser.
//
//   node basic/page_check.mjs <build-dir>
//
// It runs the inline script of <build-dir>/basic.html, unchanged, against the
// basic.wasm beside it and a stand-in document built from the page's own
// markup. Then it uses the page as a person does: it types lines into the
// listing, presses Run and Stop, answers INPUT in the line box and picks
// samples. After each step it holds everything a reader would see, exactly.
//
// The clock is virtual. A timer fires as soon as the page has nothing else to
// do, so the millisecond the page sleeps after each PRINT costs no real time,
// and a SLEEP's length is read off the clock.
import { readFileSync } from "node:fs";
import vm from "node:vm";

const dir = process.argv[2];
if (!dir) { console.error("usage: node basic/page_check.mjs <build-dir>"); process.exit(2); }

let held = 0;
let lastHeld = "none yet";
function stop(why) {
  console.error(`page_check: FAIL after ${held} steps (the last held: ${lastHeld}): ${why}`);
  process.exit(1);
}
process.on("unhandledRejection", (e) => stop(`the page's script threw: ${e?.stack ?? e}`));

// ── a stand-in document ────────────────────────────────────────────────────

let focused = null;
// What the page's clock says, and so the seed its next Run is given.
let seedClock = 1000;

class Element {
  constructor(tag) {
    this.tag = tag; this.children = []; this.text = ""; this.current = "";
    this.hidden = false; this.disabled = false; this.placeholder = "";
    this.classes = new Set(); this.listeners = {}; this.image = null;
    this.style = { setProperty: (name, value) => { this.style[name] = value; } };
    this.classList = { add: (c) => this.classes.add(c), remove: (c) => this.classes.delete(c) };
    this.offsetWidth = 0;
  }
  appendChild(child) { this.children.push(child); return child; }
  get textContent() { return this.children.length ? this.children.map((c) => c.textContent).join("") : this.text; }
  set textContent(s) { this.children = []; this.text = s; }
  get value() { return this.current; }
  // A select takes only a value one of its options has.
  set value(v) {
    this.current = this.tag !== "select" || this.children.some((o) => o.value === v) ? v : "";
  }
  focus() { focused = this; }
  addEventListener(kind, fn) { (this.listeners[kind] ??= []).push(fn); }
  getContext() {
    return {
      createImageData: (w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }),
      putImageData: (image) => { this.image = image; },
    };
  }
}

const html = readFileSync(`${dir}/basic.html`, "utf8");
const inline = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
if (inline.length !== 1) stop(`${inline.length} inline scripts in basic.html, not 1`);
const elements = {};
for (const [, tag, attrs, id] of html.slice(0, inline[0].index).matchAll(/<(\w+)((?:\s[^<>]*)?\sid="(\w+)"[^<>]*)>/g)) {
  const e = new Element(tag);
  e.hidden = /\shidden\b/.test(attrs);
  e.disabled = /\sdisabled\b/.test(attrs);
  e.placeholder = /\splaceholder="([^"]*)"/.exec(attrs)?.[1] ?? "";
  elements[id] = e;
}
const $ = (id) => elements[id];

// ── the browser around the page ────────────────────────────────────────────

let clock = 0;
let timers = [];
const module = await WebAssembly.compile(readFileSync(`${dir}/basic.wasm`));

const sandbox = {
  document: {
    getElementById: (id) => elements[id] ?? null,
    createElement: (tag) => new Element(tag),
    documentElement: new Element("html"),
  },
  TextEncoder, TextDecoder,
  Date: { now: () => seedClock },
  setTimeout: (fn, ms) => {
    timers.push({ at: clock + ms, fn });
    timers.sort((a, b) => a.at - b.at);
  },
  fetch: async (url) => {
    if (url !== "basic.wasm") stop(`the page fetched ${url}`);
    return module;
  },
  WebAssembly: {
    // The imports are the page's own, so a module the page couldn't link fails here too.
    instantiateStreaming: async (fetched, imports) => ({ instance: new WebAssembly.Instance(await fetched, imports) }),
  },
};
vm.createContext(sandbox);

const turn = () => new Promise((resolve) => setImmediate(resolve));

// Fires timers, at most `turns` of them, until the page has none left.
async function fire(turns) {
  await turn();
  for (let i = 0; i < turns && timers.length; i++) {
    const t = timers.shift();
    clock = t.at;
    t.fn();
    await turn();
  }
}

// Lets the page run until it is waiting for the reader.
async function settle() {
  await fire(5000);
  if (timers.length) stop("the page never came to rest");
}

// ── a person at the page ───────────────────────────────────────────────────

function press(el, key, modifiers = {}) {
  if (el.disabled) stop(`a key was pressed on the disabled #${el.tag}`);
  let prevented = false;
  const event = { key, metaKey: false, ctrlKey: false, ...modifiers, preventDefault: () => { prevented = true; } };
  for (const fn of el.listeners.keydown ?? []) fn(event);
  if (!prevented && key === "Enter" && el.tag === "textarea") el.value += "\n";
}

async function click(id) {
  $(id).onclick();
  await settle();
}

function typeLines(...lines) {
  for (const line of lines) {
    $("src").value += line;
    press($("src"), "Enter");
  }
}

async function runLines(...lines) {
  $("src").value = "";
  typeLines(...lines);
  await click("run");
}

function pick(name) {
  $("sample").value = name;
  if ($("sample").value !== name) stop(`no sample named ${name}`);
  $("sample").onchange();
}

async function reply(text) {
  $("line").value = text;
  press($("line"), "Enter");
  await settle();
}

// ── what a reader sees ─────────────────────────────────────────────────────

function screenRows() {
  const rows = $("screen").children;
  if (rows.length !== 25) stop(`the screen has ${rows.length} rows`);
  for (const row of rows) if (row.children.length !== 40) stop(`a screen row has ${row.children.length} cells`);
  const text = rows.map((row) => row.textContent.trimEnd());
  while (text.length && text[text.length - 1] === "") text.pop();
  return text;
}

function sight() {
  const line = $("line");
  const box = line.disabled ? "closed" : focused === line ? "open and focused" : "open, not focused";
  const shown = [`status: ${$("status").textContent}`, `line box: ${box}: ${line.placeholder}`];
  if ($("line").value !== "") shown.push(`line box holds: ${$("line").value}`);
  if ($("status").classes.has("done")) shown.push("status jiggles");
  if ($("screen").hidden !== $("screenlab").hidden) stop("the screen and its label disagree");
  if ($("pix").hidden !== $("pixlab").hidden) stop("the canvas and its label disagree");
  if (!$("pix").hidden) shown.push("canvas shown");
  if ($("screen").hidden) shown.push("screen hidden");
  else shown.push(...screenRows().map((row) => `| ${row}`));
  return shown.join("\n");
}

function see(name, want) {
  const got = sight();
  if (got !== want) stop(`at "${name}" the page shows\n${got}\n--- where it should show\n${want}`);
  held++;
  lastHeld = name;
}

function same(name, got, want) {
  if (got !== want) stop(`${name} is ${JSON.stringify(got)}, not ${JSON.stringify(want)}`);
}

const CLOSED = "line box: closed: the program is not asking for anything";
const OPEN = "line box: open and focused: type a line and press Enter";
const page = (status, box, screen) => [status, box, ...screen.map((row) => `| ${row}`)].join("\n");
const finished = (...screen) => page("status: finished ✓", `${CLOSED}\nstatus jiggles`, screen);
const waiting = (...screen) => page("status: waiting for a line", OPEN, screen);
const running = (...screen) => page("status: running", CLOSED, screen);
const stopped = (status, ...screen) => page(`status: ${status}`, CLOSED, screen);
const numbers = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => ` ${from + i}`);

function cell(y, x) {
  const c = $("screen").children[y].children[x];
  return `${c.textContent} ${c.style.color} on ${c.style.background ?? "nothing"}`;
}

function pixel(x, y) {
  const at = (y * 320 + x) * 4;
  return [...$("pix").image.data.slice(at, at + 4)].join(" ");
}

// ── the session ────────────────────────────────────────────────────────────

const started = performance.now();
vm.runInContext(inline[0][1], sandbox, { filename: "basic.html" });
await settle();
see("the page opens running Hello", finished("HELLO, WORLD"));
same("the listing", $("src").value, '10 PRINT "HELLO, WORLD"\n20 END\n');

$("src").value = "";
typeLines('10 PRINT "COUNTING"', "20 FOR I = 1 TO 3", "30 PRINT I; I*I", "40 NEXT I", "50 END");
see("typing lines runs nothing", finished("HELLO, WORLD"));

const typed = '10 PRINT "COUNTING"\n20 FOR I = 1 TO 3\n30 PRINT I; I*I\n40 NEXT I\n50 END\n';
same("the listing as typed", $("src").value, typed);
await click("run");
see("Run prints and loops", finished("COUNTING", " 1  1", " 2  4", " 3  9"));
same("the listing after Run", $("src").value, typed);

$("src").value = typed.replace("I*I", "I*10");
press($("src"), "Enter", { ctrlKey: true });
await settle();
see("an edited line, run by ctrl Enter", finished("COUNTING", " 1  10", " 2  20", " 3  30"));
same("the listing after ctrl Enter", $("src").value, typed.replace("I*I", "I*10"));

$("src").value = typed.replace("TO 3", "TO 2");
press($("src"), "Enter", { metaKey: true });
await settle();
see("another edit, run by cmd Enter", finished("COUNTING", " 1  1", " 2  4"));

await runLines();
see("an empty listing clears the screen", finished());

await runLines('10 INPUT "NAME"; A$', '20 PRINT "HI "; A$', "30 INPUT N", "40 PRINT N*2", "50 END");
see("INPUT asks", waiting("NAME?"));
$("line").value = "STE";
press($("line"), "V");
see("a key that isn't Enter sends nothing", `${waiting("NAME?")}`.replace(OPEN, `${OPEN}\nline box holds: STE`));
await reply("STEVE");
see("a reply answers, and the next INPUT asks", waiting("NAME? STEVE", "HI STEVE", "?"));
await reply("21");
see("the last reply ends the program", finished("NAME? STEVE", "HI STEVE", "? 21", " 42"));

await runLines("10 INPUT A$", "20 PRINT LEN(A$)");
await reply("X".repeat(4097));
see("a reply past the 4,096 bytes is not sent", waiting("?"));
await reply("X".repeat(4096));
see("a reply of 4,096 bytes is", finished(...Array(22).fill("X".repeat(40)), "X".repeat(18), " 4096"));

await runLines('10 PRINT "BEFORE"', "20 LET = 5", '30 PRINT "AFTER"');
see("a syntax error stops at its line",
  stopped("stopped: a form the interpreter has not built  —  UNSUPPORTED: Expected a variable", "BEFORE"));
await runLines('10 PRINT "BEFORE"', "20 LET A = 5", '30 PRINT "AFTER"; A');
see("the line fixed, the next Run works", finished("BEFORE", "AFTER 5"));

await runLines('10 PRINT "BEFORE"', "20 RETURN", '30 PRINT "AFTER"');
see("a run-time error stops the program", stopped("stopped on an exception  —  HALTED: RETURN without GOSUB", "BEFORE"));
await runLines("10 INPUT A", "20 PRINT A + 1");
see("the page takes INPUT after an error", waiting("?"));
await reply("1");
see("and its reply", finished("? 1", " 2"));

await runLines("10 FOR I = 1 TO 30", "20 PRINT I", "30 NEXT I");
see("the screen scrolls", finished(...numbers(7, 30)));

pick("Counting forever");
await fire(40);
see("a program that never ends is running", running(...numbers(17, 40)));
same("timers while running", timers.length, 1);
await click("stop");
see("Stop stops it", stopped("stopped", ...numbers(17, 40)));
same("timers after Stop", timers.length, 0);
$("run").onclick();
await fire(3);
see("Run starts it over", running(" 0", " 1", " 2", " 3"));
await runLines('10 PRINT "REPLACED"');
see("Run replaces a running program", finished("REPLACED"));

await runLines("10 INPUT A", "20 PRINT A");
const asking = screenRows();
await click("stop");
see("Stop during INPUT ends the run", stopped("stopped", ...asking));
same("timers after Stop during INPUT", timers.length, 0);
await runLines('10 PRINT "AGAIN"');
see("Run works after Stop during INPUT", finished("AGAIN"));

async function firstRndAt(time) {
  seedClock = time;
  await runLines("10 PRINT RND(1)");
  return screenRows()[0];
}
const drawn = await firstRndAt(1000);
if (await firstRndAt(2000) === drawn) stop(`RND drew ${drawn} on two seeds`);
same("RND on the same seed", await firstRndAt(1000), drawn);
held++;
lastHeld = "RND follows the page's seed";
same("timers after a replaced run", timers.length, 0);

$("src").value = "";
typeLines("10 SLEEP 0.05", '20 PRINT "AWAKE"', "30 SLEEP 5", '40 PRINT "LATE"');
const before = clock;
$("run").onclick();
await fire(0);
see("a SLEEP is running", running());
await settle();
see("the SLEEP ends", finished("AWAKE", "LATE"));
// 50 ms, a millisecond for each PRINT, and SLEEP 5 held to the page's 2 seconds.
same("the time slept", clock - before, 2052);

await runLines("10 POKE 1024, 1", "20 POKE 55296, 7", "30 POKE 1065, 129", "40 POKE 55296 + 41, 2");
see("POKE draws on the screen", finished("A", " A"));
same("a poked colour", cell(0, 0), "A #edf171 on nothing");
same("a reversed cell", cell(1, 1), "A #000000 on #813338");
same("a cell left alone", cell(0, 1), "  #33ff66 on nothing");

await runLines("10 PLOT 1, 1, 5", '20 PRINT "UNDER THE PIXELS"');
see("PLOT shows the framebuffer", ["status: finished ✓", CLOSED, "status jiggles", "canvas shown", "screen hidden"].join("\n"));
same("a plotted pixel", pixel(1, 1), "86 172 77 255");
same("a pixel left alone", pixel(0, 0), "0 0 0 255");

await runLines('10 PRINT "TEXT AGAIN"');
see("the next program has the text screen back", finished("TEXT AGAIN"));

$("theme").value = "Black on white";
$("theme").onchange();
same("the screen's colour", sandbox.document.documentElement.style["--scr-bg"], "#ffffff");
same("a cell in the new theme", cell(0, 0), "T #111111 on nothing");

const short = '10 PRINT "BIG"\n';
$("src").value = short + " ".repeat(131072 - short.length);
await click("run");
see("a listing of 128 KiB runs", finished("BIG"));
$("src").value += " ";
await click("run");
see("a byte more is refused", `${stopped("listing too long for this module", "BIG")}`.replace(CLOSED, `${CLOSED}\nstatus jiggles`));

pick("Squares");
await settle();
see("a sample, picked, runs", finished(
  " 1             1             1", " 2             4             8", " 3             9             27",
  " 4             16            64", " 5             25            125", " 6             36            216",
  " 7             49            343", " 8             64            512", " 9             81            729",
  " 10            100           1000"));

// Each sample gets the same 40 turns. One that hasn't finished by then is held
// as running, and Stop ends it.
const SAMPLES = {
  "Counting forever": "running",
  "Eight queens": "running",
  "Fibonacci": "finished ✓",
  "Guess a number (type your own)": "waiting for a line",
  "Hello": "finished ✓",
  "Pixels: plasma (PLOT)": "finished ✓",
  "Screen: Mandelbrot": "finished ✓",
  "Screen: Mandelbrot zoom (SLEEP)": "running",
  "Screen: colour bars": "finished ✓",
  "Screen: sine wave": "finished ✓",
  "Screen: the maze, forever": "running",
  "Sieve of Eratosthenes": "running",
  "Square roots by Newton": "finished ✓",
  "Squares": "finished ✓",
  "Temperature table": "finished ✓",
};
same("the samples offered", $("sample").children.map((o) => o.value).join(), Object.keys(SAMPLES).join());
for (const [name, status] of Object.entries(SAMPLES)) {
  pick(name);
  await fire(40);
  same(name, $("status").textContent, status);
  if (status === "running") await click("stop");
  held++;
  lastHeld = name;
}

console.log(`page_check: ${held} steps held, ${Math.round(performance.now() - started)} ms`);
