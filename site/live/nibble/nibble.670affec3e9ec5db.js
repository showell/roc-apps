// nibble.js: the Nibble puzzle page. The machine is src/vm.c compiled to
// wasm (web/nibble.c); the puzzles, their counts and shortest lengths, and
// the opcodes' comments come from web/puzzles.c's table, puzzles.json.
// A puzzle is a language: accept exactly `set` and reject the rest.
// Nothing is kept between visits: a reload starts at puzzle 1.
// web/build.shale rewrites the two fetched names to their hashed ones.

const STEPS = 6;
const INPUTS = [0, 1, 2, 3];
// run_progam's Status.
const NONE = 0, ACCEPTED = 1;
const LINES = ["an empty", "a one-line", "a two-line", "a three-line", "a four-line", "a five-line", "a six-line"];

const [wasm, table] = await Promise.all([
  fetch("nibble.d9274e0bd105b936.wasm").then((r) => r.arrayBuffer()).then((b) => WebAssembly.instantiate(b)),
  fetch("puzzles.1e622fa72a79c00b.json").then((r) => r.json()),
]).catch((e) => {
  const said = document.getElementById("loading");
  said.className = "err";
  said.textContent = `The machine didn't load: ${e.message}`;
  throw e;
});
const machine = wasm.instance.exports;
const { ops: OPS, puzzles: PUZZLES } = table;

// A program is its ops' codes; its code is base 4, op i digit i, as `assemble`.
const codeOf = (program) => program.reduce((sum, op, i) => sum + op * 4 ** i, 0);
const unpack = (word) => ({ ax: word & 3, halted: (word >> 2) & 1, status: (word >> 3) & 3 });
const setText = (set) => `{${set.join(", ")}}`;
// What the puzzle wants of input n, and what program `code` gave it.
const wantOf = (puzzle, n) => (puzzle.set.includes(n) ? "accept" : "reject");
const outcomeOf = (code, n) => (machine.status(n, code) === ACCEPTED ? "accept" : "reject");

// ── progress, for this visit only: the puzzles solved, by place ─────────
const solved = new Set();
const isOpen = (i) => i === 0 || solved.has(i - 1) || solved.has(i);
let current = 0;

// ── the page ─────────────────────────────────────────────────────────────
const el = (tag, attrs = {}, ...kids) => {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v; else if (k === "text") e.textContent = v; else e.setAttribute(k, v);
  }
  for (const k of kids) e.append(k);
  return e;
};

