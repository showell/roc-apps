// plus.js: the Nibble++ sandbox, the Nibble sandbox (sandbox.js) for
// Nibble++. AX holds 0 to 15, a program is 1 to 30 lines of half, zero, decr
// and mod2, and it opens as thirty decrs. The machine is the Roc port's
// roc/Plus.roc compiled to wasm (roc/PlusWasm.roc on web/platform/plus.roc).
// The trace is a row an input, after the line the step buttons are on, so
// 16 inputs fit a phone; the box above the program is the language it
// decides. A program loads by its number too: two bits a line, line 1 first,
// up to 60 bits, so the numbers are BigInts. Nothing is kept between visits.
// It shares nibble.css with the Nibble pages but not machine.js, whose
// module loads Nibble's wasm and puzzle table as it starts.
// web/build.shale rewrites the wasm's name to its hashed one.

const MAX_LINES = 30;
const INPUTS = Array.from({ length: 16 }, (_, n) => n);
// PlusWasm.roc's status.
const NONE = 0, ACCEPTED = 1;
// The ops in code order, as src/plus.h numbers them.
const OPS = [
  { name: "half", comment: "set AX to AX / 2, rounding down" },
  { name: "zero", comment: "accept original input if AX = 0" },
  { name: "decr", comment: "reject zero or decrement AX" },
  { name: "mod2", comment: "set AX to AX % 2" },
];
const DECR = 2;
const START = () => Array(MAX_LINES).fill(DECR);

