// js_runner -- the page's door onto the JavaScript subset's interpreter,
// js.wasm (the Roc in js/roc on the host in js/wasm). A program runs once,
// `start(src, onLine)`, then a frame at a time, `frame(t, onLine)`, while the
// last call ended `frame`.
//
// **EACH EFFECT ARRIVES WHILE THE PROGRAM RUNS.** The wasm calls the import
// `js_emit` with each effect's line (Canvas.line_of in js/roc/Canvas.roc) at
// the moment the program makes it, and this hands it to `onLine` before the
// program goes on; the pointer and the keys are asked of `input` when the
// program asks: `input.pointer(axis)` (0 for x, 1 for y) and
// `input.key(name)`, which the page sets. Each call's last line says how it ended (js/roc/JsApp.roc),
// and the call answers it: { ending, why }, the ending one of "frame",
// "done", "faulted", "refused" or "crashed".
//
// The page and page_check.mjs both use it, so the check drives the very
// code the page runs.

export async function loadRunner(wasmBytes) {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const input = { pointer: () => 200, key: () => false };
  let x = null;
  let onLine = () => {};
  let ended = null;
  const text = (p, n) => decoder.decode(new Uint8Array(x.memory.buffer, p, n));
  const env = {
    js_emit(p, n) {
      const line = text(p, n);
      if (line.startsWith("end ")) ended = line;
      else onLine(line);
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
    start(src, sink) {
      const bytes = encoder.encode(src);
      const at = x.sourcePtr(bytes.length);
      new Uint8Array(x.memory.buffer, at, bytes.length).set(bytes);
      return call(sink, () => x.start());
    },
    frame(t, sink) {
      return call(sink, () => x.frame(t));
    },
  };
}

// The words of a `log` or `text` line, its `\n` and `\\` read back.
export function unescaped(words) {
  return words.replace(/\\(n|\\)/g, (_, c) => (c === "n" ? "\n" : "\\"));
}

// What console.log printed, from a run's lines, as js-run prints it; a run
// that stopped ends with its `js: <why>` line, as js-run's does.
export function transcriptOf(lines, result) {
  let out = "";
  for (const line of lines) if (line.startsWith("log ")) out += unescaped(line.slice(4)) + "\n";
  if (result.ending === "faulted" || result.ending === "refused") out += `js: ${result.why}\n`;
  return out;
}
