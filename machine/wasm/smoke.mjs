// Drive the machine's wasm from Node, with no browser: load the module and the
// disk image, make a machine, step it, send two keys, and print the console
// and the landed span.
//
//   node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine
import { readFileSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2];
const { instance } = await WebAssembly.instantiate(readFileSync(join(dir, "machine.wasm")), {});
const x = instance.exports;
const image = readFileSync(join(dir, "drive0.img"));
new Uint8Array(x.memory.buffer, x.diskPtr(), image.length).set(image);
x.newMachine(image.length);

function view() {
  const n = x.view();
  const b = new Uint8Array(x.memory.buffer, x.outPtr(), n).slice();
  let p = 0;
  const u32 = () => { const v = (b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24)) >>> 0; p += 4; return v; };
  const status = b[p++];
  const steps = u32();
  const clen = u32();
  const console = new TextDecoder().decode(b.subarray(p, p + clen)); p += clen;
  const count = u32(); p += count * 12;
  const addr = u32(), len = u32();
  const span = b.subarray(p, p + len);
  return { status, steps, console, count, addr, len, span };
}

x.step(1000);
x.key(0x1e);
x.key(0x39);
x.step(1000);
const v = view();
process.stdout.write(v.console);
console.log(`status ${v.status} steps ${v.steps} pci ${v.count} landed 0x${v.addr.toString(16)} len ${v.len}`);
console.log(`span[0..16] ${Array.from(v.span.subarray(0, 16)).join(" ")}`);
console.log(`image[0..16] ${Array.from(image.subarray(0, 16)).join(" ")}`);
