#!/usr/bin/env node
// Run a Roc wasm module from Node the way a browser would: satisfy its `env`
// imports and call its exported entry.
//
//   wasm/run_wasm.mjs <module.wasm> [entry]        entry defaults to wasm_main
//
// Roc's test host exports `wasm_main`, which answers a pointer to a string,
// and `wasm_result_len`, its length. Anything the module imports from `env`
// that this file does not know is given a function that logs its call, so an
// unexpected import is visible rather than a silent link failure. `echo` and
// `roc_dbg` write their bytes; `roc_panic` throws. Step one of the wasm plan:
// notes/safari-wasm-in-roc.md.
import { readFileSync } from "node:fs";

const [path, entry = "wasm_main"] = process.argv.slice(2);
if (!path) { console.error("usage: run_wasm.mjs <module.wasm> [entry]"); process.exit(2); }

const bytes = readFileSync(path);
const mod = new WebAssembly.Module(bytes);
let memory = null;
const text = (ptr, len) => new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
const known = {
  echo: (p, n) => process.stdout.write(text(p, n)),
  roc_dbg: (p, n) => process.stderr.write("dbg: " + text(p, n) + "\n"),
  roc_expect_failed: (p, n) => process.stderr.write("expect failed: " + text(p, n) + "\n"),
  roc_panic: (p, n) => { throw new Error("roc_panic: " + text(p, n)); },
};
const env = {};
for (const imp of WebAssembly.Module.imports(mod)) {
  if (imp.module !== "env") { console.error(`import from ${imp.module}.${imp.name}: unsupported`); process.exit(2); }
  env[imp.name] = known[imp.name] ?? ((...a) => console.error(`env.${imp.name}(${a.join(", ")}) called`));
}
const { exports } = new WebAssembly.Instance(mod, { env });
memory = exports.memory;
console.error("exports:", Object.keys(exports).join(" "));
const ptr = exports[entry]();
if (exports.wasm_result_len) {
  const len = exports.wasm_result_len();
  process.stdout.write(text(ptr, len) + "\n");
} else {
  console.log(`${entry} -> ${ptr}`);
}
