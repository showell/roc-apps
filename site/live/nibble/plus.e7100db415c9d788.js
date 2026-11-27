// plus.js: the Nibble++ sandbox. AX holds 0 to 15, and a program is 7 lines
// of half, zero, decr and mod2; it opens as zero, decr, zero, decr, zero,
// decr, decr, which decides {0, 1, 2}. The page shows the language a program
// decides, its machine code and number, and its lines' buttons. The machine
// is the Roc port's roc/Plus.roc compiled to wasm (roc/PlusWasm.roc on
// web/platform/plus.roc). Nothing is kept between visits. It shares
// nibble.css with the Nibble pages but not machine.js, whose module loads
// Nibble's wasm and puzzle table as it starts. The languages' names are
// web/plus_names.c's table, plus_names.bin (its header says how it is laid
// out; docs/NIBBLE_PLUS_NAMES.md says how the names are chosen).
// web/build.shale rewrites the wasm's and the table's names to their hashed
// ones.

const LINES = 7;
const INPUTS = Array.from({ length: 16 }, (_, n) => n);
// PlusWasm.roc's status for an accepted run.
const ACCEPTED = 1;
// The ops in code order, as src/plus.h numbers them.
const OPS = [
  { name: "half", comment: "set AX to AX / 2, rounding down" },
  { name: "zero", comment: "accept original input if AX = 0" },
  { name: "decr", comment: "reject zero or decrement AX" },
  { name: "mod2", comment: "set AX to AX % 2" },
];
// The order the ops are shown in, by code: the workhorses zero, decr and
// mod2, then half, which shortens programs.
const SHOWN = [1, 2, 3, 0];
const ZERO = 1, DECR = 2;
const START = [ZERO, DECR, ZERO, DECR, ZERO, DECR, DECR];

const LANGUAGES = 65536;
const fetched = (url) => fetch(url).then((r) => {
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return r.arrayBuffer();
});

// The names table: its tokens, each ended by a newline, then a 0 byte; then
// each language's name as its tokens' numbers (from 1), a byte each, ended
// by a 0 byte, none for a language with no name. A name is its tokens joined
// by `_`, after `is_` unless it starts with has_, lacks_, grumpy or
// always_true. The reader gives a language's name, or null.
function readNames(bytes) {
  const end = bytes.indexOf(0);
  if (end < 0) throw new Error("plus_names.bin has no vocabulary");
  const tokens = [null, ...new TextDecoder().decode(bytes.subarray(0, end)).split("\n").slice(0, -1)];
  const starts = new Uint32Array(LANGUAGES + 1);
  let at = end + 1;
  for (let lang = 0; lang < LANGUAGES; lang++) {
    starts[lang] = at;
    at = bytes.indexOf(0, at) + 1;
    if (at === 0) throw new Error(`plus_names.bin ends at language ${lang}`);
  }
  starts[LANGUAGES] = at;
  if (at !== bytes.length) throw new Error("plus_names.bin runs past its last language");
  return (lang) => {
    const words = Array.from(bytes.subarray(starts[lang], starts[lang + 1] - 1), (t) => tokens[t]);
    if (words.length === 0) return null;
    if (words.includes(undefined)) throw new Error(`plus_names.bin's language ${lang} has a token past its vocabulary`);
    const bare = /^(has_|lacks_|grumpy$|always_true$)/.test(words[0]);
    return (bare ? "" : "is_") + words.join("_");
  };
}

const [machine, nameOf] = await Promise.all([
  fetched("plus.30f5a0b8d928868e.wasm").then((b) => WebAssembly.instantiate(b)).then((w) => w.instance.exports),
  fetched("plus_names.e25f4cc7f9e84c31.bin").then((b) => readNames(new Uint8Array(b))),
]).catch((e) => {
  const said = document.getElementById("loading");
  said.className = "err";
  said.textContent = `The machine didn't load: ${e.message}`;
  throw e;
});

const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v; else if (k === "text") e.textContent = v; else e.setAttribute(k, v);
  }
  for (const k of kids) e.append(k);
  return e;
};
const setText = (set) => (set.length === 0 ? "{ }" : `{${set.join(", ")}}`);
// A set with each run of three or more written as its ends: {0–13, 15}.
function rangeText(set) {
  const parts = [];
  for (let i = 0; i < set.length;) {
    let j = i;
    while (j + 1 < set.length && set[j + 1] === set[j] + 1) j++;
    if (j - i >= 2) parts.push(`${set[i]}–${set[j]}`);
    else for (let k = i; k <= j; k++) parts.push(String(set[k]));
    i = j + 1;
  }
  return parts.length === 0 ? "{ }" : `{${parts.join(", ")}}`;
}