const machine = await fetch("plus.30f5a0b8d928868e.wasm").then((r) => r.arrayBuffer()).then((b) => WebAssembly.instantiate(b))
  .then((w) => w.instance.exports).catch((e) => {
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

// A program is its ops' codes. Its code, for the machine, is two bits a
// line, line 1 lowest, as plus_pack. Its number, for the reader, is base 4
// with line 1 the highest digit, so its digits and its bits read in line
// order.
const codeOf = (program) => program.reduce((sum, op, i) => sum | (BigInt(op) << BigInt(2 * i)), 0n);
const numberOf = (program) => program.reduce((sum, op) => sum * 4n + BigInt(op), 0n);
const programOf = (n, lines) => Array.from({ length: lines }, (_, k) => Number((n >> BigInt(2 * (lines - 1 - k))) & 3n));
const unpack = (word) => ({ ax: word & 15, halted: (word >> 4) & 1, status: (word >> 5) & 3 });
const largest = (lines) => 4n ** BigInt(lines) - 1n;

// A button's tip: what its op does to each AX, from the machine itself (the
// op alone on line 1).
function opTip(op) {
  const to = INPUTS.map((n) => {
    const m = unpack(machine.after(n, BigInt(op), 1));
    return `${n}->${m.halted ? (m.status === ACCEPTED ? "A" : "R") : m.ax}`;
  });
  const keys = [to.some((t) => t.endsWith("A")) ? "A accepts" : null, to.some((t) => t.endsWith("R")) ? "R rejects" : null].filter(Boolean);
  return `${OPS[op].name}: ${to.join(", ")}${keys.length ? ` (${keys.join(", ")})` : ""}`;
}
const TIPS = OPS.map((_, op) => opTip(op));

const legend = document.getElementById("ops");
for (const op of OPS) legend.append(el("dt", { text: op.name }), el("dd", { text: op.comment }));

let program = START();
// The trace shows the machine after this many lines; it follows the end of
// the program until a step button moves it.
let step = MAX_LINES;
let atEnd = true;

const panel = document.getElementById("sandbox");
const decided = el("div", { class: "decided", id: "decided" });
const reset = el("button", { type: "button", id: "reset", text: "Reset" });
reset.addEventListener("click", () => { program = START(); atEnd = true; draw(); });
const addLine = el("button", { type: "button", id: "add-line", text: "+ line" });
addLine.addEventListener("click", () => { if (program.length < MAX_LINES) { program.push(DECR); draw(); } });
const removeLine = el("button", { type: "button", id: "remove-line", text: "− line" });
removeLine.addEventListener("click", () => { if (program.length > 1) { program.pop(); draw(); } });
const count = el("span", { class: "count", id: "line-count" });

const number = el("input", { type: "text", inputmode: "numeric", id: "program-number", "aria-label": "Program number", autocomplete: "off" });
const load = el("form", { class: "load wide", id: "load" }, el("label", { for: "program-number", text: "Program #" }), number, el("button", { type: "submit", id: "load-button", text: "Load" }));
// A number from 0 to 4^lines - 1 loads that program into the lines there
// are; anything else marks the box and loads nothing.
load.addEventListener("submit", (e) => {
  e.preventDefault();
  const said = number.value.trim();
  const n = /^\d+$/.test(said) ? BigInt(said) : -1n;
  const ok = n >= 0n && n <= largest(program.length);
  number.classList.toggle("bad", !ok);
  number.title = ok ? "" : `A ${program.length}-line program's number is 0 to ${largest(program.length)}.`;
  if (ok) { program = programOf(n, program.length); draw(); }
});

const code = el("code", { id: "machine-code" });
const codeHelp = el("button", { type: "button", class: "code-help", id: "code-help", title: "What are these bits?", "aria-expanded": "false", text: "?" });
const codeExplain = el("p", { class: "hint", id: "code-explain" });
codeExplain.hidden = true;
codeHelp.addEventListener("click", () => {
  codeExplain.hidden = !codeExplain.hidden;
  codeHelp.setAttribute("aria-expanded", String(!codeExplain.hidden));
});

// The step buttons: the trace after line 0 (the inputs), back, on, and the end.
const stepLabel = el("span", { class: "step-label", id: "step-label" });
const moveTo = (k) => { step = Math.max(0, Math.min(program.length, k)); atEnd = step === program.length; draw(); };
const stepButton = (id, text, to) => {
  const b = el("button", { type: "button", id, text });
  b.addEventListener("click", () => moveTo(to()));
  return b;
};
const stepper = el("div", { class: "actions stepper", id: "stepper" },
  stepButton("step-start", "Start", () => 0), stepButton("step-back", "Back", () => step - 1),
  stepButton("step-next", "Step", () => step + 1), stepButton("step-end", "End", () => program.length), stepLabel);

const slots = el("div", { class: "slots", id: "slots" });
const trace = el("div", { class: "trace", id: "trace" });
panel.replaceChildren(
  decided,
  el("div", { class: "actions" }, reset, addLine, removeLine, count),
  el("div", { class: "actions" }, load),
  el("p", { class: "machine-line" }, code, " ", codeHelp),
  codeExplain,
  slots,
  stepper,
  trace,
);

// The language a program decides: its accepted inputs, and its code, the
// sum of 2^n over them.
function drawDecided(c) {
  const lang = machine.accepts(c, program.length);
  const accepted = INPUTS.filter((n) => (lang >> n) & 1);
  decided.replaceChildren("This program decides the language ", el("code", { id: "decided-set", text: setText(accepted) }),
    ", #", el("span", { id: "decided-code", text: String(lang) }), " of 65,536: it accepts those inputs and rejects the rest.");
}

// Input n's run: the line it halted at (0 for none) and how it ended.
function runOf(c, n) {
  for (let k = 1; k <= program.length; k++) {
    const m = unpack(machine.after(n, c, k));
    if (m.halted) return { line: k, status: m.status };
  }
  return { line: 0, status: NONE };
}
const ending = (r) => (r.line === 0 ? "reject: ran off the end" : `${r.status === ACCEPTED ? "accept" : "reject"} at line ${r.line}`);

// The trace: a row an input, AX after `step` lines (or where it halted, if
// it has), then how the run ends.
function drawTrace(c) {
  const head = el("tr", {}, el("th", { class: "step", text: "input" }), el("th", { text: step === 0 ? "start" : `after line ${step}` }), el("th", { text: "result" }));
  const rows = INPUTS.map((n) => {
    const m = unpack(machine.after(n, c, step));
    const r = runOf(c, n);
    const now = m.halted ? `${m.status === ACCEPTED ? "accept" : "reject"} (line ${r.line})` : `AX=${m.ax}`;
    return el("tr", { "data-input": String(n), class: r.status === ACCEPTED ? "accepted" : "" },
      el("th", { class: "step mono", text: String(n) }),
      el("td", { class: "mono" + (m.halted ? " halt" : ""), "data-col": "now", text: now }),
      el("td", { "data-col": "result", text: ending(r) }));
  });
  trace.replaceChildren(el("table", { class: "plus" }, el("thead", {}, head), el("tbody", {}, ...rows)));
}

function draw() {
  if (atEnd || step > program.length) step = program.length;
  atEnd = step === program.length;
  const c = codeOf(program);
  slots.replaceChildren(...program.map((op, line) => {
    const row = el("div", { class: "slot" + (line + 1 === step ? " current" : ""), "data-line": String(line) }, el("span", { class: "num", text: String(line + 1) }));
    OPS.forEach((o, k) => {
      const b = el("button", { type: "button", class: o.name + (k === op ? " on" : ""), title: TIPS[k], "data-slot": String(line), "data-op": o.name, text: o.name });
      b.addEventListener("click", () => { program[line] = k; draw(); });
      row.append(b);
    });
    return row;
  }));
  count.textContent = `${program.length} ${program.length === 1 ? "line" : "lines"}`;
  addLine.disabled = program.length === MAX_LINES;
  removeLine.disabled = program.length === 1;
  number.placeholder = `0 to ${largest(program.length)}`;
  code.textContent = `${program.map((op) => op.toString(2).padStart(2, "0")).join(" ")}  (#${numberOf(program)})`;
  codeExplain.textContent = "The machine code: each line's opcode in two bits, line 1 first (half 00, zero 01, decr 10, mod2 11). "
    + `${program.length} ${program.length === 1 ? "line makes" : "lines make"} ${2 * program.length} bits, so there are ${(largest(program.length) + 1n).toLocaleString("en-US")} programs of this length, numbered 0 to ${largest(program.length)}: read the bits as one binary number, line 1 first.`;
  stepLabel.textContent = `after line ${step} of ${program.length}`;
  drawTrace(c);
  drawDecided(c);
}

draw();
