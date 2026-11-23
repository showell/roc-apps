// page_check -- the JavaScript subset's page, run with no browser.
//
//   node js/page_check.mjs <build-dir> <tests-dir>
//
// It loads <build-dir>/js.wasm through the page's own js_runner.js and runs
// every program in <tests-dir> through it, each held to what node itself
// prints for it (the program run in a fresh context whose console.log
// writes util.format's line, as console.log does); each program in
// <tests-dir>/refused must be refused with the message its first line
// names. Then it builds the page itself, js_page.js, on a stand-in document,
// and presses Run on every sample: each runs to its end but the one outside
// the subset, which is refused.
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import util from "node:util";
import vm from "node:vm";

const [dir, tests] = process.argv.slice(2);
if (!dir || !tests) { console.error("usage: node js/page_check.mjs <build-dir> <tests-dir>"); process.exit(2); }

let failures = 0;
function fail(why) { failures++; console.error(`page_check: FAIL ${why}`); }

const { loadRunner } = await import(pathToFileURL(join(dir, "js_runner.js")).href);
const runner = await loadRunner(readFileSync(join(dir, "js.wasm")));

function nodeOutput(src) {
  let out = "";
  const console = { log: (...args) => { out += util.format(...args) + "\n"; } };
  vm.runInNewContext(src, { console });
  return out;
}

const programs = readdirSync(tests).filter((f) => f.endsWith(".js")).sort();
for (const f of programs) {
  const src = readFileSync(join(tests, f), "utf8");
  const want = nodeOutput(src);
  const got = runner.run(src);
  if (got.ending !== "ran") fail(`${f}: the page's run ${got.ending}: ${got.text.trim().split("\n").pop()}`);
  else if (got.text !== want) fail(`${f}: the page printed what node does not`);
}

const refused = readdirSync(join(tests, "refused")).filter((f) => f.endsWith(".js")).sort();
for (const f of refused) {
  const src = readFileSync(join(tests, "refused", f), "utf8");
  const must = src.split("\n")[0].replace(/^\/\/ refused: /, "");
  const got = runner.run(src);
  const last = got.text.trim().split("\n").pop();
  if (got.ending === "ran" || got.ending === "crashed" || !last.startsWith("js: ") || !last.includes(must)) {
    fail(`refused/${f}: wanted \`${must}\`, the page said \`${last}\` (${got.ending})`);
  }
}

// ── the page itself, on a stand-in document ───────────────────────────────

class Element {
  constructor(tag) { this.tag = tag; this.children = []; this.listeners = {}; this.textContent = ""; this.value = ""; this.className = ""; }
  appendChild(c) { this.children.push(c); return c; }
  addEventListener(kind, fn) { (this.listeners[kind] ??= []).push(fn); }
  fire(kind) { for (const fn of this.listeners[kind] ?? []) fn(); }
}
globalThis.window = { JS_PAGE_CHECK: true };
globalThis.document = { head: new Element("head"), body: new Element("body"), createElement: (t) => new Element(t) };
const { buildPage } = await import(pathToFileURL(join(dir, "js_page.js")).href);
const page = buildPage(runner);
const samples = page.picker.children.map((o) => o.value);
if (samples.length < 2) fail(`the page offers ${samples.length} samples`);
for (const name of samples) {
  page.picker.value = name;
  page.picker.fire("change");
  page.runButton.fire("click");
  const wantRefused = name === "Outside the subset";
  const said = page.status.textContent;
  if (page.output.textContent === "") fail(`sample ${name}: the page printed nothing`);
  if (wantRefused !== said.startsWith("refused")) fail(`sample ${name}: the status says \`${said}\``);
}

const total = programs.length + refused.length + samples.length;
if (failures > 0) { console.error(`page_check: ${failures} of ${total} failed`); process.exit(1); }
console.log(`page_check: ${programs.length} programs print what node prints, ${refused.length} refused, ${samples.length} samples run on the page`);
