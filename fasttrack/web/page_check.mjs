// page_check -- plays Fast Track through the real page, with no browser.
//
//   node fasttrack/web/page_check.mjs <build-dir>
//   SEED=42 SETUP=5 SEATS=hccc TEAMS=anytime CLICKS=300 SHOT=board.png node fasttrack/web/page_check.mjs <build-dir>
//
// It loads <build-dir>'s fasttrack.wasm and roc_glue.js and runs
// fasttrack.js -- the page's own file, unchanged -- against a stand-in
// document just large enough for it. Then it PLAYS. When the view asks for
// a tick (the computer's seat, SEATS as in the page's ?seats=, default hccc)
// it sends it, as the page's timer would. In a person's seat it clicks what
// the page offers, the way a person would: "done" when it is there, else the
// first square that takes a click, else the first card button that is
// enabled, and "oops" every seventh step when it is offered. It stops when
// someone wins.
//
// **EVERY CLICK IS CHECKED.** After each one: sixteen pieces are on the board
// (a move never loses or copies one), the board has its 89 squares, and the
// document holds exactly the nodes Roc sent. The default run (red a person)
// also checks the first deal against the one ElmRandom's expects pin.
//
// With SHOT set it paints the last board to a PNG through
// canvas_apps/web/mini_canvas.mjs, and prints the page's text beside it.
import { readFileSync, writeFileSync } from "node:fs";
import vm from "node:vm";

const dir = process.argv[2];
if (!dir) { console.error("usage: node page_check.mjs <build-dir>"); process.exit(2); }
const SEED = Number(process.env.SEED ?? 0);
const SETUP = Number(process.env.SETUP ?? 0);
const CLICKS = Number(process.env.CLICKS ?? 400);
const SHOT = process.env.SHOT;
const SEATS = process.env.SEATS ?? "hccc";
const TEAMS = process.env.TEAMS ?? "";

// ── a stand-in document ────────────────────────────────────────────────────

class Node {
  constructor(tag, text) {
    this.tag = tag; this.text = text; this.children = []; this.parent = null;
    this.attrs = {}; this.style = { cssText: "" }; this.disabled = false; this.listeners = [];
  }
  appendChild(child) {
    if (child.parent) child.parent.children = child.parent.children.filter((c) => c !== child);
    child.parent = this;
    this.children.push(child);
    return child;
  }
  replaceChildren() {
    for (const c of this.children) c.parent = null;
    this.children = [];
  }
  setAttribute(name, value) { this.attrs[name] = String(value); }
  set textContent(v) { this.children = [new Node("#text", v)]; }
  addEventListener(kind, f) { if (kind === "click") this.listeners.push(f); }
  click() { for (const f of this.listeners) f(); }
  get textContent() { return this.tag === "#text" ? this.text : this.children.map((c) => c.textContent).join(""); }
}

const document = {
  createElement: (tag) => new Node(tag, ""),
  createElementNS: (_ns, tag) => new Node(tag, ""),
  createTextNode: (text) => new Node("#text", text),
};

function walk(node, f) { f(node); for (const c of node.children) walk(c, f); }

function countNodes(root) {
  let n = 0;
  // The board's own children are not the page's nodes.
  const visit = (node) => { n++; if (node.tag !== "svg") node.children.forEach(visit); };
  root.children.forEach(visit);
  return n;
}

// The page's text, a line per block, as a reader would see it.
function pageText(root) {
  const lines = [];
  let line = "";
  const blocks = new Set(["div", "hr", "br"]);
  const visit = (node) => {
    if (node.tag === "#text") { line += node.text; return; }
    if (node.tag === "svg") { line += "[board]"; return; }
    if (blocks.has(node.tag) && line.trim()) { lines.push(line.trim()); line = ""; }
    if (node.tag === "button") {
      line += ` [${node.textContent}${node.disabled ? "" : "*"}] `;
      return;
    }
    node.children.forEach(visit);
    if (blocks.has(node.tag) && line.trim()) { lines.push(line.trim()); line = ""; }
  };
  root.children.forEach(visit);
  if (line.trim()) lines.push(line.trim());
  return lines.join("\n");
}

