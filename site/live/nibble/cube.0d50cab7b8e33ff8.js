// cube.js: the rolling cube's playground. The 4 x 4 board and the cube are
// drawn in 3D on a canvas with its own perspective projection: tiles are
// boxes drawn far to near (the painter's order), and the cube, which is
// convex and always above the board, is drawn last with its back faces
// culled. A roll is animated as a quarter turn about the cube's bottom edge.
//
// The rules are the Roc port's roc/Cube.roc compiled to wasm
// (roc/CubeWasm.roc on web/platform/cube.roc): the page keeps the state as
// one number and asks `roll(state, r)` for each roll. The pars are the
// census's, cube_pars.bin, a byte a lit set (web/cube_data.c). Nothing is
// kept between visits. web/build.shale rewrites the wasm's and the table's
// names to their hashed ones.

const ROLLS = "NESW";
// CubeWasm.roc's state: the lit set in bits 0-15, the cell in 16-19, the
// painted face in 20-22; bit 24 is a roll off the board.
const OFF = 1 << 24;
const litOf = (w) => w & 0xffff;
const cellOf = (w) => (w >> 16) & 15;
const faceOf = (w) => (w >> 20) & 7;
const FACE_NAMES = ["up", "down", "north", "south", "east", "west"];
const cellName = (cell) => "abcd"[cell % 4] + String(Math.floor(cell / 4) + 1);

// The world: x east, y up, z south; tile (row r, column c) is centred at
// (c - 1.5, 0, r - 1.5), a1 the north-west corner.
const FACE_VECTORS = [[0, 1, 0], [0, -1, 0], [0, 0, -1], [0, 0, 1], [1, 0, 0], [-1, 0, 0]];
const ROLL_VECTORS = [[0, 0, -1], [1, 0, 0], [0, 0, 1], [-1, 0, 0]];

const SAMPLES = [
  { name: "ESWN, the 4-roll macro", program: "ESWN" },
  { name: "b2 alone (par 8)", program: "ESENSNWS" },
  { name: "the diagonal (par 18)", program: "ESSENNWWESESESNNWW" },
  { name: "every tile (par 47)", program: "EEESWNWSENWSWNESWESWESWNESENWNESESWNESWNEWNEWNE" },
];

const fetched = (url) => fetch(url).then((r) => {
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return r.arrayBuffer();
});

const [machine, pars] = await Promise.all([
  fetched("cube.26da3181289821de.wasm").then((b) => WebAssembly.instantiate(b)).then((w) => w.instance.exports),
  fetched("cube_pars.ae6c160fdee15462.bin").then((b) => {
    const bytes = new Uint8Array(b);
    if (bytes.length !== 65536) throw new Error(`cube_pars.bin has ${bytes.length} bytes, not 65,536`);
    return bytes;
  }),
]).catch((e) => {
  const said = document.getElementById("loading");
  said.className = "err";
  said.textContent = `The cube didn't load: ${e.message}`;
  throw e;
});
document.getElementById("loading").remove();

// ── the program and its run ──────────────────────────────────────────

const view = {
  program: [],      // roll codes
  frames: [0],      // the state before any roll, then after each
  offAt: -1,        // the roll that leaves the board, or -1
  at: 0,            // the frame shown
  anim: null,       // { from, roll, dir, start, ms }
  playing: false,
};

function runProgram() {
  view.frames = [0];
  view.offAt = -1;
  for (let i = 0; i < view.program.length; i++) {
    const next = machine.roll(view.frames[i], view.program[i]);
    if (next & OFF) { view.offAt = i; break; }
    view.frames.push(next);
  }
  view.at = Math.min(view.at, view.frames.length - 1);
}

const lastFrame = () => view.frames.length - 1;

// ── the 3D scene ─────────────────────────────────────────────────────

const canvas = document.getElementById("scene");
const ctx = canvas.getContext("2d");
const camera = { yaw: 0.32, pitch: 0.9, dist: 9 };
const FOCAL = 1 / Math.tan((38 * Math.PI) / 360);
const LIGHT = norm([0.45, 1, 0.65]);

function norm(v) { const l = Math.hypot(v[0], v[1], v[2]); return [v[0] / l, v[1] / l, v[2] / l]; }
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const sub3 = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];

