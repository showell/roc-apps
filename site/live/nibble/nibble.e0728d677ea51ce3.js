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
  fetch("puzzles.89d9bf622894fdcf.json").then((r) => r.json()),
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
function loadProgress() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORE) ?? "null");
    if (saved && typeof saved.solved === "object") return { solved: saved.solved, current: Number(saved.current) || 0, drafts: saved.drafts ?? {} };
  } catch { /* no storage, or none saved: start fresh */ }
  return { solved: {}, current: 0, drafts: {} };
}
function saveProgress() {
  try { localStorage.setItem(STORE, JSON.stringify(progress)); } catch { /* storage refused: progress lasts this visit */ }
}
const progress = loadProgress();
const isSolved = (i) => progress.solved[PUZZLES[i].code] !== undefined;
const isOpen = (i) => i === 0 || isSolved(i - 1);
if (!isOpen(progress.current) || progress.current >= PUZZLES.length) progress.current = 0;

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

function draftOf(i) {
  const code = PUZZLES[i].code;
  const saved = progress.drafts[code] ?? progress.solved[code];
  return Array.isArray(saved) && saved.length === STEPS ? saved.slice() : new Array(STEPS).fill(0);
}

function drawNav() {
  nav.replaceChildren(...PUZZLES.map((p, i) => {
    const b = el("button", { type: "button", "data-puzzle": String(i), title: p.name, text: String(i + 1) });
    if (i === progress.current) b.classList.add("current");
    if (isSolved(i)) b.classList.add("solved");
    b.disabled = !isOpen(i);
    b.addEventListener("click", () => show(i));
    return b;
  }));
}

function show(i) {
  progress.current = i;
  saveProgress();
  program = draftOf(i);
  drawNav();
  drawPuzzle();
}

function drawPuzzle() {
  const i = progress.current;
  const p = PUZZLES[i];
  const rejected = INPUTS.filter((n) => !accepts(p, n));
  const goal = p.set.length === 0 ? "Reject every input." : `Accept ${setText(p.set)}${rejected.length ? `; reject ${setText(rejected)}` : ""}.`;
  const slots = el("div", { class: "slots" });
  program.forEach((op, line) => {
    const row = el("div", { class: "slot" }, el("span", { class: "num", text: String(line + 1) }));
    OPS.forEach((o, code) => {
      const b = el("button", { type: "button", class: o.name + (code === op ? " on" : ""), title: o.comment, "data-slot": String(line), "data-op": o.name, text: o.name });
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
  const run = el("button", { type: "button", class: "primary", id: "run", text: "Run" });
  const clear = el("button", { type: "button", id: "clear", text: "Clear" });
  const next = el("button", { type: "button", id: "next", text: "Next puzzle" });
  next.hidden = !(isSolved(i) && i + 1 < PUZZLES.length);
  const trace = el("div", { class: "trace", id: "trace" });
  const verdict = el("div", { class: "verdict", id: "verdict" });
  run.addEventListener("click", () => runAll(trace, verdict, next));
  clear.addEventListener("click", () => { program = new Array(STEPS).fill(0); delete progress.drafts[p.code]; saveProgress(); drawPuzzle(); });
  next.addEventListener("click", () => show(i + 1));
  const found = el("p", { class: "hint", id: "found" });
  if (isSolved(i)) found.textContent = foundText(p);
  panel.replaceChildren(
    el("h2", { id: "title", text: `Puzzle ${i + 1} of ${PUZZLES.length}: ${p.name}` }),
    el("p", { id: "goal", text: goal }),
    el("p", { class: "hint", id: "hint", text: `This can be solved with ${LINES[p.shortest]} Nibble program${p.shortest === 0 ? " (all nada)" : ""}.` }),
    slots,
    el("div", { class: "actions" }, run, clear, next),
    trace, verdict, found,
  );
}

const foundText = (p) => p.count === 1 ? "You found the one program, of all 4,096, that does this." : `You found one of ${p.count.toLocaleString("en-US")} programs that do this.`;

// What a run ended as, in words.
const endText = (s) => s === ACCEPTED ? "accepted" : s === REJECTED ? "rejected" : "rejected (ran off the end)";

function runAll(trace, verdict, next) {
  const i = progress.current;
  const p = PUZZLES[i];
  const code = codeOf(program);
  const head = el("tr", {}, el("th", { text: "input" }), ...program.map((op, k) => el("th", { class: "mono", text: `${k + 1} ${OPS[op].name}` })), el("th", { text: "result" }), el("th", { text: "want" }));
  const rows = [];
  let wrong = null;
  for (const n of INPUTS) {
    const cells = [el("td", { class: "mono", text: String(n) })];
    let haltedAt = -1;
    for (let k = 1; k <= STEPS; k++) {
      const m = unpack(machine.after(n, code, k));
      if (m.halted && haltedAt < 0) { haltedAt = k; cells.push(el("td", { class: "mono", text: m.status === ACCEPTED ? "accept" : "reject" })); }
      else if (m.halted) cells.push(el("td", { class: "halt", text: "" }));
      else cells.push(el("td", { class: "mono", text: `AX=${m.ax}` }));
    }
    const status = machine.status(n, code);
    const ok = (status === ACCEPTED) === accepts(p, n);
    if (!ok && wrong === null) wrong = { n, status };
    const row = el("tr", { "data-input": String(n) }, ...cells, el("td", { text: endText(status) }), el("td", { text: accepts(p, n) ? "accept" : "reject" }));
    if (!ok) row.classList.add("wrong");
    rows.push(row);
  }
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
show(progress.current);
