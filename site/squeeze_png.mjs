// squeeze_png.mjs rewrites an 8-bit RGB or RGBA PNG as a small RGB one, the
// same pixels with the alpha dropped. roc-screensaver's native harness writes
// its frames uncompressed (a 960 by 600 frame is 1.7 MB), and a landing page's
// picture should be a few tens of kilobytes. Each row takes whichever of PNG's
// five filters leaves the smallest sum, the usual heuristic, and the rows are
// deflated at level 9. site/publish_screensavers.shale runs it.
//
//   node site/squeeze_png.mjs <in.png> <out.png>
import { readFileSync, writeFileSync } from "node:fs";
import zlib from "node:zlib";

const [from, to] = process.argv.slice(2);
if (!from || !to) { console.error("usage: squeeze_png.mjs <in.png> <out.png>"); process.exit(2); }

const png = readFileSync(from);
let at = 8;
let width = 0, height = 0, channels = 0;
const idat = [];
while (at < png.length) {
  const length = png.readUInt32BE(at);
  const type = png.toString("ascii", at + 4, at + 8);
  const data = png.subarray(at + 8, at + 8 + length);
  if (type === "IHDR") {
    width = data.readUInt32BE(0);
    height = data.readUInt32BE(4);
    if (data[8] !== 8 || (data[9] !== 2 && data[9] !== 6) || data[12] !== 0) {
      console.error(`${from}: only 8-bit RGB or RGBA, not interlaced (depth ${data[8]}, colour type ${data[9]}, interlace ${data[12]})`);
      process.exit(1);
    }
    channels = data[9] === 2 ? 3 : 4;
  }
  if (type === "IDAT") idat.push(data);
  at += 12 + length;
}
const packed = zlib.inflateSync(Buffer.concat(idat));
const stride = width * channels;
if (packed.length !== height * (stride + 1)) { console.error(`${from}: ${packed.length} bytes of pixels, expected ${height * (stride + 1)}`); process.exit(1); }

const paeth = (a, b, c) => {
  const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
};
// The predictor of filter `f` for byte `i` of a row, `bpp` bytes a pixel.
const predict = (f, row, prior, i, bpp) => {
  const a = i >= bpp ? row[i - bpp] : 0, b = prior[i], c = i >= bpp ? prior[i - bpp] : 0;
  return [0, a, b, (a + b) >> 1, paeth(a, b, c)][f];
};

// Unfilter into RGB rows.
const rgb = Buffer.alloc(height * width * 3);
let prior = Buffer.alloc(stride);
for (let y = 0; y < height; y++) {
  const f = packed[y * (stride + 1)];
  const row = Buffer.from(packed.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)));
  for (let i = 0; i < stride; i++) row[i] = (row[i] + predict(f, row, prior, i, channels)) & 0xff;
  for (let x = 0; x < width; x++) row.copy(rgb, (y * width + x) * 3, x * channels, x * channels + 3);
  prior = row;
}

// Filter each RGB row by the filter with the smallest sum of signed bytes.
const out = Buffer.alloc(height * (width * 3 + 1));
const rowBytes = width * 3;
prior = Buffer.alloc(rowBytes);
for (let y = 0; y < height; y++) {
  const row = rgb.subarray(y * rowBytes, (y + 1) * rowBytes);
  let best = null, bestSum = Infinity, bestF = 0;
  for (let f = 0; f < 5; f++) {
    const line = Buffer.alloc(rowBytes);
    let sum = 0;
    for (let i = 0; i < rowBytes; i++) {
      const v = (row[i] - predict(f, row, prior, i, 3)) & 0xff;
      line[i] = v;
      sum += v < 128 ? v : 256 - v;
    }
    if (sum < bestSum) { best = line; bestSum = sum; bestF = f; }
  }
  out[y * (rowBytes + 1)] = bestF;
  best.copy(out, y * (rowBytes + 1) + 1);
  prior = row;
}

const CRC = new Uint32Array(256).map((_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
const crc32 = (buf) => {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const head = Buffer.alloc(8);
  head.writeUInt32BE(data.length, 0);
  head.write(type, 4, "ascii");
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([head.subarray(4), data])), 0);
  return Buffer.concat([head, data, crc]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(width, 0);
ihdr.writeUInt32BE(height, 4);
ihdr[8] = 8;
ihdr[9] = 2;
const squeezed = Buffer.concat([
  png.subarray(0, 8), chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(out, { level: 9 })), chunk("IEND", Buffer.alloc(0)),
]);
writeFileSync(to, squeezed);
console.log(`squeezed ${from}: ${width} by ${height}, ${png.length} bytes to ${squeezed.length}`);
