// nibble.js: the Nibble puzzle page. The machine, the table (the puzzles,
// their counts and shortest lengths, and the opcodes' comments) and the
// parts the sandbox draws too are machine.js's.
// A puzzle is a language: accept exactly `set` and reject the rest.
// Nothing is kept between visits: a reload starts at puzzle 1.
// web/build.shale rewrites machine.js's name to its hashed one.

import { STEPS, INPUTS, OPS, PUZZLES, codeOf, setText, outcomeOf, el, drawOps, opTip, machineCode, CODE_EXPLAIN, traceTable } from "./machine.9c38f3ca638d7d58.js";

const LINES = ["an empty", "a one-line", "a two-line", "a three-line", "a four-line", "a five-line", "a six-line"];

// What the puzzle wants of input n.
const wantOf = (puzzle, n) => (puzzle.set.includes(n) ? "accept" : "reject");

// ── progress, for this visit only: the puzzles solved, by place ─────────
const solved = new Set();
// Every puzzle is open: a player may jump ahead to any of them.
const isOpen = () => true;
let current = 0;

// ── the page ─────────────────────────────────────────────────────────────
const nav = document.getElementById("puzzles");
const panel = document.getElementById("puzzle");
drawOps(document.getElementById("ops"));

let program = [];
// Whether the player brought the buttons back after a solve, on this puzzle.
let reopened = false;
// Whether the machine code's explanation is open; it stays as the player left it.
let codeHelpOpen = false;

// A puzzle's `fixed` lines (a bitmask, line k's bit 1 << k, from 0) are
// locked to its start's ops; its lines past `lines` (its shortest program's
// length, but one for grumpy, which all nada solves) are locked to nada; the
// rest are the player's.
const isFixed = (p, line) => ((p.fixed >> line) & 1) === 1;
const isLocked = (p, line) => isFixed(p, line) || line >= p.lines;
// The program a puzzle opens with, `start`: all nada but its fixed lines,
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
  reopened = false;
  drawIntro();
  program = startOf(PUZZLES[i]);
  drawNav();
  drawPuzzle();
}

function lockTitle(p, line, o) {
  if (isFixed(p, line)) return `Fixed: line ${line + 1} is ${OPS[program[line]].name}.`;
  return line >= p.lines ? "Locked to nada: this puzzle needs fewer lines." : opTip(OPS.indexOf(o));
}

