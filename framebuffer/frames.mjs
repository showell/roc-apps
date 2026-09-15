// Run a program built by framebuffer/build.sh from Node, with no browser: give
// it the screen it brings (320 x 240 when it brings none), run it, and print
// each frame's time, how many pixels differ from the top-left one, and a hash of
// the image, then the console of the last frame. The last frame is also written
// as a PNG, ~/build/roc-apps/gen/framebuffer/<program>/frame.png.
//
//   node framebuffer/frames.mjs <program> [runs]          a frame is a run, the clock 100 ms on each time
//   node framebuffer/frames.mjs <program> flushes:<n>     a frame is a GPU flush; stop at the nth
//   node framebuffer/frames.mjs <path/to/program.wasm> ...
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import { crc32, deflateSync } from "node:zlib";

const dir = join(homedir(), "build/roc-apps/next/framebuffer");
const [n, count = "3"] = process.argv.slice(2);
const TICK = 100;
const flushBudget = count.startsWith("flushes:") ? Number(count.slice("flushes:".length)) : 0;
const runs = flushBudget ? Infinity : Number(count);
const name = n.endsWith(".wasm") ? basename(n, ".wasm") : n;
const listed = n.endsWith(".wasm") ? null : JSON.parse(readFileSync(join(dir, "programs.json"), "utf8")).find((p) => p.name === n);
const [W, H, S] = listed?.screen ?? [320, 240, 320];
const wasm = n.endsWith(".wasm") ? n : join(dir, `${n}.wasm`);

// FNV-1a over the visible pixels, as the page draws them.
function fnv(bytes) {
  let h = 0x811c9dc5;
  for (let i = 0; i < bytes.length; i++) h = Math.imul(h ^ bytes[i], 0x01000193);
  return (h >>> 0).toString(16).padStart(8, "0");
}

function png(w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) Buffer.from(rgba.buffer, rgba.byteOffset + y * w * 4, w * 4).copy(raw, y * (w * 4 + 1) + 1);
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(body));
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw)), chunk("IEND", Buffer.alloc(0))]);
}

let x = null, last = null, frame = 0, started = 0;
const ENOUGH = new Error("enough flushes");

// One frame: the pixels now on the screen, reported and kept.
function report(ms) {
  const px = new Uint8Array(x.memory.buffer, x.present(), W * H * 4);
  let drawn = 0;
  for (let i = 0; i < px.length; i += 4) if (px[i] !== px[0] || px[i + 1] !== px[1] || px[i + 2] !== px[2]) drawn++;
  const mb = (x.memory.buffer.byteLength / 1048576).toFixed(0);
  console.log(`frame ${frame}: ${ms.toFixed(0)} ms, ${drawn} pixels unlike the top-left, hash ${fnv(px)}, ${x.pagesMade()} pages, wasm memory ${mb} MB`);
  last = px.slice();
  frame++;
}

function frameFlushed() {
  if (!flushBudget) return;
  report(performance.now() - started);
  if (frame === flushBudget) throw ENOUGH;
  started = performance.now();
}

// A program's asset load reads the file under the preview's assets/, where the
// page's runner fetches it.
let asset = null;
function assetSize(ptr, len) {
  try {
    asset = readFileSync(join(dir, "assets", text(ptr, len)));
    return asset.length;
  } catch {
    return -1;
  }
}
function assetRead(ptr) {
  new Uint8Array(x.memory.buffer, ptr, asset.length).set(asset);
  asset = null;
}

const { instance } = await WebAssembly.instantiate(readFileSync(wasm), { env: { frameFlushed, assetSize, assetRead } });
x = instance.exports;
const text = (ptr, len) => new TextDecoder().decode(new Uint8Array(x.memory.buffer, ptr, len));
if (!x.screen(W, H, S)) throw new Error(`no ${W} x ${H} screen with stride ${S}`);

for (let r = 0; r < runs && frame < (flushBudget || Infinity); r++) {
  x.clock(r * TICK);
  started = performance.now();
  const before = frame;
  try {
    x.run();
  } catch (e) {
    if (e !== ENOUGH) {
      console.log(`run ${r}: stopped: ${text(x.crashPtr(), x.crashLen()) || e.message}`);
      process.exit(1);
    }
  }
  if (!flushBudget) report(performance.now() - started);
  else if (frame === before) {
    console.log(`run ${r} ended without a GPU flush; count runs instead`);
    process.exit(1);
  }
}
process.stdout.write(text(x.consolePtr(), x.consoleLen()));
if (last) {
  const out = join(homedir(), "build/roc-apps/gen/framebuffer", name);
  mkdirSync(out, { recursive: true });
  writeFileSync(join(out, "frame.png"), png(W, H, last));
}
