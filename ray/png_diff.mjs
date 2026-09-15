#!/usr/bin/env node
// Compare two same-sized PNGs pixel by pixel on red, green and blue: how many
// pixels differ at all, how many by more than a tolerance on any channel, and
// the largest channel difference. For the Windows runner's screenshots of the
// two painters, where a small difference is rasterisation and a large one is a
// bug. 8-bit RGB or RGBA, non-interlaced, as raylib writes them.
//
//   ray/png_diff.mjs <a.png> <b.png> [tolerance]    tolerance defaults to 8
import { inflateSync } from "node:zlib";
import { readFileSync } from "node:fs";

function decode(path) {
  const buf = readFileSync(path);
  let at = 8, width = 0, height = 0, channels = 0;
  const idat = [];
  while (at < buf.length) {
    const len = buf.readUInt32BE(at), type = buf.toString("ascii", at + 4, at + 8);
    const data = buf.subarray(at + 8, at + 8 + len);
    if (type === "IHDR") {
      width = data.readUInt32BE(0); height = data.readUInt32BE(4);
      if (data[8] !== 8 || data[12] !== 0) throw new Error(`${path}: not 8-bit non-interlaced`);
      channels = { 2: 3, 6: 4 }[data[9]];
      if (!channels) throw new Error(`${path}: colour type ${data[9]} is not RGB or RGBA`);
    } else if (type === "IDAT") idat.push(data);
    at += 12 + len;
  }
  const raw = inflateSync(Buffer.concat(idat));
  const stride = width * channels, px = Buffer.alloc(height * stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)], src = y * (stride + 1) + 1, row = y * stride;
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? px[row + x - channels] : 0;
      const b = y > 0 ? px[row - stride + x] : 0;
      const c = x >= channels && y > 0 ? px[row - stride + x - channels] : 0;
      const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
      const pred = [0, a, b, (a + b) >> 1, pa <= pb && pa <= pc ? a : pb <= pc ? b : c][filter];
      px[row + x] = (raw[src + x] + pred) & 255;
    }
  }
  return { width, height, channels, px };
}

const [pa, pb, tolArg = "8"] = process.argv.slice(2);
if (!pa || !pb) { console.error("usage: png_diff.mjs <a.png> <b.png> [tolerance]"); process.exit(2); }
const a = decode(pa), b = decode(pb), tol = Number(tolArg);
if (a.width !== b.width || a.height !== b.height) throw new Error("the images differ in size");
let differ = 0, over = 0, worst = 0;
for (let i = 0; i < a.width * a.height; i++) {
  let d = 0;
  for (let c = 0; c < 3; c++) d = Math.max(d, Math.abs(a.px[i * a.channels + c] - b.px[i * b.channels + c]));
  if (d > 0) differ++;
  if (d > tol) over++;
  worst = Math.max(worst, d);
}
const n = a.width * a.height;
console.log(`${a.width}x${a.height}: ${differ} differ (${(100 * differ / n).toFixed(2)}%), ${over} by more than ${tol} (${(100 * over / n).toFixed(2)}%), largest ${worst}`);
