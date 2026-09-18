#!/usr/bin/env node
// **DOES THE PAGE ACTUALLY RUN?** Node checks the wasm and never touches
// blitter.js, which is how a reference error in it reached the browser: the
// canvas was sized from a module that had not been bound yet, and every page
// threw before drawing a pixel.
//
// So this runs blitter.js the way a browser would, against a canvas that
// records rather than paints and the real wasm. It cannot say whether a frame
// LOOKS right -- nothing here can -- but it says the page runs, draws, and
// keeps drawing.
//
//   web/page_check.mjs <movie>            one of the built pages
import { readFileSync } from "node:fs";
import vm from "node:vm";

const name = process.argv[2];
if (!name) { console.error("usage: page_check.mjs <movie>"); process.exit(2); }
const dir = `${process.env.HOME}/build/roc-apps/next/${name}`;
const page = readFileSync(`${dir}/index.html`, "utf8");
const blitter = readFileSync(`${dir}/blitter.js`, "utf8");

// The show the page declares, taken from the page rather than assumed.
const showSrc = page.match(/window\.SHOW\s*=\s*(\{[\s\S]*?\});/);
if (!showSrc) throw new Error("the page does not set window.SHOW");

let calls = 0, fills = 0;
const ctx = new Proxy({}, {
  get: (_t, k) => {
    if (k === "canvas") return { width: 0, height: 0 };
    if (k === "measureText") return () => ({ width: 10 });
    if (k === "createLinearGradient" || k === "createRadialGradient")
      return () => ({ addColorStop() {} });
    return (...a) => { calls++; if (k === "fill" || k === "fillRect") fills++; return undefined; };
  },
  set: () => true,
});

const el = () => ({
  style: {}, width: 0, height: 0, textContent: "", appendChild() {}, remove() {},
  getContext: () => ctx, addEventListener() {},
});
const document_ = {
  body: { style: {}, appendChild() {} },
  head: { appendChild() {} },
  createElement: el,
  addEventListener() {},
};

let frames = 0;
const sandbox = {
  console, performance, WebAssembly, fetch: async () => ({}), TextDecoder,
  document: document_, window: {},
  requestAnimationFrame: (fn) => { if (frames++ < 30) setImmediate(fn); },
  setImmediate,
};
sandbox.addEventListener = () => {};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;

// The one thing a page cannot do here: stream a module over fetch.
const bytes = readFileSync(`${dir}/${name}.wasm`);
sandbox.WebAssembly = Object.create(WebAssembly);
sandbox.WebAssembly.instantiateStreaming = async () => {
  const mod = new WebAssembly.Module(bytes);
  const env = {};
  for (const imp of WebAssembly.Module.imports(mod)) env[imp.name] = () => {};
  return { instance: new WebAssembly.Instance(mod, { env }) };
};

vm.createContext(sandbox);
vm.runInContext(`window.SHOW = ${showSrc[1]};`, sandbox);
vm.runInContext(blitter, sandbox, { filename: "blitter.js" });

await new Promise((r) => setTimeout(r, 400));
if (frames < 2) { console.error(`${name}: the page never asked for a second frame`); process.exit(1); }
if (fills === 0) { console.error(`${name}: the page drew nothing`); process.exit(1); }
console.log(`${name}: ran ${frames} frames, ${calls} canvas calls, ${fills} fills`);
