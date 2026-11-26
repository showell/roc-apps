// sandbox.js: the Nibble sandbox, any program with no puzzle around it.
// Six lines, each free; the trace on the four inputs; and, where the puzzle
// page has its verdict, the problem the program decides: the inputs it
// accepts and the problem's name in the puzzle table. A program loads by its
// number too. The machine, the table and the drawing parts are machine.js's.
// Nothing is kept between visits: a reload starts at all nada.
// web/build.shale rewrites machine.js's name to its hashed one.

import { STEPS, INPUTS, OPS, PUZZLES, machine, codeOf, programOf, setText, el, drawOps, opTip, machineCode, CODE_EXPLAIN, traceTable } from "./machine.5fbe919a2979e99e.js";

const PROGRAMS = 4 ** STEPS;
let program = programOf(0);

const panel = document.getElementById("sandbox");
drawOps(document.getElementById("ops"));

// The parts that stay: the decided problem, the actions (Clear, the number
// to load, the machine code and its "?"), the code's explanation, the lines
// and the trace. A pick redraws the lines, the trace, the problem and the code.
const decided = el("div", { class: "decided", id: "decided" });
const clear = el("button", { type: "button", id: "clear", text: "Clear" });
clear.addEventListener("click", () => { program = programOf(0); draw(); });

const number = el("input", { type: "text", inputmode: "numeric", id: "program-number", placeholder: "0 to 4095", "aria-label": "Program number, 0 to 4095", autocomplete: "off" });
const load = el("form", { class: "load", id: "load" }, el("label", { for: "program-number", text: "Program #" }), number, el("button", { type: "submit", id: "load-button", text: "Load" }));
// A number from 0 to 4095 loads that program; anything else marks the box
// and loads nothing.
load.addEventListener("submit", (e) => {
  e.preventDefault();
  const said = number.value.trim();
  const n = /^\d+$/.test(said) ? Number(said) : -1;
  const ok = n >= 0 && n < PROGRAMS;
  number.classList.toggle("bad", !ok);
  number.title = ok ? "" : "A program's number is 0 to 4095.";
  if (ok) { program = programOf(n); draw(); }
});

const code = el("code", { id: "machine-code" });
const codeHelp = el("button", { type: "button", class: "code-help", id: "code-help", title: "What are these bits?", "aria-expanded": "false", text: "?" });
const codeExplain = el("p", { class: "hint", id: "code-explain", text: CODE_EXPLAIN });
codeExplain.hidden = true;
codeHelp.addEventListener("click", () => {
  codeExplain.hidden = !codeExplain.hidden;
  codeHelp.setAttribute("aria-expanded", String(!codeExplain.hidden));
});

const slots = el("div", { class: "slots", id: "slots" });
const trace = el("div", { class: "trace", id: "trace" });
panel.replaceChildren(
  decided,
  el("div", { class: "actions" }, clear, load, el("span", { class: "machine" }, code, codeHelp)),
  codeExplain,
  slots,
  trace,
);

// The problem a program decides: its accepted inputs, a language's bits as
// the table codes them, and that problem's name.
function drawDecided() {
  const lang = machine.accepts(codeOf(program));
  const accepted = INPUTS.filter((n) => (lang >> n) & 1);
  const problem = PUZZLES.find((p) => p.code === lang);
  decided.replaceChildren("This program decides ", el("code", { id: "decided-name", text: problem.name }),
    ": it accepts ", el("span", { id: "decided-set", text: setText(accepted) }), " and rejects the rest.");
}

function draw() {
  slots.replaceChildren(...program.map((op, line) => {
    const row = el("div", { class: "slot", "data-line": String(line) }, el("span", { class: "num", text: String(line + 1) }));
    OPS.forEach((o, c) => {
      const b = el("button", { type: "button", class: o.name + (c === op ? " on" : ""), title: opTip(c), "data-slot": String(line), "data-op": o.name, text: o.name });
      b.addEventListener("click", () => { program[line] = c; draw(); });
      row.append(b);
    });
    return row;
  }));
  trace.replaceChildren(traceTable(program, (tag, n, attrs) => el(tag, { ...attrs, "data-input": String(n) })));
  code.textContent = machineCode(program);
  drawDecided();
}

draw();
