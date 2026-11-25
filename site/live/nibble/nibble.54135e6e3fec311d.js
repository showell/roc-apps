// nibble.js: the Nibble puzzle page. The machine is src/vm.c compiled to
// wasm (web/nibble.c); the puzzles, their counts and shortest lengths, and
// the opcodes' comments come from web/puzzles.c's table, puzzles.json.
// web/build.shale rewrites the two fetched names to their hashed ones.

const STEPS = 6;
const INPUTS = [0, 1, 2, 3];
// run_progam's Status.
const NONE = 0, ACCEPTED = 1, REJECTED = 2;
const STORE = "nibble-progress-v1";
const LINES = ["an empty", "a one-line", "a two-line", "a three-line", "a four-line", "a five-line", "a six-line"];

const [wasm, table] = await Promise.all([
  fetch("nibble.d9274e0bd105b936.wasm").then((r) => r.arrayBuffer()).then((b) => WebAssembly.instantiate(b)),
  fetch("puzzles.fed4c110692b5a0d.json").then((r) => r.json()),
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
const accepts = (puzzle, n) => puzzle.set.includes(n);

// ── progress: which puzzles are solved, and with what; per viewer ────────
// Everything is kept by language code, never by place in the order, so a
// new order keeps each puzzle's progress: `at` is the code of the puzzle on
// show (an older save's `current`, a place, is dropped).
function loadProgress() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORE) ?? "null");
    if (saved && typeof saved.solved === "object") return { solved: saved.solved, at: Number.isInteger(saved.at) ? saved.at : null, drafts: saved.drafts ?? {} };
  } catch { /* no storage, or none saved: start fresh */ }
  return { solved: {}, at: null, drafts: {} };
}
function saveProgress() {
  try { localStorage.setItem(STORE, JSON.stringify(progress)); } catch { /* storage refused: progress lasts this visit */ }
}
const progress = loadProgress();
const isSolved = (i) => progress.solved[PUZZLES[i].code] !== undefined;
// A puzzle solved under an older order stays open.
const isOpen = (i) => i === 0 || isSolved(i - 1) || isSolved(i);
let current = PUZZLES.findIndex((p) => p.code === progress.at);
if (current < 0 || !isOpen(current)) current = 0;

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

// A puzzle's lines past `lines` (its shortest program's length, but one
// for the nada lesson) are locked to nada.
const isLocked = (p, line) => line >= p.lines;
// The program a puzzle opens with, `start`: all nada, but `zero` on the
// nada lesson's one line, since all nada solves it.
const startOf = (p) => Array.from({ length: STEPS }, (_, k) => Math.floor(p.start / 4 ** k) % 4);

function draftOf(i) {
  const p = PUZZLES[i];
  const saved = progress.drafts[p.code] ?? progress.solved[p.code];
  const draft = Array.isArray(saved) && saved.length === STEPS ? saved.slice() : startOf(p);
  return draft.map((op, line) => (isLocked(p, line) ? 0 : op));
}

