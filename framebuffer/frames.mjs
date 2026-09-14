// Run a program built by framebuffer/build.sh from Node, with no browser: give
// it the screen it brings (320 x 240 when it brings none), run it frame after
// frame with the clock 100 ms further on each time, and print each frame's time,
// how many pixels differ from the top-left one, and a hash of the image, then
// the console of the last frame.
//
//   node framebuffer/frames.mjs <program> [frames]
//   node framebuffer/frames.mjs <path/to/program.wasm> [frames]
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const dir = join(homedir(), "build/roc-apps/next/framebuffer");
const [n, count = "3"] = process.argv.slice(2);
const TICK = 100;
const listed = n.endsWith(".wasm") ? null : JSON.parse(readFileSync(join(dir, "programs.json"), "utf8")).find((p) => p.name === n);
const [W, H, S] = listed?.screen ?? [320, 240, 320];
const wasm = n.endsWith(".wasm") ? n : join(dir, `${n}.wasm`);
const { instance } = await WebAssembly.instantiate(readFileSync(wasm), {});
const x = instance.exports;
const text = (ptr, len) => new TextDecoder().decode(new Uint8Array(x.memory.buffer, ptr, len));
if (!x.screen(W, H, S)) throw new Error(`no ${W} x ${H} screen with stride ${S}`);

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
  for (let i = 0; i < px.length; i += 4) if (px[i] !== px[0] || px[i + 1] !== px[1] || px[i + 2] !== px[2]) drawn++;
  last = text(x.consolePtr(), x.consoleLen());
  const mb = (x.memory.buffer.byteLength / 1048576).toFixed(0);
  console.log(`frame ${f}: ${ms.toFixed(0)} ms, exit ${code}, ${drawn} pixels unlike the top-left, hash ${fnv(px)}, ${x.pagesMade()} pages, wasm memory ${mb} MB`);
}
process.stdout.write(last);
