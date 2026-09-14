// Run a program built by framebuffer/build.sh from Node, with no browser: give
// it a 320 x 240 screen, run it frame after frame with the clock 100 ms further
// on each time, and print each frame's time and a hash of its pixels, then the
// console of the last frame.
//
//   node framebuffer/frames.mjs <program> [frames]
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const dir = join(homedir(), "build/roc-apps/next/framebuffer");
const [n, count = "3"] = process.argv.slice(2);
const W = 320, H = 240, TICK = 100;
const { instance } = await WebAssembly.instantiate(readFileSync(join(dir, `${n}.wasm`)), {});
const x = instance.exports;
const text = (ptr, len) => new TextDecoder().decode(new Uint8Array(x.memory.buffer, ptr, len));
if (!x.screen(W, H, W)) throw new Error(`no ${W} x ${H} screen`);

// FNV-1a over the visible pixels, as the page draws them.
function fnv(bytes) {
  let h = 0x811c9dc5;
  for (let i = 0; i < bytes.length; i++) h = Math.imul(h ^ bytes[i], 0x01000193);
  return (h >>> 0).toString(16).padStart(8, "0");
}

let last = "";
for (let f = 0; f < Number(count); f++) {
  x.clock(f * TICK);
  const t0 = performance.now();
  let code;
  try {
    code = x.run();
  } catch (e) {
    console.log(`frame ${f}: stopped: ${text(x.crashPtr(), x.crashLen()) || e.message}`);
    process.exit(1);
  }
  const ms = performance.now() - t0;
  const px = new Uint8Array(x.memory.buffer, x.present(), W * H * 4);
  let drawn = 0;
  for (let i = 0; i < px.length; i += 4) if (px[i] !== 20 || px[i + 1] !== 20 || px[i + 2] !== 30) drawn++;
  last = text(x.consolePtr(), x.consoleLen());
  const mb = (x.memory.buffer.byteLength / 1048576).toFixed(0);
  console.log(`frame ${f}: ${ms.toFixed(0)} ms, exit ${code}, ${drawn} pixels not sky, hash ${fnv(px)}, ${x.pagesMade()} pages, wasm memory ${mb} MB`);
}
process.stdout.write(last);