// The camera's place and axes, orbiting the board's centre.
function eye() {
  const c = Math.cos(camera.pitch);
  const at = [camera.dist * c * Math.sin(camera.yaw), camera.dist * Math.sin(camera.pitch), camera.dist * c * Math.cos(camera.yaw)];
  const forward = norm(sub3([0, 0, 0], at));
  const right = norm(cross(forward, [0, 1, 0]));
  const up = cross(right, forward);
  return { at, forward, right, up };
}

// A projection fitted to the canvas: the board and a cube's height above it
// fill most of it, whichever way the camera turns.
function projector(width, height) {
  const e = eye();
  const raw = (p) => {
    const d = sub3(p, e.at);
    const z = dot(d, e.forward);
    return [(dot(d, e.right) / z) * FOCAL, (dot(d, e.up) / z) * FOCAL, z];
  };
  let lo = [Infinity, Infinity], hi = [-Infinity, -Infinity];
  for (const x of [-2.3, 2.3]) for (const y of [-0.3, 1.1]) for (const z of [-2.3, 2.3]) {
    const [u, v] = raw([x, y, z]);
    lo = [Math.min(lo[0], u), Math.min(lo[1], v)];
    hi = [Math.max(hi[0], u), Math.max(hi[1], v)];
  }
  const scale = 0.94 * Math.min(width / (hi[0] - lo[0]), height / (hi[1] - lo[1]));
  const mid = [(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2];
  return {
    eye: e,
    point: (p) => {
      const [u, v, z] = raw(p);
      return [width / 2 + (u - mid[0]) * scale, height / 2 - (v - mid[1]) * scale, z];
    },
  };
}

// The six faces of a box, each its outward normal and four corners.
function boxFaces(x0, x1, y0, y1, z0, z1) {
  return [
    { n: [0, 1, 0], pts: [[x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1]] },
    { n: [0, -1, 0], pts: [[x0, y0, z0], [x0, y0, z1], [x1, y0, z1], [x1, y0, z0]] },
    { n: [0, 0, -1], pts: [[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0]] },
    { n: [0, 0, 1], pts: [[x0, y0, z1], [x0, y1, z1], [x1, y1, z1], [x1, y0, z1]] },
    { n: [1, 0, 0], pts: [[x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0]] },
    { n: [-1, 0, 0], pts: [[x0, y0, z0], [x0, y1, z0], [x0, y1, z1], [x0, y0, z1]] },
  ];
}

const centre = (pts) => pts.reduce((s, p) => [s[0] + p[0] / pts.length, s[1] + p[1] / pts.length, s[2] + p[2] / pts.length], [0, 0, 0]);
const facing = (face, e) => dot(face.n, sub3(e.at, centre(face.pts))) > 0;

function shaded(rgb, n, ambient = 0.42) {
  const k = ambient + (1 - ambient) * Math.max(0, dot(n, LIGHT));
  return `rgb(${Math.round(rgb[0] * k)}, ${Math.round(rgb[1] * k)}, ${Math.round(rgb[2] * k)})`;
}

function fillFace(proj, pts, fill, stroke) {
  ctx.beginPath();
  pts.forEach((p, i) => {
    const [x, y] = proj.point(p);
    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  });
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();
  if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = 1; ctx.stroke(); }
}

const DARK_TILE = [58, 61, 70];
const LIT_TILE = [255, 179, 71];
const BASE = [38, 40, 46];
const CUBE = [236, 232, 223];
const PAINT = [58, 123, 255];

// Rotates `p` by `angle` about the pivot line through `pivot` along the
// roll's bottom edge: up turns toward the roll's direction `d`.
function tipped(p, pivot, d, angle, isVector) {
  const rel = isVector ? p : sub3(p, pivot);
  const u = rel[1], v = dot(rel, d);
  const w = [rel[0] - v * d[0], 0, rel[2] - v * d[2]];
  const c = Math.cos(angle), s = Math.sin(angle);
  const u2 = u * c - v * s, v2 = v * c + u * s;
  const out = [w[0] + v2 * d[0], u2, w[2] + v2 * d[2]];
  return isVector ? out : [out[0] + pivot[0], out[1] + pivot[1], out[2] + pivot[2]];
}