function drawNav() {
  nav.replaceChildren(...PUZZLES.map((p, i) => {
    const b = el("button", { type: "button", "data-puzzle": String(i), title: p.name, text: String(i + 1) });
    if (i === current) b.classList.add("current");
    if (isSolved(i)) b.classList.add("solved");
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

function show(i) {
  current = i;
  drawIntro();
  progress.at = PUZZLES[i].code;
  saveProgress();
  program = draftOf(i);
  drawNav();
  drawPuzzle();
}

function drawPuzzle() {
  const i = current;
  const p = PUZZLES[i];
  const rejected = INPUTS.filter((n) => !accepts(p, n));
  const goal = p.set.length === 0 ? "Reject every input." : `Accept ${setText(p.set)}${rejected.length ? `; reject ${setText(rejected)}` : ""}.`;
  const slots = el("div", { class: "slots" });
  program.forEach((op, line) => {
    const locked = isLocked(p, line);
    const row = el("div", { class: locked ? "slot locked" : "slot", "data-line": String(line) }, el("span", { class: "num", text: String(line + 1) }));
    OPS.forEach((o, code) => {
      const b = el("button", { type: "button", class: o.name + (code === op ? " on" : ""), title: locked ? "Locked to nada: this puzzle needs fewer lines." : o.comment, "data-slot": String(line), "data-op": o.name, text: o.name });
      b.disabled = locked;
      b.addEventListener("click", () => {
        program[line] = code;
        progress.drafts[p.code] = program.slice();
        saveProgress();
        drawPuzzle();
      });
      row.append(b);
    });
    slots.append(row);
  });
  const clear = el("button", { type: "button", id: "clear", text: "Clear" });
  const next = el("button", { type: "button", class: "primary", id: "next", text: "Next puzzle" });
  next.hidden = !(isSolved(i) && i + 1 < PUZZLES.length);
  const trace = el("div", { class: "trace", id: "trace" });
  const verdict = el("div", { class: "verdict", id: "verdict" });
  clear.addEventListener("click", () => { program = startOf(p); delete progress.drafts[p.code]; saveProgress(); drawPuzzle(); });
  next.addEventListener("click", () => show(i + 1));
  const found = el("p", { class: "hint", id: "found" });
  if (isSolved(i)) found.textContent = foundText(p);
  // The verdict and the buttons sit above the program, so a solve shows
  // without scrolling; the trace, the longest part, goes last.
  panel.replaceChildren(
    el("h2", { id: "title", text: `Puzzle ${i + 1} of ${PUZZLES.length}: ${p.name}` }),
    el("p", { id: "goal", text: goal }),
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

const hintText = (p) => `This can be solved with ${LINES[p.lines]} Nibble program${lockedText(p.lines)}.`;
const lockedText = (n) => n === STEPS ? "" : n === STEPS - 1 ? `, so line ${STEPS} is locked to nada` : `, so lines ${n + 1} to ${STEPS} are locked to nada`;

const foundText = (p) => p.count === 1 ? "You found the one program, of all 4,096, that does this." : `You found one of ${p.count.toLocaleString("en-US")} programs that do this.`;

// What a run ended as, in words.
const endText = (s) => s === ACCEPTED ? "accept" : s === REJECTED ? "reject" : "reject: ran off the end";

// The trace: a row a step, so it lines up with the program's lines, and a
// column an input, which fits a phone's width. A cell is AX after that
// step, or accept or reject where the run halted; the last two rows are how
// each run ended and what the puzzle wants. A wrong input's column is marked.
function runAll(trace, verdict, next) {
  const i = current;
  const p = PUZZLES[i];
  const code = codeOf(program);
  const status = INPUTS.map((n) => machine.status(n, code));
  const ok = INPUTS.map((n) => (status[n] === ACCEPTED) === accepts(p, n));
  const wrongAt = ok.indexOf(false);
  const wrong = wrongAt < 0 ? null : { n: INPUTS[wrongAt], status: status[wrongAt] };
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
  rows.push(el("tr", { class: "end", "data-row": "result" }, el("th", { class: "step", text: "result" }), ...INPUTS.map((n) => cell("td", n, { text: endText(status[n]) }))));
  rows.push(el("tr", { class: "end", "data-row": "want" }, el("th", { class: "step", text: "want" }), ...INPUTS.map((n) => cell("td", n, { text: accepts(p, n) ? "accept" : "reject" }))));
  trace.replaceChildren(el("table", {}, el("thead", {}, head), el("tbody", {}, ...rows)));
  const found = document.getElementById("found");
  if (wrong === null) {
    progress.solved[p.code] = program.slice();
    saveProgress();
    verdict.className = "verdict good";
    verdict.textContent = i + 1 < PUZZLES.length ? "Solved! The next puzzle is open." : "Solved! That was the last puzzle.";
    found.textContent = foundText(p);
    next.hidden = i + 1 >= PUZZLES.length;
    drawNav();
  } else {
    verdict.className = "verdict bad";
    const should = accepts(p, wrong.n) ? "accepted" : "rejected";
    verdict.textContent = `Input ${wrong.n} should be ${should}, and your program ${wrong.status === ACCEPTED ? "accepted" : "rejected"} it.`;
  }
}

document.getElementById("loading")?.remove();
show(current);
