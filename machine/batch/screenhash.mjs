// The screen a unit built by machine/batch/build.sh leaves, hashed as
// framebuffer/frames.mjs hashes its own: the first `width` pixels of each row
// as red, green, blue, 255, FNV-1a over the bytes. Prints the console, the hash
// and how many pixels differ from the top-left one, so the machine's GPU
// (MachineGpu, Roc) and the framebuffer platform's (gpu.zig) can be compared on
// the same program.
//
//   node machine/batch/screenhash.mjs <unit>
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const dir = join(homedir(), "build/roc-apps/next/machine/batch");
const n = process.argv[2];
const { instance } = await WebAssembly.instantiate(readFileSync(join(dir, `${n}.wasm`)), {});
const x = instance.exports;
const bytes = (ptr, len) => new Uint8Array(x.memory.buffer, ptr, len);
const words = [];
const vmargs = join(dir, `${n}.vmargs`);
if (existsSync(vmargs)) {
  for (const l of readFileSync(vmargs, "utf8").split("\n")) if (!l.startsWith("#")) words.push(...l.split(/\s+/).filter(Boolean));
}
const line = new TextEncoder().encode(words.map((w) => w + "\0").join(""));
bytes(x.argsBuffer(), line.length).set(line);
const t0 = performance.now();
const code = x.run(line.length);
const ms = performance.now() - t0;
process.stdout.write(new TextDecoder().decode(bytes(x.consolePtr(), x.consoleLen())));
const w = x.screenWidth(), h = x.screenHeight(), stride = x.screenStride();
const src = bytes(x.screenPtr(), x.screenLen());
const px = new Uint8Array(w * h * 4);
for (let y = 0; y < h; y++) {
  for (let c = 0; c < w; c++) {
    const s = (y * stride + c) * 4, d = (y * w + c) * 4;
    px[d] = src[s + 2]; px[d + 1] = src[s + 1]; px[d + 2] = src[s]; px[d + 3] = 255;
  }
}
let hash = 0x811c9dc5, drawn = 0;
for (let i = 0; i < px.length; i++) hash = Math.imul(hash ^ px[i], 0x01000193);
for (let i = 0; i < px.length; i += 4) if (px[i] !== px[0] || px[i + 1] !== px[1] || px[i + 2] !== px[2]) drawn++;
console.log(`-- exit ${code} in ${ms.toFixed(0)} ms, ${w} x ${h} stride ${stride}, ${drawn} pixels unlike the top-left, hash ${(hash >>> 0).toString(16).padStart(8, "0")}`);