// ── the page, as a browser would load it ───────────────────────────────────

const context = vm.createContext({ TextDecoder, DataView, Uint8Array, console });
vm.runInContext(readFileSync(`${dir}/roc_glue.js`, "utf8") + "\nglobalThis.RocGlue = RocGlue;", context);
vm.runInContext(readFileSync(new URL("./fasttrack.js", import.meta.url), "utf8") + "\nglobalThis.FastTrack = FastTrack;", context);
const { FastTrack } = context;

const { instance } = await WebAssembly.instantiate(readFileSync(`${dir}/fasttrack.wasm`), {});
const game = FastTrack.game(instance);
let last = null;
const watched = { ...game, view: () => (last = game.view()) };

const root = new Node("div", "");
game.start(SEED, SETUP, FastTrack.seatBits(SEATS), FastTrack.teamStyle(TEAMS));
const page = FastTrack.mount(document, root, watched);
page.draw();

let failures = 0;
function fail(msg) { console.log(`FAIL: ${msg}`); failures++; }

function check(step) {
  const pieces = last.slots.filter((s) => s.piece !== "").length;
  if (pieces !== 16) fail(`step ${step}: ${pieces} pieces on the board`);
  if (last.slots.length !== 89) fail(`step ${step}: ${last.slots.length} squares`);
  const drawn = countNodes(root);
  if (drawn !== last.nodes.length) fail(`step ${step}: ${drawn} nodes in the document, ${last.nodes.length} from Roc`);
  let svg = null;
  walk(root, (n) => { if (n.tag === "svg") svg = n; });
  if (!svg || svg.children.length !== 89) fail(`step ${step}: the board is not in the page`);
}

check(0);

// The cards-home overlay cycles off, plain, with a free face card. Plain, the
// mover's own B4 reads 0, its pen 3 and DS 2; with the face card DS reads 1;
// off again, no square has a label.
function labelOf(zoneIndex, square) {
  const e = last.slots[zoneIndex * 22 + square];
  return e ? e.label : undefined;
}
page.onClick(4);
{
  const labels = last.slots.filter((s) => s.label !== "").length;
  // The mover's zone is drawn first: HP1 is square 0, B4 square 7.
  if (labelOf(0, 7) !== "0" || labelOf(0, 0) !== "3" || labels < 60) fail(`cards home: B4 ${labelOf(0, 7)}, pen ${labelOf(0, 0)}, ${labels} labels`);
}
if (labelOf(0, 9) !== "2") fail(`cards home: DS ${labelOf(0, 9)}, not 2`);
page.onClick(4);
if (labelOf(0, 9) !== "1") fail(`cards home with a face card: DS ${labelOf(0, 9)}, not 1`);
page.onClick(4);
if (last.slots.some((s) => s.label !== "")) fail("cards home stays on after it is hidden");
check(0);
const firstPage = pageText(root);
if (SEED === 0 && SETUP === 0 && SEATS[0] === "h") {
  // Seed 0 deals red 9 J 5 5 J (Game.roc's expect); none leaves the pen.
  const expected = "[9*]  [J*]  [5*]  [5*]  [J*]\nclick a card to discard";
  if (!firstPage.includes(expected)) fail(`the first deal:\n${firstPage}`);
}

// ── play ───────────────────────────────────────────────────────────────────

// What the game offers to click. The cards-home toggle is always there and
// changes only the view, so it is not one of them.
function clickables() {
  const buttons = [];
  const squares = [];
  walk(root, (n) => {
    if (n.tag === "button" && !n.disabled && n.listeners.length && !/cards home$/.test(n.textContent)) buttons.push(n);
    if (n.tag === "g" && n.attrs.cursor === "pointer") squares.push(n);
  });
  return { buttons, squares };
}