// The cube's faces for state `word`, tipped `angle` into roll `roll` (or
// standing when roll is -1).
function cubeFaces(word, roll, angle) {
  const cell = cellOf(word);
  const cx = (cell % 4) - 1.5, cz = Math.floor(cell / 4) - 1.5;
  const paint = FACE_VECTORS[faceOf(word)];
  const faces = boxFaces(cx - 0.5, cx + 0.5, 0, 1, cz - 0.5, cz + 0.5).map((f) => ({ ...f, painted: dot(f.n, paint) > 0.5 }));
  if (roll < 0 || angle === 0) return { faces, centre: [cx, 0.5, cz] };
  const d = ROLL_VECTORS[roll];
  const pivot = [cx + 0.5 * d[0], 0, cz + 0.5 * d[2]];
  return {
    faces: faces.map((f) => ({ n: tipped(f.n, pivot, d, angle, true), pts: f.pts.map((p) => tipped(p, pivot, d, angle, false)), painted: f.painted })),
    centre: tipped([cx, 0.5, cz], pivot, d, angle, false),
  };
}

function label(proj, p, text) {
  const [x, y] = proj.point(p);
  ctx.fillText(text, x, y);
}

function draw(now) {
  const dpr = window.devicePixelRatio || 1;
  const width = canvas.clientWidth || 720;
  const height = Math.round(width * 0.68);
  if (canvas.width !== Math.round(width * dpr) || canvas.height !== Math.round(height * dpr)) {
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
  }
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  const sky = ctx.createLinearGradient(0, 0, 0, height);
  sky.addColorStop(0, "#23262d");
  sky.addColorStop(1, "#15161a");
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, width, height);
  const proj = projector(width, height);
  const e = proj.eye;

  // What is shown: a frame, or a roll part done.
  let word = view.frames[view.at], roll = -1, angle = 0;
  if (view.anim) {
    const t = Math.min(1, (now - view.anim.start) / view.anim.ms);
    const eased = t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t);
    word = view.anim.from;
    roll = view.anim.roll;
    angle = (view.anim.dir > 0 ? eased : 1 - eased) * (Math.PI / 2);
  }
  const lit = litOf(word);

  // The base, then the tiles far to near, each with its back faces culled.
  for (const f of boxFaces(-2.15, 2.15, -0.32, -0.12, -2.15, 2.15)) {
    if (facing(f, e)) fillFace(proj, f.pts, shaded(BASE, f.n));
  }
  const tiles = [];
  for (let cell = 0; cell < 16; cell++) {
    const x = (cell % 4) - 1.5, z = Math.floor(cell / 4) - 1.5;
    tiles.push({ cell, x, z, far: Math.hypot(x - e.at[0], -0.06 - e.at[1], z - e.at[2]) });
  }
  tiles.sort((a, b) => b.far - a.far);
  for (const t of tiles) {
    const on = (lit >> t.cell) & 1;
    const rgb = on ? LIT_TILE : DARK_TILE;
    for (const f of boxFaces(t.x - 0.46, t.x + 0.46, -0.12, 0, t.z - 0.46, t.z + 0.46)) {
      if (!facing(f, e)) continue;
      if (on && f.n[1] > 0) {
        ctx.save();
        ctx.shadowColor = "rgba(255, 170, 60, 0.85)";
        ctx.shadowBlur = 22;
        fillFace(proj, f.pts, "rgb(255, 196, 110)");
        ctx.restore();
      } else {
        fillFace(proj, f.pts, shaded(rgb, f.n));
      }
    }
  }

  // The board's names: columns a to d along the south edge, rows 1 to 4
  // along the west, and north.
  ctx.fillStyle = "#9a9aa2";
  ctx.font = "13px system-ui, sans-serif";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  for (let c = 0; c < 4; c++) label(proj, [c - 1.5, -0.12, 2.45], "abcd"[c]);
  for (let r = 0; r < 4; r++) label(proj, [-2.45, -0.12, r - 1.5], String(r + 1));
  label(proj, [0, -0.12, -2.55], "north");

  // The cube's shadow, then the cube: convex and above the board, so its
  // front faces, in any order, are all it needs.
  const cube = cubeFaces(word, roll, angle);
  const lift = Math.max(0, cube.centre[1] - 0.5);
  const s = 0.5 + lift * 0.25;
  fillFace(proj, [[cube.centre[0] - s, 0.002, cube.centre[2] - s], [cube.centre[0] + s, 0.002, cube.centre[2] - s],
    [cube.centre[0] + s, 0.002, cube.centre[2] + s], [cube.centre[0] - s, 0.002, cube.centre[2] + s]], "rgba(0, 0, 0, 0.35)");
  for (const f of cube.faces) {
    if (!facing(f, e)) continue;
    fillFace(proj, f.pts, shaded(f.painted ? PAINT : CUBE, f.n, 0.5), "rgba(20, 20, 24, 0.55)");
  }

  canvas.dataset.frame = String(view.at);
  canvas.dataset.animating = view.anim ? "1" : "0";
}