function drawPuzzle() {
  const i = current;
  const p = PUZZLES[i];
  const slots = el("div", { class: "slots", id: "slots" });
  program.forEach((op, line) => {
    const locked = isLocked(p, line);
    const kind = isFixed(p, line) ? "slot locked given" : locked ? "slot locked" : "slot";
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
  // Once solved, the buttons fold away so the trace, the run's story, shows;
  // "Change the program" brings them back.
  const edit = el("button", { type: "button", id: "edit", text: "Change the program" });
  edit.hidden = true;
  clear.addEventListener("click", () => { program = startOf(p); drawPuzzle(); });
  next.addEventListener("click", () => show(i + 1));
  edit.addEventListener("click", () => { reopened = true; drawPuzzle(); });
  // The program as machine code: twelve bits, two a line, beside a "?".
  const codeHelp = el("button", { type: "button", class: "code-help", id: "code-help", title: "What are these bits?", "aria-expanded": String(codeHelpOpen), text: "?" });
  const codeExplain = el("p", { class: "hint", id: "code-explain", text: CODE_EXPLAIN });
  codeExplain.hidden = !codeHelpOpen;
  codeHelp.addEventListener("click", () => { codeHelpOpen = !codeHelpOpen; drawPuzzle(); });
  const found = el("p", { class: "hint", id: "found" });
  // The verdict and the buttons sit above the program, so a solve shows
  // without scrolling; the trace, the longest part, goes last.
  panel.replaceChildren(
    el("h2", { id: "title", text: `Puzzle ${i + 1} of ${PUZZLES.length}: ${p.name}` }),
    el("p", { id: "goal", text: goalText(p) }),
    ...(p.lesson ? [el("p", { class: "lesson", id: "lesson", text: p.lesson })] : []),
    el("p", { class: "hint", id: "hint", text: hintText(p) }),
    verdict, found,
    el("div", { class: "actions" }, clear, edit, next,
      el("span", { class: "machine" }, el("code", { id: "machine-code" }), codeHelp)),
    codeExplain,
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
// Lines (from 0) as a hint says them: "line 4", "lines 1 to 3", or, with a
// gap, each one: "lines 1, 3 and 4".
function linesText(ks) {
  if (ks[ks.length - 1] - ks[0] === ks.length - 1) return span(ks[0] + 1, ks[ks.length - 1] + 1);
  const names = ks.map((k) => String(k + 1));
  return `lines ${names.slice(0, -1).join(", ")} and ${names[names.length - 1]}`;
}
// The fixed lines, each with its op: "Line 2 is already fixed as mod2, and
// line 5 as zero."
function fixedText(p, fixed) {
  const each = fixed.map((k) => `line ${k + 1} as ${OPS[startOf(p)[k]].name}`);
  const first = `Line ${fixed[0] + 1} is already fixed as ${OPS[startOf(p)[fixed[0]]].name}`;
  if (each.length === 1) return `${first}.`;
  return `${first}, ${each.slice(1, -1).map((s) => `${s}, `).join("")}and ${each[each.length - 1]}.`;
}
function hintText(p) {
  const fixed = Array.from({ length: p.lines }, (_, k) => k).filter((k) => isFixed(p, k));
  if (fixed.length === 0) return `This can be solved with ${LINES[p.lines]} Nibble program${p.lines === STEPS ? "" : `, so ${span(p.lines + 1, STEPS)} ${p.lines + 1 === STEPS ? "is" : "are"} locked to nada`}.`;
  const open = Array.from({ length: p.lines }, (_, k) => k).filter((k) => !isFixed(p, k));
  const parts = [fixedText(p, fixed), `Your job: fix ${linesText(open)}.`];
  // Past the lessons, the hint first says how short a program can be.
  if (!p.lesson) parts.unshift(`This can be solved with ${LINES[p.lines]} Nibble program.`);
  const locked = lockedText(p.lines);
  if (locked) parts.push(locked);
  return parts.join(" ");
}

const foundText = (p) => p.count === 1 ? "You found the one program, of all 4,096, that does this." : `You found one of ${p.count.toLocaleString("en-US")} programs that do this.`;

// The trace (machine.js's traceTable), then what the puzzle wants and
// whether each input came out right. A wrong input's column is marked.
function runAll(trace, verdict, next) {
  const i = current;
  const p = PUZZLES[i];
  const code = codeOf(program);
  document.getElementById("machine-code").textContent = machineCode(program);
  const outcome = INPUTS.map((n) => outcomeOf(code, n));
  const ok = INPUTS.map((n) => outcome[n] === wantOf(p, n));
  const wrongAt = ok.indexOf(false);
  const wrong = wrongAt < 0 ? null : INPUTS[wrongAt];
  const cell = (tag, n, attrs) => {
    const c = el(tag, { ...attrs, "data-input": String(n) });
    if (!ok[n]) c.classList.add("wrong");
    return c;
  };
  trace.replaceChildren(traceTable(program, cell, [
    el("tr", { class: "end", "data-row": "want" }, el("th", { class: "step", text: "want" }), ...INPUTS.map((n) => cell("td", n, { text: wantOf(p, n) }))),
    el("tr", { class: "end", "data-row": "outcome" }, el("th", { class: "step", text: "outcome" }), ...INPUTS.map((n) => cell("td", n, { text: ok[n] ? "Correct! 🎉" : "WRONG! ❌" }))),
  ]));
  const found = document.getElementById("found");
  if (wrong === null) {
    solved.add(i);
    verdict.className = "verdict good";
    verdict.textContent = i + 1 < PUZZLES.length ? "Solved! The next puzzle is open." : "Solved! That was the last puzzle.";
    found.textContent = foundText(p);
    next.hidden = i + 1 >= PUZZLES.length;
    if (!reopened) {
      document.getElementById("slots").hidden = true;
      document.getElementById("clear").hidden = true;
      document.getElementById("edit").hidden = false;
    }
    drawNav();
  } else {
    verdict.className = "verdict bad";
    verdict.textContent = wrongText(INPUTS.filter((n) => !ok[n] && outcome[n] === "accept"), INPUTS.filter((n) => !ok[n] && outcome[n] !== "accept"));
  }
}

// Every way the program is wrong: "Your program falsely accepts 0. It
// falsely rejects 2 and 3."
const listed = (ns) => (ns.length === 1 ? String(ns[0]) : `${ns.slice(0, -1).join(", ")} and ${ns[ns.length - 1]}`);
function wrongText(accepted, rejected) {
  const parts = [];
  if (accepted.length) parts.push(`falsely accepts ${listed(accepted)}.`);
  if (rejected.length) parts.push(`falsely rejects ${listed(rejected)}.`);
  return `Your program ${parts[0]}${parts.length > 1 ? ` It ${parts[1]}` : ""}`;
}

document.getElementById("loading")?.remove();
show(0);