// A program is its ops' codes. Its code, for the machine, is two bits a
// line, line 1 lowest, as plus_pack; the wasm takes it as a BigInt. Its
// number, for the reader, is base 4 with line 1 the highest digit, so its
// digits and its bits read in line order: 14 bits, 0 to 16,383.
const codeOf = (program) => BigInt(program.reduce((sum, op, i) => sum + op * 4 ** i, 0));
const numberOf = (program) => program.reduce((sum, op) => sum * 4 + op, 0);

// A button's tip: what its op does to each AX, from the machine itself (the
// op alone on line 1).
function opTip(op) {
  const to = INPUTS.map((n) => {
    const word = machine.after(n, BigInt(op), 1);
    const halted = (word >> 4) & 1, status = (word >> 5) & 3;
    return `${n}->${halted ? (status === ACCEPTED ? "A" : "R") : word & 15}`;
  });
  const keys = [to.some((t) => t.endsWith("A")) ? "A accepts" : null, to.some((t) => t.endsWith("R")) ? "R rejects" : null].filter(Boolean);
  return `${OPS[op].name}: ${to.join(", ")}${keys.length ? ` (${keys.join(", ")})` : ""}`;
}
const TIPS = OPS.map((_, op) => opTip(op));

const legend = document.getElementById("ops");
for (const op of SHOWN.map((k) => OPS[k])) legend.append(el("dt", { text: op.name }), el("dd", { text: op.comment }));

const program = [...START];

const decided = el("div", { class: "decided", id: "decided" });
const code = el("code", { id: "machine-code" });
const codeHelp = el("button", { type: "button", class: "code-help", id: "code-help", title: "What are these bits?", "aria-expanded": "false", text: "?" });
const codeExplain = el("p", { class: "hint", id: "code-explain",
  text: `The machine code: each line's opcode in two bits, line 1 first (zero 01, decr 10, mod2 11, half 00). ${LINES} lines make ${2 * LINES} bits, so there are ${(4 ** LINES).toLocaleString("en-US")} programs, numbered 0 to ${4 ** LINES - 1}: read the bits as one binary number, line 1 first.` });
codeExplain.hidden = true;
codeHelp.addEventListener("click", () => {
  codeExplain.hidden = !codeExplain.hidden;
  codeHelp.setAttribute("aria-expanded", String(!codeExplain.hidden));
});
const slots = el("div", { class: "slots", id: "slots" });
document.getElementById("sandbox").replaceChildren(decided, el("p", { class: "machine-line" }, code, " ", codeHelp), codeExplain, slots);

// The language a program decides: its name, when the table has one, its
// accepted inputs with runs written as ranges, its code (the sum of 2^n over
// them), and the inputs one by one.
function drawDecided() {
  const lang = machine.accepts(codeOf(program), LINES);
  const accepted = INPUTS.filter((n) => (lang >> n) & 1);
  const named = nameOf(lang);
  decided.replaceChildren("This program decides ",
    ...(named === null ? ["the language "] : [el("code", { id: "decided-name", text: named }), ", "]),
    el("code", { id: "decided-range", text: rangeText(accepted) }),
    ", #", el("span", { id: "decided-code", text: String(lang) }), " of 65,536: it accepts ",
    el("span", { id: "decided-set", text: setText(accepted) }), " and rejects the rest.");
}

function draw() {
  slots.replaceChildren(...program.map((op, line) => {
    const row = el("div", { class: "slot", "data-line": String(line) }, el("span", { class: "num", text: String(line + 1) }));
    SHOWN.forEach((k) => {
      const o = OPS[k];
      const b = el("button", { type: "button", class: o.name + (k === op ? " on" : ""), title: TIPS[k], "data-slot": String(line), "data-op": o.name, text: o.name });
      b.addEventListener("click", () => { program[line] = k; draw(); });
      row.append(b);
    });
    return row;
  }));
  code.textContent = `${program.map((op) => op.toString(2).padStart(2, "0")).join(" ")}  (#${numberOf(program)})`;
  drawDecided();
}

draw();