let drawQueued = false;
function requestDraw() {
  if (drawQueued) return;
  drawQueued = true;
  requestAnimationFrame((now) => {
    drawQueued = false;
    if (view.anim && now - view.anim.start >= view.anim.ms) finishAnim();
    draw(now);
    if (view.anim) requestDraw();
  });
}

// ── moving through the run ───────────────────────────────────────────

const STEP_MS = 260;

function finishAnim() {
  const a = view.anim;
  if (!a) return;
  view.anim = null;
  view.at = a.target;
  showRun();
  if (view.playing) {
    if (view.at < lastFrame()) stepTo(view.at + 1);
    else { view.playing = false; showRun(); }
  }
}

// Animates from the shown frame to the one next to it.
function stepTo(target) {
  if (view.anim) { const keep = view.playing; view.playing = false; finishAnim(); view.playing = keep; }
  if (target < 0 || target > lastFrame() || target === view.at) return;
  const dir = target > view.at ? 1 : -1;
  const before = dir > 0 ? view.at : target;
  view.anim = { from: view.frames[before], roll: view.program[before], dir, target, start: performance.now(), ms: STEP_MS };
  showRun();
  requestDraw();
}

function stop() {
  view.playing = false;
  if (view.anim) finishAnim();
}

// ── the readout ──────────────────────────────────────────────────────

const input = document.getElementById("program");
const said = document.getElementById("said");
const rollsLine = document.getElementById("rolls");
const status = document.getElementById("status");
const map = document.getElementById("lit-map");
const lengthLine = document.getElementById("length");
const parLine = document.getElementById("par");
const playButton = document.getElementById("play");
const mapCells = Array.from({ length: 16 }, (_, cell) => {
  const d = document.createElement("div");
  d.title = cellName(cell);
  map.append(d);
  return d;
});

const programText = () => view.program.map((r) => ROLLS[r]).join("");

function showRun() {
  const shown = view.anim ? view.anim.target : view.at;
  rollsLine.replaceChildren(...view.program.map((r, i) => {
    const span = document.createElement("span");
    span.textContent = ROLLS[r];
    span.className = i === view.offAt ? "off" : i < shown ? (i === shown - 1 ? "now" : "done") : "todo";
    return span;
  }));
  const word = view.frames[shown];
  const where = `the cube on ${cellName(cellOf(word))}, the paint ${FACE_NAMES[faceOf(word)]}`;
  if (view.offAt >= 0 && shown === lastFrame()) {
    status.className = "err";
    status.textContent = `Roll ${view.offAt + 1} (${ROLLS[view.program[view.offAt]]}) would leave the board from ${cellName(cellOf(word))}, so the program stops there.`;
  } else {
    status.className = "";
    status.textContent = shown === 0 ? `The start: ${where}.` : `After roll ${shown} of ${view.program.length}: ${where}.`;
  }
  const n = view.program.length;
  lengthLine.textContent = `${n} roll${n === 1 ? "" : "s"}`;
  if (view.offAt >= 0) {
    mapCells.forEach((d) => d.classList.remove("lit"));
    parLine.textContent = "No par: the program rolls off the board.";
  } else {
    const lit = litOf(view.frames[lastFrame()]);
    mapCells.forEach((d, cell) => d.classList.toggle("lit", ((lit >> cell) & 1) === 1));
    parLine.textContent = `par ${pars[lit]}; yours is ${n}`;
  }
  parLine.dataset.lit = view.offAt >= 0 ? "" : String(litOf(view.frames[lastFrame()]));
  playButton.textContent = view.playing ? "Pause" : "Play";
  document.getElementById("back").disabled = shown === 0;
  document.getElementById("reset").disabled = shown === 0 && !view.anim;
  document.getElementById("forward").disabled = shown >= lastFrame();
  document.getElementById("clear").disabled = n === 0;
}

