// js_runner -- the page's door onto the JavaScript subset's interpreter,
// js.wasm (the Roc in js/roc on the host in js/wasm). One call a run: the
// program's bytes go in at sourcePtr, run() answers the transcript's length,
// and the transcript is read at transcriptPtr. Its first byte says how the
// run ended: 0 it ran to its end, 1 it stopped with a fault, 2 the parser
// refused it.
//
// The page and page_check.mjs both use it, so the check drives the very
// code the page runs.

const ENDINGS = ["ran", "faulted", "refused"];

export async function loadRunner(wasmBytes) {
  const { instance } = await WebAssembly.instantiate(wasmBytes, {});
  const x = instance.exports;
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  return {
    run(src) {
      const bytes = encoder.encode(src);
      const at = x.sourcePtr(bytes.length);
      new Uint8Array(x.memory.buffer, at, bytes.length).set(bytes);
      let length;
      try {
        length = x.run();
      } catch (e) {
        const said = decoder.decode(new Uint8Array(x.memory.buffer, x.crashPtr(), x.crashLen()));
        return { ending: "crashed", text: `the interpreter crashed: ${said || e.message}\n` };
      }
      const out = new Uint8Array(x.memory.buffer, x.transcriptPtr(), length);
      return { ending: ENDINGS[out[0]] ?? "unknown", text: decoder.decode(out.subarray(1)) };
    },
  };
}
