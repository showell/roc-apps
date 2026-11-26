// machine.js: what the two Nibble pages share, the puzzle page (nibble.js)
// and the sandbox (sandbox.js). The machine is the Roc port's
// roc/Machine.roc compiled to wasm (roc/NibbleWasm.roc on web/platform);
// the opcodes' comments and the puzzles, one a problem, come from
// web/puzzles.c's table, puzzles.json. Beside them: a program's code and
// number, the op tips, the machine-code line and the trace's step rows.
// web/build.shale rewrites the two fetched names to their hashed ones.

export const STEPS = 6;
export const INPUTS = [0, 1, 2, 3];
// run_progam's Status.
export const NONE = 0, ACCEPTED = 1;

const [wasm, table] = await Promise.all([
  fetch("nibble.c9f85bcae2462a60.wasm").then((r) => r.arrayBuffer()).then((b) => WebAssembly.instantiate(b)),
  fetch("puzzles.60c40870ab0a98bf.json").then((r) => r.json()),
]).catch((e) => {
  const said = document.getElementById("loading");
  said.className = "err";
  said.textContent = `The machine didn't load: ${e.message}`;
  throw e;
});
export const machine = wasm.instance.exports;
export const { ops: OPS, puzzles: PUZZLES } = table;

// A program is its ops' codes. Its code, for the machine, is base 4 with op i
// digit i, as `assemble`. Its number, for the reader, is base 4 with line 1
// the highest digit, so its digits and its twelve bits read in line order.
export const codeOf = (program) => program.reduce((sum, op, i) => sum + op * 4 ** i, 0);
export const numberOf = (program) => program.reduce((sum, op) => sum * 4 + op, 0);
// The program numbered `n`, 0 to 4095: line 1 its highest base-4 digit.
export const programOf = (n) => Array.from({ length: STEPS }, (_, k) => Math.floor(n / 4 ** (STEPS - 1 - k)) % 4);
export const unpack = (word) => ({ ax: word & 3, halted: (word >> 2) & 1, status: (word >> 3) & 3 });
export const setText = (set) => (set.length === 0 ? "{ }" : `{${set.join(", ")}}`);
export const outcomeOf = (code, n) => (machine.status(n, code) === ACCEPTED ? "accept" : "reject");
// What a run ended as, in the result row: a run off the end says why it
// rejects.
export const endText = (code, n) => (machine.status(n, code) === NONE ? "reject: ran off the end" : outcomeOf(code, n));

export const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v; else if (k === "text") e.textContent = v; else e.setAttribute(k, v);
  }
  for (const k of kids) e.append(k);
  return e;
};

// The opcodes' key under the page, from their comments.
export function drawOps(legend) {
  for (const op of OPS) legend.append(el("dt", { text: op.name }), el("dd", { text: op.comment.replace(/^# /, "") }));
}

// A button's tip: what its op does to each AX, from the machine itself (the
// op alone on line 1): decr is "0->R, 1->0, 2->1, 3->2 (R rejects)"; the key
// names only the letters the tip uses.
export function opTip(op) {
  const to = INPUTS.map((n) => {
    const m = unpack(machine.after(n, op, 1));
    return `${n}->${m.halted ? (m.status === ACCEPTED ? "A" : "R") : m.ax}`;
  });
  const keys = [to.some((t) => t.endsWith("A")) ? "A accepts" : null, to.some((t) => t.endsWith("R")) ? "R rejects" : null].filter(Boolean);
  return `${OPS[op].name}: ${to.join(", ")}${keys.length ? ` (${keys.join(", ")})` : ""}`;
}

// The program's twelve bits, line 1 first, and its number among the 4,096.
const BITS = ["00", "01", "10", "11"];
export const machineCode = (prog) => `${prog.map((op) => BITS[op]).join(" ")}  (#${numberOf(prog)})`;
export const CODE_EXPLAIN = "The machine code: each line's opcode in two bits, line 1 first (nada 00, zero 01, decr 10, mod2 11). "
  + "Six lines make twelve bits, so there are 4,096 programs, numbered 0 to 4095: read the twelve bits as one binary number, line 1 first.";

// The trace: a row a step, so it lines up with the program's lines, and a
// column an input, which fits a phone's width. A cell is AX after that
// step, or accept or reject where the run halted; then a row of how each run
// ended. `cell(tag, n, attrs)` makes input n's cell (the puzzle page marks a
// wrong input's column), and `more` is rows the page adds below.
export function traceTable(program, cell, more = []) {
  const code = codeOf(program);
  const head = el("tr", {}, el("th", { class: "step", text: "input" }), ...INPUTS.map((n) => cell("th", n, { class: "mono", text: String(n) })));
  const rows = program.map((op, k) => el("tr", { "data-step": String(k + 1) },
    el("th", { class: "step mono", text: `${k + 1} ${OPS[op].name}` }),
    ...INPUTS.map((n) => {
      const m = unpack(machine.after(n, code, k + 1));
      const before = k === 0 ? null : unpack(machine.after(n, code, k));
      if (m.halted && before?.halted) return cell("td", n, { class: "halt", text: "" });
      if (m.halted) return cell("td", n, { class: "mono", text: m.status === ACCEPTED ? "accept" : "reject" });
      return cell("td", n, { class: "mono", text: `AX=${m.ax}` });
    })));
  rows.push(el("tr", { class: "end", "data-row": "result" }, el("th", { class: "step", text: "result" }), ...INPUTS.map((n) => cell("td", n, { text: endText(code, n) }))));
  return el("table", {}, el("thead", {}, head), el("tbody", {}, ...rows, ...more));
}
