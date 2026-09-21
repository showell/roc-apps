#!/usr/bin/env node
// Turn canvas_apps/safari/RasterFrame's output into a PNG: a `hash` line, `<width>
// <height>`, then every pixel as six hex digits (0xRRGGBB, row-major). Prints
// the hash line and writes the image.
//
//   <RasterFrame binary> [steps] | ray/pixels_png.mjs <out.png>
import { deflateSync } from "node:zlib";
import { readFileSync, writeFileSync } from "node:fs";

const out = process.argv[2];
if (!out) { console.error("usage: ... | pixels_png.mjs <out.png>"); process.exit(2); }
const lines = readFileSync(0, "utf8").split("\n").filter((l) => l.length > 0);
const hashLine = lines.find((l) => l.startsWith("hash "));
const at = lines.indexOf(hashLine);
const [w, h] = lines[at + 1].split(" ").map(Number);
const hex = lines.slice(at + 2).join("");
if (hex.length !== w * h * 6) throw new Error(`expected ${w * h * 6} hex digits, got ${hex.length}`);

const raw = Buffer.alloc((w * 3 + 1) * h);
for (let y = 0; y < h; y++) {
  const row = y * (w * 3 + 1);
  for (let x = 0; x < w; x++) {
    const p = (y * w + x) * 6;
    for (let c = 0; c < 3; c++) raw[row + 1 + x * 3 + c] = parseInt(hex.substr(p + 2 * c, 2), 16);
  }
}

const table = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
const crc = (buf) => {
  let c = 0xffffffff;
  for (const b of buf) c = table[(c ^ b) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const sum = Buffer.alloc(4); sum.writeUInt32BE(crc(body));
  return Buffer.concat([len, body, sum]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
writeFileSync(out, Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr), chunk("IDAT", deflateSync(raw)), chunk("IEND", Buffer.alloc(0)),
]));
console.log(hashLine);
