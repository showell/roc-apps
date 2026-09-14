// The framebuffer page's runner, a Web Worker: one program's wasm, run off the
// page's thread, so a program that draws in a loop of its own can run as long
// as it likes while the page still shows its frames and answers its buttons.
//
// The page sends { name, kind, screen: [width, height, stride], firstRun, frames, input }.
// `input`, when the page is cross-origin isolated, is a SharedArrayBuffer the
// page writes keys and mouse moves into while the program runs: an Int32Array
// ring, [head, tail] then four ints a event (1 and a scancode, or 2 and x, y and
// buttons). The runner hands what has arrived to the host before each run and
// at every GPU flush, so a program that never ends its run still hears it.
// With kind "run" a frame is a run of the program's opening, the clock 100 ms
// further on each time. With kind "flush" a frame is a GPU flush inside the one
// run of a program that never ends it, and while playing at most one flush in
// 30 ms is shown. The runner posts
//   { kind: "frame", pixels, width, height, console, run, ms }   for each frame shown,
//   { kind: "done", run }                                        after `frames` frames, or when the program ends its loop,
//   { kind: "stopped", why, console }                            when the program or the host crashes.
const TICK = 100;
const GAP = 30;

self.onmessage = async ({ data }) => {
  const { name, kind, screen: [w, h, s], firstRun, frames, input } = data;
  const ring = input ? new Int32Array(input) : null;
  const slots = ring ? (ring.length - 2) / 4 : 0;
  const ENOUGH = new Error("enough frames");
  let x = null;
  let shown = 0;
  let run = firstRun;
  let lastShown = -Infinity;
  let lastFlush = 0;
  const text = (ptr, len) => new TextDecoder().decode(new Uint8Array(x.memory.buffer, ptr, len).slice());
  const show = (ms) => {
    lastShown = performance.now();
    const pixels = new Uint8ClampedArray(x.memory.buffer, x.present(), w * h * 4).slice();
    shown += 1;
    self.postMessage({ kind: "frame", pixels, width: w, height: h, console: text(x.consolePtr(), x.consoleLen()), run, ms }, [pixels.buffer]);
  };
  // The page is the ring's one writer and the runner its one reader.
  const drain = () => {
    if (!ring) return;
    let head = Atomics.load(ring, 0);
    const tail = Atomics.load(ring, 1);
    while (head !== tail) {
      const at = 2 + head * 4;
      if (ring[at] === 1) x.key(ring[at + 1]);
      else if (ring[at] === 2) x.mouse(ring[at + 1], ring[at + 2], ring[at + 3]);
      head = (head + 1) % slots;
    }
    Atomics.store(ring, 0, head);
  };
  const frameFlushed = () => {
    drain();
    if (kind !== "flush") return;
    const now = performance.now();
    const ms = now - lastFlush;
    lastFlush = now;
    if (frames === Infinity && now - lastShown < GAP) return;
    show(ms);
    if (shown >= frames) throw ENOUGH;
  };
  const stopped = (why) => self.postMessage({ kind: "stopped", why, console: x ? text(x.consolePtr(), x.consoleLen()) : "" });

  try {
    const bytes = await (await fetch(`${name}.wasm`)).arrayBuffer();
    x = (await WebAssembly.instantiate(bytes, { env: { frameFlushed } })).instance.exports;
  } catch (e) {
    return stopped(`${name}.wasm did not load: ${e.message}`);
  }
  if (!x.screen(w, h, s)) return stopped(`the host has no room for a ${w} × ${h} screen`);

  while (shown < frames) {
    drain();
    x.clock(run * TICK);
    const t0 = performance.now();
    lastFlush = t0;
    try {
      x.run();
    } catch (e) {
      if (e === ENOUGH) break;
      return stopped(text(x.crashPtr(), x.crashLen()) || e.message);
    }
    show(performance.now() - t0);
    run += 1;
    if (kind === "flush") break;
    // Let the page's messages in between runs.
    await new Promise((resolve) => setTimeout(resolve, 0));
  }
  self.postMessage({ kind: "done", run });
};
