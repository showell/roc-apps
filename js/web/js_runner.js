// js_runner -- the page's door onto the JavaScript subset's interpreter,
// js.wasm (the Roc in js/roc on the host in js/wasm). A program runs once,
// `start(src, onLine)`, then a frame at a time, `frame(t, onLine)`, while the
// last call ended `frame`. Each frame is a tick of the program's clock: the
// timers due and its `frame(t)` run then. `click(x, y)` queues a click for
// the program's `onClick` handler, which runs in the next frame.
//
// **EACH EFFECT ARRIVES WHILE THE PROGRAM RUNS.** The wasm calls the import
// `js_emit` with each effect's line (Canvas.line_of in js/roc/Canvas.roc) at
// the moment the program makes it, and this hands it to `onLine` before the
// program goes on; the pointer and the keys are asked of `input` when the
// program asks: `input.pointer(axis)` (0 for x, 1 for y) and
// `input.key(name)`, which the page sets. Each call's last line says how it ended (js/roc/JsApp.roc),
// and the call answers it: { ending, why }, the ending one of "frame",
// "done", "faulted", "thrown" (a throw nothing caught, `why` the line js-vm
// prints for it), "refused" or "crashed".
//
// **IT KEEPS A TIMELINE OF THE LAST RUN'S MEMORY** (`memory`). The wasm
// hands it a line `memory collected <cells> <live>` after each collection and
// `memory cells <cells>` at the end of each call that runs the program
// (JsApp.roc); neither reaches `onLine`. Each becomes a point: its time since
// `start`, the heap's cells (its list's length, the freed cells included),
// the cells a collection found live, and the wasm memory's real size in
// bytes. Past `MOST_POINTS` the points are thinned, every two made one, so a
// run that goes on for good keeps a bounded timeline of all of itself.
//
// The page and page_check.mjs both use it, so the check drives the very
// code the page runs.

const MOST_POINTS = 1200;

// A point and the one after it as one: the later's place, the collections
// of both, and the live count of the last collection between them.
function merged(a, b) {
  return { ...b, collections: a.collections + b.collections, live: b.live ?? a.live };
}

function thinned(points) {
  const kept = [points[0]];
  for (let i = 1; i < points.length; i += 2) kept.push(i + 1 < points.length ? merged(points[i], points[i + 1]) : points[i]);
  return kept;
}

export async function loadRunner(wasmBytes) {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const input = { pointer: () => 200, key: () => false };
  let x = null;
  let onLine = () => {};
  let ended = null;
  const memory = { points: [], started: 0 };
  const now = () => globalThis.performance.now();
  function sampled(cells, live) {
    const point = { ms: now() - memory.started, cells, live, collections: live === null ? 0 : 1, bytes: x.memory.buffer.byteLength };
    memory.points.push(point);
    if (memory.points.length > MOST_POINTS) memory.points = thinned(memory.points);
  }
  const text = (p, n) => decoder.decode(new Uint8Array(x.memory.buffer, p, n));
  const env = {
    js_emit(p, n) {
      const line = text(p, n);
      if (line.startsWith("end ")) ended = line;
      else if (line.startsWith("memory ")) {
        const [, kind, cells, live] = line.split(" ");
        sampled(Number(cells), kind === "collected" ? Number(live) : null);
      } else onLine(line);
    },
    js_pointer: (axis) => input.pointer(axis),
    js_key: (p, n) => (input.key(text(p, n)) ? 0 : 1),
  };
  const { instance } = await WebAssembly.instantiate(wasmBytes, { env });
  x = instance.exports;

  function call(sink, go) {
    onLine = sink;
    ended = null;
    try {
      go();
    } catch (e) {
      const said = decoder.decode(new Uint8Array(x.memory.buffer, x.crashPtr(), x.crashLen()));
      return { ending: "crashed", why: `the interpreter crashed: ${said || e.message}` };
    } finally {
      onLine = () => {};
    }
    const m = /^end (\w+)(?: (.*))?$/s.exec(ended ?? "");
    if (!m) return { ending: "crashed", why: `the interpreter ended a call with \`${ended}\`` };
    return { ending: m[1], why: m[2] ?? "" };
  }

  return {
    input,
    memory,
    start(src, sink) {
      memory.points = [];
      memory.started = now();
      memory.points.push({ ms: 0, cells: null, live: null, collections: 0, bytes: x.memory.buffer.byteLength });
      const bytes = encoder.encode(src);
      const at = x.sourcePtr(bytes.length);
      new Uint8Array(x.memory.buffer, at, bytes.length).set(bytes);
      return call(sink, () => x.start());
    },
    frame(t, sink) {
      return call(sink, () => x.frame(t));
    },
    click(px, py) {
      x.click(px, py);
    },
  };
}

// The words of a `log` or `text` line, its `\n` and `\\` read back.
export function unescaped(words) {
  return words.replace(/\\(n|\\)/g, (_, c) => (c === "n" ? "\n" : "\\"));
}

// What console.log printed, from a run's lines, as js-vm prints it; a run
// that stopped ends with its `js: <why>` line, or a throw nothing caught
// with its `Uncaught ...` line, as js-vm's does.
export function transcriptOf(lines, result) {
  let out = "";
  for (const line of lines) if (line.startsWith("log ")) out += unescaped(line.slice(4)) + "\n";
  if (result.ending === "faulted" || result.ending === "refused") out += `js: ${result.why}\n`;
  if (result.ending === "thrown") out += `${result.why}\n`;
  return out;
}