const nav = document.getElementById("puzzles");
const panel = document.getElementById("puzzle");
const legend = document.getElementById("ops");
for (const op of OPS) legend.append(el("dt", { text: op.name }), el("dd", { text: op.comment.replace(/^# /, "") }));

let program = [];

// A puzzle's first `given` lines are locked to its start's ops; its lines
// past `lines` (its shortest program's length, but one for grumpy, which all
// nada solves) are locked to nada; the lines between are the player's.
const isGiven = (p, line) => line < p.given;
const isLocked = (p, line) => isGiven(p, line) || line >= p.lines;
// The program a puzzle opens with, `start`: all nada but its given lines,
// and grumpy's `zero` on line 1.
const startOf = (p) => Array.from({ length: STEPS }, (_, k) => Math.floor(p.start / 4 ** k) % 4);

function drawNav() {
  nav.replaceChildren(...PUZZLES.map((p, i) => {
    const b = el("button", { type: "button", "data-puzzle": String(i), title: p.name, text: String(i + 1) });
    if (i === current) b.classList.add("current");
    if (solved.has(i)) b.classList.add("solved");
    b.disabled = !isOpen(i);
    b.addEventListener("click", () => show(i));
    return b;
  }));
}

// The intro shows on the first puzzle; past it, Help shows or hides it.
const intro = document.getElementById("intro");
const help = document.getElementById("help");
let helpOpen = false;
function drawIntro() {
  help.hidden = current === 0;
  intro.hidden = current !== 0 && !helpOpen;
  help.textContent = helpOpen ? "Hide help" : "Help";
  help.setAttribute("aria-expanded", String(!intro.hidden));
}
help.addEventListener("click", () => { helpOpen = !helpOpen; drawIntro(); });

// A puzzle opens at its start, a solved one too: it reopens as a puzzle.
function show(i) {
  current = i;
  drawIntro();
  program = startOf(PUZZLES[i]);
  drawNav();
  drawPuzzle();
}

function lockTitle(p, line, o) {
  if (isGiven(p, line)) return `Given: line ${line + 1} is ${OPS[program[line]].name}.`;
  return line >= p.lines ? "Locked to nada: this puzzle needs fewer lines." : o.comment;
}

function drawPuzzle() {
  const i = current;
  const p = PUZZLES[i];
  const slots = el("div", { class: "slots" });
  program.forEach((op, line) => {
    const locked = isLocked(p, line);
    const kind = isGiven(p, line) ? "slot locked given" : locked ? "slot locked" : "slot";
    const row = el("div", { class: kind, "data-line": String(line) }, el("span", { class: "num", text: String(line + 1) }));
    OPS.forEach((o, code) => {
      const b = el("button", { type: "button", class: o.name + (code === op ? " on" : ""), title: lockTitle(p, line, o), "data-slot": String(line), "data-op": o.name, text: o.name });
      b.disabled = locked;
      b.addEventListener("click", () => { program[line] = code; drawPuzzle(); });
      row.append(b);
    });
    slots.append(row);
  });
  const clear = el("button", { type: "button", id: "clear", text: "Clear" });
  const next = el("button", { type: "button", class: "primary", id: "next", text: "Next puzzle" });
  next.hidden = !(solved.has(i) && i + 1 < PUZZLES.length);
  const trace = el("div", { class: "trace", id: "trace" });
  const verdict = el("div", { class: "verdict", id: "verdict" });
  clear.addEventListener("click", () => { program = startOf(p); drawPuzzle(); });
  next.addEventListener("click", () => show(i + 1));
  const found = el("p", { class: "hint", id: "found" });
  // The verdict and the buttons sit above the program, so a solve shows
  // without scrolling; the trace, the longest part, goes last.
  panel.replaceChildren(
    el("h2", { id: "title", text: `Puzzle ${i + 1} of ${PUZZLES.length}: ${p.name}` }),
    el("p", { id: "goal", text: goalText(p) }),
    ...(p.lesson ? [el("p", { class: "lesson", id: "lesson", text: p.lesson })] : []),
    el("p", { class: "hint", id: "hint", text: hintText(p) }),
    verdict, found,
    el("div", { class: "actions" }, clear, next),
    slots,
    trace,
  );
  // No Run button: the program runs on every pick.
  runAll(trace, verdict, next);
}

function goalText(p) {
  const rejected = INPUTS.filter((n) => !p.set.includes(n));
  return p.set.length === 0 ? "Reject all inputs." : `Accept ${setText(p.set)}${rejected.length ? `; reject ${setText(rejected)}` : ""}.`;
}

// Lines a to b (from 1), as a hint says them.
const span = (a, b) => (a === b ? `line ${a}` : `lines ${a} to ${b}`);
const cap = (s) => s[0].toUpperCase() + s.slice(1);
const lockedText = (n) => (n === STEPS ? "" : `${cap(span(n + 1, STEPS))} ${n + 1 === STEPS ? "is" : "are"} locked to nada.`);
function hintText(p) {
  if (p.given === 0) return `This can be solved with ${LINES[p.lines]} Nibble program${p.lines === STEPS ? "" : `, so ${span(p.lines + 1, STEPS)} ${p.lines + 1 === STEPS ? "is" : "are"} locked to nada`}.`;
  const ops = startOf(p).slice(0, p.given).map((op) => OPS[op].name).join(", ");
  const given = `${cap(span(1, p.given))} ${p.given === 1 ? "is" : "are"} already fixed as ${ops}. Your job: fix ${span(p.given + 1, p.lines)}.`;
  const locked = lockedText(p.lines);
  return locked ? `${given} ${locked}` : given;
}

const foundText = (p) => p.count === 1 ? "You found the one program, of all 4,096, that does this." : `You found one of ${p.count.toLocaleString("en-US")} programs that do this.`;

// What a run ended as, in the result row: a run off the end says why it
// rejects.
const endText = (code, n) => (machine.status(n, code) === NONE ? "reject: ran off the end" : outcomeOf(code, n));

// The trace: a row a step, so it lines up with the program's lines, and a
// column an input, which fits a phone's width. A cell is AX after that
// step, or accept or reject where the run halted; the last two rows are how
// each run ended and what the puzzle wants. A wrong input's column is marked.
function runAll(trace, verdict, next) {
  const i = current;
  const p = PUZZLES[i];
  const code = codeOf(program);
  const outcome = INPUTS.map((n) => outcomeOf(code, n));
  const ok = INPUTS.map((n) => outcome[n] === wantOf(p, n));
  const wrongAt = ok.indexOf(false);
  const wrong = wrongAt < 0 ? null : INPUTS[wrongAt];
  const cell = (tag, n, attrs) => {
    const c = el(tag, { ...attrs, "data-input": String(n) });
    if (!ok[n]) c.classList.add("wrong");
    return c;
  };
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
  rows.push(el("tr", { class: "end", "data-row": "want" }, el("th", { class: "step", text: "want" }), ...INPUTS.map((n) => cell("td", n, { text: wantOf(p, n) }))));
  trace.replaceChildren(el("table", {}, el("thead", {}, head), el("tbody", {}, ...rows)));
  const found = document.getElementById("found");
  if (wrong === null) {
    solved.add(i);
    verdict.className = "verdict good";
    verdict.textContent = i + 1 < PUZZLES.length ? "Solved! The next puzzle is open." : "Solved! That was the last puzzle.";
    found.textContent = foundText(p);
    next.hidden = i + 1 >= PUZZLES.length;
    drawNav();
  } else {
    verdict.className = "verdict bad";
    const should = wantOf(p, wrong) === "accept" ? "be accepted" : "be rejected";
    verdict.textContent = `Input ${wrong} should ${should}, and your program ${outcome[wrong] === "accept" ? "accepted" : "rejected"} it.`;
  }
}

document.getElementById("loading")?.remove();
show(0);