const counts = { done: 0, square: 0, card: 0, oops: 0, tick: 0 };
const started = performance.now();
let step = 0;
for (; step < CLICKS && last.winner === ""; step++) {
  if (last.tick) {
    const { buttons, squares } = clickables();
    if (buttons.length || squares.length) fail(`step ${step + 1}: the computer's turn offers clicks`);
    counts.tick++;
    page.onClick(last.tick);
    check(step + 1);
    continue;
  }
  const { buttons, squares } = clickables();
  const named = (label) => buttons.find((b) => b.textContent === label);
  let target;
  let kind;
  if (step % 7 === 6 && named("oops")) { target = named("oops"); kind = "oops"; }
  else if (named("done")) { target = named("done"); kind = "done"; }
  else if (squares.length) { target = squares[0]; kind = "square"; }
  else { target = buttons.find((b) => b.textContent !== "oops"); kind = "card"; }
  if (!target) { fail(`step ${step + 1}: nothing to click\n${pageText(root)}`); break; }
  counts[kind]++;
  target.click();
  check(step + 1);
  if (failures > 5) break;
}
const ms = (performance.now() - started) / Math.max(step, 1);

const turns = counts.done;
const won = last.winner ? `, ${last.winner} won` : "";
console.log(`seed ${SEED} setup ${SETUP} seats ${SEATS}${TEAMS ? ` teams ${TEAMS}` : ""}: ${step} clicks (${counts.card} cards, ${counts.square} squares, ${counts.oops} oops, ${turns} turns by hand, ${counts.tick} computer clicks${won}), ${ms.toFixed(3)} ms a click`);
if (SEATS.includes("h") && turns === 0) fail("no turn ever finished by hand");
if (SEATS.includes("h") && counts.square === 0) fail("no piece ever moved by hand");
if (/[cn]/.test(SEATS) && counts.tick === 0) fail("the computer never played");
if (last.winner && (last.tick || clickables().buttons.length || clickables().squares.length)) fail("the game goes on after a win");

if (SHOT) {
  const { createCanvas } = await import(new URL("../../canvas_apps/web/mini_canvas.mjs", import.meta.url));
  writeFileSync(SHOT, paint(createCanvas, last).toPNG());
  console.log(`--- the page, last:\n${pageText(root)}\n--- board: ${SHOT}`);
}

// The board as the SVG draws it: each outline is a one-pixel ring, the
// stroke's colour under the fill's, since mini_canvas only fills.
function paint(createCanvas, view) {
  const COLORS = {
    white: "#ffffff", black: "#000000", gray: "#808080", red: "#ff0000", blue: "#0000ff",
    green: "#008000", purple: "#800080", aqua: "#00ffff", brown: "#a52a2a",
    lightblue: "#add8e6", lightcyan: "#e0ffff", lightgreen: "#90ee90", mintcream: "#f5fffa",
  };
  const hex = (name) => { if (!COLORS[name]) throw new Error(`page_check: no colour ${name}`); return COLORS[name]; };
  const size = Math.ceil(view.board_size);
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "#ffffff";
  ctx.fillRect(0, 0, size, size);
  const disc = (x, y, r, color) => { ctx.fillStyle = hex(color); ctx.beginPath(); ctx.arc(x, y, r, 0, 2 * Math.PI); ctx.fill(); };
  const box = (x, y, w, color) => { ctx.fillStyle = hex(color); ctx.fillRect(x - w / 2, y - w / 2, w, w); };
  for (const s of view.slots) {
    if (s.square) { box(s.cx, s.cy, s.size + 1, s.stroke); box(s.cx, s.cy, s.size - 1, s.fill); }
    else { disc(s.cx, s.cy, s.size / 2 + 0.5, s.stroke); disc(s.cx, s.cy, s.size / 2 - 0.5, s.fill); }
    if (s.piece !== "") disc(s.cx, s.cy, s.piece_r + 0.5, s.piece);
  }
  return canvas;
}

if (failures) { console.log(`${failures} failure(s)`); process.exit(1); }
console.log("ok");