// The program from the text box: N, E, S and W in either case, spaces
// skipped; anything else is refused, and the run stays as it was.
function fromText() {
  const text = input.value.toUpperCase();
  const bad = text.replace(/[NESW\s]/g, "");
  if (bad.length > 0) {
    input.classList.add("bad");
    said.className = "err";
    said.textContent = `Only N, E, S, W and spaces: "${bad[0]}" is not a roll.`;
    return;
  }
  input.classList.remove("bad");
  said.textContent = "";
  stop();
  view.program = Array.from(text.replace(/\s/g, ""), (ch) => ROLLS.indexOf(ch));
  runProgram();
  view.at = lastFrame();
  showRun();
  requestDraw();
}

function setProgram(text, at) {
  stop();
  input.value = text;
  input.classList.remove("bad");
  said.textContent = "";
  view.program = Array.from(text, (ch) => ROLLS.indexOf(ch));
  runProgram();
  view.at = at === "end" ? lastFrame() : 0;
  showRun();
  requestDraw();
}

// A roll from a button or a key: the program is cut at the frame shown and
// the roll added there, unless it would leave the board.
function rollNow(code) {
  stop();
  const word = view.frames[view.at];
  if (machine.roll(word, code) & OFF) {
    said.className = "err";
    said.textContent = `${ROLLS[code]} from ${cellName(cellOf(word))} would leave the board.`;
    return;
  }
  said.textContent = "";
  view.program = view.program.slice(0, view.at).concat([code]);
  input.value = programText();
  input.classList.remove("bad");
  runProgram();
  stepTo(view.at + 1);
}

input.addEventListener("input", fromText);
for (const b of document.querySelectorAll("button[data-roll]")) {
  b.addEventListener("click", () => rollNow(ROLLS.indexOf(b.dataset.roll)));
}
document.getElementById("reset").addEventListener("click", () => { stop(); view.at = 0; showRun(); requestDraw(); });
document.getElementById("back").addEventListener("click", () => { view.playing = false; stepTo((view.anim ? view.anim.target : view.at) - 1); });
document.getElementById("forward").addEventListener("click", () => { view.playing = false; stepTo((view.anim ? view.anim.target : view.at) + 1); });
document.getElementById("clear").addEventListener("click", () => setProgram("", 0));
playButton.addEventListener("click", () => {
  if (view.playing) { view.playing = false; showRun(); return; }
  if (lastFrame() === 0) return;
  if (view.at >= lastFrame()) { stop(); view.at = 0; }
  view.playing = true;
  stepTo(view.at + 1);
});

const KEYS = { ArrowUp: 0, ArrowRight: 1, ArrowDown: 2, ArrowLeft: 3 };
document.addEventListener("keydown", (ev) => {
  if (ev.target === input || ev.altKey || ev.ctrlKey || ev.metaKey) return;
  if (!(ev.key in KEYS)) return;
  ev.preventDefault();
  rollNow(KEYS[ev.key]);
});

const samples = document.getElementById("samples");
for (const s of SAMPLES) {
  const b = document.createElement("button");
  b.type = "button";
  b.textContent = s.name;
  b.dataset.program = s.program;
  b.addEventListener("click", () => {
    setProgram(s.program, 0);
    view.playing = true;
    stepTo(1);
  });
  samples.append(b);
}

// Dragging turns the camera about the board; a double click puts it back.
let drag = null;
canvas.addEventListener("pointerdown", (ev) => {
  drag = { x: ev.clientX, y: ev.clientY, yaw: camera.yaw, pitch: camera.pitch };
  canvas.setPointerCapture(ev.pointerId);
  canvas.classList.add("dragging");
});
canvas.addEventListener("pointermove", (ev) => {
  if (!drag) return;
  camera.yaw = drag.yaw - (ev.clientX - drag.x) * 0.008;
  camera.pitch = Math.min(1.45, Math.max(0.3, drag.pitch + (ev.clientY - drag.y) * 0.006));
  requestDraw();
});
const endDrag = () => { drag = null; canvas.classList.remove("dragging"); };
canvas.addEventListener("pointerup", endDrag);
canvas.addEventListener("pointercancel", endDrag);
canvas.addEventListener("dblclick", () => { camera.yaw = 0.32; camera.pitch = 0.9; requestDraw(); });
window.addEventListener("resize", requestDraw);

showRun();
requestDraw();
