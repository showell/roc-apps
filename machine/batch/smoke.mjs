// Run a unit built by machine/batch/build.sh from Node, with no browser: load
// its wasm and disk images, run it, print the console and a crash's message,
// and compare the console with the unit's cleaned verdict.
//
//   node machine/batch/smoke.mjs <unit>
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const dir = join(homedir(), "build/roc-apps/next/machine/batch");
const n = process.argv[2];
const { instance } = await WebAssembly.instantiate(readFileSync(join(dir, `${n}.wasm`)), {});
const x = instance.exports;
const bytes = (ptr, len) => new Uint8Array(x.memory.buffer, ptr, len);

// Each image the unit brings goes in its drive's buffer, and the command line
// names it as codex-vm's flags do.
const words = [];
for (const [p, ext, flag] of [[0, "disk", "-disk"], [1, "disk2", "-disk2"]]) {
  const path = join(dir, `${n}.${ext}`);
  if (!existsSync(path)) continue;
  const image = readFileSync(path);
  const at = x.driveBuffer(p, image.length);
  if (at === 0) throw new Error(`no buffer for drive ${p}`);
  bytes(at, image.length).set(image);
  words.push(flag, `drive${p}`);
}
const line = new TextEncoder().encode(words.map((w) => w + "\0").join(""));
bytes(x.argsBuffer(), line.length).set(line);

let code = null, trapped = null;
const t0 = performance.now();
try {
  code = x.run(line.length);
} catch (e) {
  trapped = e;
}
const ms = (performance.now() - t0).toFixed(0);
const text = new TextDecoder().decode(bytes(x.consolePtr(), x.consoleLen()));
process.stdout.write(text);
if (trapped) {
  const why = new TextDecoder().decode(bytes(x.crashPtr(), x.crashLen()));
  console.log(`-- trapped after ${ms} ms: ${why || trapped.message}`);
} else {
  console.log(`-- exit ${code} after ${ms} ms`);
}
let sent = 0, answered = 0;
const wire = bytes(x.wirePtr(), x.wireLen());
for (let p = 0; p + 5 <= wire.length; p += 5 + ((wire[p + 1] | (wire[p + 2] << 8) | (wire[p + 3] << 16) | (wire[p + 4] << 24)) >>> 0)) {
  if (wire[p] === 0) sent++; else answered++;
}
console.log(`-- the wire: ${sent} sent, ${answered} answered`);
const verdict = join(dir, `${n}.expected`);
if (existsSync(verdict)) {
  const want = readFileSync(verdict, "utf8");
  const got = text.replace(/\n+$/, "\n");
  console.log(got === want ? "-- matches the verdict" : "-- DIFFERS from the verdict");
}
