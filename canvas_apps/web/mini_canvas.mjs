// mini_canvas — a dependency-free software rasterizer for the part of
// CanvasRenderingContext2D that shapewire.js and canvas_app_runner.js use, so a
// canvas app's frame can be SEEN without a browser.
//
// Ported from angry-gopher's games/driving/mini_canvas.ts, which does the same
// for the driving game's cat, and extended to what the canvas apps paint with:
// linear and concentric radial gradients, clip, the additive `lighter`
// composite, global alpha, and images put through a scratch canvas. The real
// painter runs unchanged against it; this is a canvas, not a re-implementation
// of any app.
//
// **IT PAINTS WHAT IT IS ASKED AND REFUSES WHAT IT DOES NOT KNOW.** An operation
// or a composite mode outside the list below throws, rather than painting
// something plausible, because a quietly wrong picture is worse than none.
//
// Coverage is point-sampled at SS x SS per pixel and box-filtered down, which is
// where the anti-aliasing comes from. Gradients mix unpremultiplied, as the
// canvas specification says and Brush.shade does. PNG goes out through node's
// own zlib.
//
//   import { createCanvas } from './mini_canvas.mjs';
//   const canvas = createCanvas(800, 600);
//   const ctx = canvas.getContext('2d');   // ... paint ...
//   writeFileSync('frame.png', canvas.toPNG());
import zlib from 'node:zlib';

const SS = 4;

// ── colours ────────────────────────────────────────────────────────────────

function parseColor(s) {
  if (typeof s !== 'string') throw new Error(`mini_canvas: not a colour: ${s}`);
  const t = s.trim();
  if (t[0] === '#') {
    let hex = t.slice(1);
    if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    const n = parseInt(hex, 16);
    return [(n >> 16) & 255, (n >> 8) & 255, n & 255, 1];
  }
  const m = t.match(/^rgba?\(([^)]+)\)$/);
  if (m) {
    const p = m[1].split(',').map((x) => parseFloat(x));
    return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
  }
  throw new Error(`mini_canvas: cannot read colour ${s}`);
}

class Gradient {
  constructor(kind, geometry) {
    this.kind = kind;
    this.geometry = geometry;
    this.stops = [];
  }
  addColorStop(offset, color) {
    this.stops.push([offset, parseColor(color)]);
    this.stops.sort((a, b) => a[0] - b[0]);
  }
  // The colour at gradient parameter t, mixed unpremultiplied, written into
  // `out` -- a pixel's worth of arithmetic should not allocate.
  at(t, out) {
    const s = this.stops;
    if (!s.length) { out[0] = out[1] = out[2] = out[3] = 0; return out; }
    let c0 = s[s.length - 1][1], c1 = c0, k = 0;
    if (t <= s[0][0]) { c0 = c1 = s[0][1]; } else {
      for (let i = 1; i < s.length; i++) {
        if (t <= s[i][0]) {
          const o0 = s[i - 1][0], o1 = s[i][0];
          c0 = s[i - 1][1]; c1 = s[i][1];
          k = o1 > o0 ? (t - o0) / (o1 - o0) : 1;
          break;
        }
      }
    }
    out[0] = c0[0] + (c1[0] - c0[0]) * k; out[1] = c0[1] + (c1[1] - c0[1]) * k;
    out[2] = c0[2] + (c1[2] - c0[2]) * k; out[3] = c0[3] + (c1[3] - c0[3]) * k;
    return out;
  }
  // Where a user-space point falls along the gradient.
  param(x, y) {
    const g = this.geometry;
    if (this.kind === 'linear') {
      const [x0, y0, x1, y1] = g;
      const dx = x1 - x0, dy = y1 - y0;
      const len2 = dx * dx + dy * dy;
      return len2 === 0 ? 0 : ((x - x0) * dx + (y - y0) * dy) / len2;
    }
    const [x0, y0, r0, x1, y1, r1] = g;
    return r1 === r0 ? 1 : (Math.hypot(x - x1, y - y1) - r0) / (r1 - r0);
  }
}

// ── the matrix ─────────────────────────────────────────────────────────────
// [a, b, c, d, e, f]: device = (a·x + c·y + e, b·x + d·y + f), device being
// the supersampled buffer.

const multiply = ([a, b, c, d, e, f], [A, B, C, D, E, F]) =>
  [a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D, a * E + c * F + e, b * E + d * F + f];

function invert([a, b, c, d, e, f]) {
  const det = a * d - b * c;
  if (det === 0) throw new Error('mini_canvas: a transform with no inverse');
  return [d / det, -b / det, -c / det, a / det, (c * f - d * e) / det, (b * e - a * f) / det];
}

// ── the canvas ─────────────────────────────────────────────────────────────

class Context {
  constructor(canvas) {
    this.canvas = canvas;
    this.reset();
  }

  reset() {
    this.st = {
      m: [SS, 0, 0, SS, 0, 0],
      fillStyle: '#000',
      globalAlpha: 1,
      globalCompositeOperation: 'source-over',
      imageSmoothingEnabled: true,
      clip: null,
    };
    this.stack = [];
    this.subs = [];
    this.sub = null;
  }

  get fillStyle() { return this.st.fillStyle; }
  set fillStyle(v) { this.st.fillStyle = v; }
  get globalAlpha() { return this.st.globalAlpha; }
  set globalAlpha(v) { this.st.globalAlpha = v; }
  get globalCompositeOperation() { return this.st.globalCompositeOperation; }
  set globalCompositeOperation(v) {
    if (v !== 'source-over' && v !== 'lighter') throw new Error(`mini_canvas: no composite ${v}`);
    this.st.globalCompositeOperation = v;
  }
  get imageSmoothingEnabled() { return this.st.imageSmoothingEnabled; }
  set imageSmoothingEnabled(v) { this.st.imageSmoothingEnabled = v; }

  save() { this.stack.push({ ...this.st, m: [...this.st.m] }); }
  restore() { const s = this.stack.pop(); if (s) this.st = s; }
  setTransform(a, b, c, d, e, f) { this.st.m = [a * SS, b * SS, c * SS, d * SS, e * SS, f * SS]; }
  transform(a, b, c, d, e, f) { this.st.m = multiply(this.st.m, [a, b, c, d, e, f]); }

  apply(x, y) {
    const [a, b, c, d, e, f] = this.st.m;
    return [a * x + c * y + e, b * x + d * y + f];
  }

  // ── path ──
  beginPath() { this.subs = []; this.sub = null; }
  moveTo(x, y) { this.sub = [this.apply(x, y)]; this.subs.push(this.sub); }
  lineTo(x, y) {
    if (!this.sub) { this.moveTo(x, y); return; }
    this.sub.push(this.apply(x, y));
  }
  closePath() { if (this.sub && this.sub.length) this.sub.push([...this.sub[0]]); }
  rect(x, y, w, h) {
    this.moveTo(x, y); this.lineTo(x + w, y); this.lineTo(x + w, y + h); this.lineTo(x, y + h); this.closePath();
  }
  arc(cx, cy, r, a0, a1) {
    // Enough sides that no edge is longer than about a device pixel.
    const [a, b, c, d] = this.st.m;
    const scale = Math.sqrt(Math.abs(a * d - b * c));
    const span = a1 - a0;
    const n = Math.max(12, Math.min(720, Math.ceil(Math.abs(span) * r * scale / 2)));
    for (let i = 0; i <= n; i++) {
      const t = a0 + span * (i / n);
      const x = cx + r * Math.cos(t), y = cy + r * Math.sin(t);
      if (i === 0 && !this.sub) this.moveTo(x, y); else this.lineTo(x, y);
    }
  }

  // ── painting ──
  fill() { this.paint(this.subs, this.paintOf(this.st.fillStyle)); }
  fillRect(x, y, w, h) {
    this.paint([[this.apply(x, y), this.apply(x + w, y), this.apply(x + w, y + h), this.apply(x, y + h)]],
      this.paintOf(this.st.fillStyle));
  }
  clip() {
    const mask = this.canvas.coverage(this.subs);
    const old = this.st.clip;
    if (old) for (let i = 0; i < mask.length; i++) mask[i] &= old[i];
    this.st.clip = mask;
  }

  createLinearGradient(x0, y0, x1, y1) { return new Gradient('linear', [x0, y0, x1, y1]); }
  createRadialGradient(x0, y0, r0, x1, y1, r1) {
    if (x0 !== x1 || y0 !== y1) throw new Error('mini_canvas: only concentric radial gradients');
    return new Gradient('radial', [x0, y0, r0, x1, y1, r1]);
  }

  createImageData(w, h) { return { width: w, height: h, data: new Uint8ClampedArray(w * h * 4) }; }
  // Writes pixels as they are, ignoring the transform, the clip and the
  // composite, as the specification says.
  putImageData(image, x0, y0) { this.canvas.put(image, x0, y0); }

  drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh) {
    if (this.st.imageSmoothingEnabled) throw new Error('mini_canvas: only unsmoothed images');
    const quad = [this.apply(dx, dy), this.apply(dx + dw, dy), this.apply(dx + dw, dy + dh), this.apply(dx, dy + dh)];
    const inv = invert(this.st.m);
    this.paint([quad], (px, py) => {
      const ux = inv[0] * px + inv[2] * py + inv[4];
      const uy = inv[1] * px + inv[3] * py + inv[5];
      return src.pixel(Math.floor(sx + ((ux - dx) / dw) * sw), Math.floor(sy + ((uy - dy) / dh) * sh));
    });
  }

  // A fill style as either one colour or a colour per device point.
  paintOf(style) {
    if (style instanceof Gradient) {
      const inv = invert(this.st.m);
      const out = [0, 0, 0, 0];
      return (px, py) => style.at(style.param(inv[0] * px + inv[2] * py + inv[4], inv[1] * px + inv[3] * py + inv[5]), out);
    }
    return parseColor(style);
  }

  paint(polys, paint) {
    this.canvas.fill(polys, paint, this.st.globalAlpha, this.st.globalCompositeOperation === 'lighter', this.st.clip);
  }
}

class Canvas {
  constructor(width, height) {
    this._width = width;
    this._height = height;
    this.allocate();
  }
  get width() { return this._width; }
  set width(v) { this._width = v; this.allocate(); }
  get height() { return this._height; }
  set height(v) { this._height = v; this.allocate(); }

  // Setting a size clears the canvas and its state, as a real one does.
  allocate() {
    this.dw = this._width * SS;
    this.dh = this._height * SS;
    this.buf = new Float32Array(this.dw * this.dh * 4);   // RGBA, 0..255 and alpha 0..1
    if (this.ctx) this.ctx.reset();
  }

  getContext(kind) {
    if (kind !== '2d') throw new Error(`mini_canvas: no ${kind} context`);
    this.ctx ??= new Context(this);
    return this.ctx;
  }

  // One source pixel, for drawImage: the top-left device pixel of its block.
  pixel(x, y) {
    if (x < 0 || y < 0 || x >= this._width || y >= this._height) return [0, 0, 0, 0];
    const i = ((y * SS) * this.dw + x * SS) * 4;
    return [this.buf[i], this.buf[i + 1], this.buf[i + 2], this.buf[i + 3]];
  }

  put(image, x0, y0) {
    for (let y = 0; y < image.height; y++) {
      for (let x = 0; x < image.width; x++) {
        const s = (y * image.width + x) * 4;
        const px = x0 + x, py = y0 + y;
        if (px < 0 || py < 0 || px >= this._width || py >= this._height) continue;
        for (let sy = 0; sy < SS; sy++) {
          for (let sx = 0; sx < SS; sx++) {
            const d = ((py * SS + sy) * this.dw + (px * SS + sx)) * 4;
            this.buf[d] = image.data[s]; this.buf[d + 1] = image.data[s + 1];
            this.buf[d + 2] = image.data[s + 2]; this.buf[d + 3] = image.data[s + 3] / 255;
          }
        }
      }
    }
  }

  // Which device pixels the union of the polygons covers, by the nonzero rule.
  coverage(polys) {
    const mask = new Uint8Array(this.dw * this.dh);
    this.scan(polys, (row, xa, xb) => mask.fill(1, row + xa, row + xb + 1));
    return mask;
  }

  fill(polys, paint, alpha, additive, clip) {
    const buf = this.buf, dw = this.dw;
    const constant = Array.isArray(paint);
    const [cr, cg, cb, ca] = constant ? paint : [0, 0, 0, 0];
    if (constant && ca * alpha <= 0) return;
    this.scan(polys, (row, xa, xb) => {
      const y = row / dw;
      for (let x = xa; x <= xb; x++) {
        const i = row + x;
        if (clip && !clip[i]) continue;
        let r = cr, g = cg, b = cb, a = ca;
        if (!constant) { const c = paint(x + 0.5, y + 0.5); r = c[0]; g = c[1]; b = c[2]; a = c[3]; }
        a *= alpha;
        if (a <= 0) continue;
        const d = i * 4;
        if (additive) {
          buf[d] = Math.min(255, buf[d] + r * a);
          buf[d + 1] = Math.min(255, buf[d + 1] + g * a);
          buf[d + 2] = Math.min(255, buf[d + 2] + b * a);
          buf[d + 3] = Math.min(1, buf[d + 3] + a);
        } else {
          const k = 1 - a;
          buf[d] = r * a + buf[d] * k;
          buf[d + 1] = g * a + buf[d + 1] * k;
          buf[d + 2] = b * a + buf[d + 2] * k;
          buf[d + 3] = a + buf[d + 3] * k;
        }
      }
    });
  }

  // Scanline over device pixels whose centres the polygons cover (nonzero),
  // handing each covered run on a row to `span(rowStart, xFirst, xLast)`.
  scan(polys, span) {
    let minY = Infinity, maxY = -Infinity;
    for (const p of polys) for (const v of p) { if (v[1] < minY) minY = v[1]; if (v[1] > maxY) maxY = v[1]; }
    const y0 = Math.max(0, Math.floor(minY)), y1 = Math.min(this.dh - 1, Math.ceil(maxY));
    const xs = [];
    for (let y = y0; y <= y1; y++) {
      const sy = y + 0.5;
      xs.length = 0;
      for (const p of polys) {
        const n = p.length;
        for (let i = 0; i < n; i++) {
          const a = p[i], b = p[(i + 1) % n];
          if ((a[1] <= sy && b[1] > sy) || (b[1] <= sy && a[1] > sy)) {
            xs.push([a[0] + ((sy - a[1]) / (b[1] - a[1])) * (b[0] - a[0]), a[1] < b[1] ? 1 : -1]);
          }
        }
      }
      if (xs.length < 2) continue;
      xs.sort((u, v) => u[0] - v[0]);
      let winding = 0;
      for (let i = 0; i + 1 < xs.length; i++) {
        winding += xs[i][1];
        if (winding === 0) continue;
        const xa = Math.max(0, Math.ceil(xs[i][0] - 0.5));
        const xb = Math.min(this.dw - 1, Math.floor(xs[i + 1][0] - 0.5));
        if (xa <= xb) span(y * this.dw, xa, xb);
      }
    }
  }

  // Box-filter SS x SS down to one pixel and write an opaque RGB PNG.
  toPNG() {
    const W = this._width, H = this._height, n = SS * SS;
    const raw = Buffer.alloc(H * (1 + W * 3));
    for (let y = 0; y < H; y++) {
      const row = y * (1 + W * 3);
      for (let x = 0; x < W; x++) {
        let r = 0, g = 0, b = 0;
        for (let sy = 0; sy < SS; sy++) {
          for (let sx = 0; sx < SS; sx++) {
            const i = ((y * SS + sy) * this.dw + (x * SS + sx)) * 4;
            r += this.buf[i]; g += this.buf[i + 1]; b += this.buf[i + 2];
          }
        }
        const o = row + 1 + x * 3;
        raw[o] = Math.round(r / n); raw[o + 1] = Math.round(g / n); raw[o + 2] = Math.round(b / n);
      }
    }
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4);
    ihdr[8] = 8; ihdr[9] = 2;   // 8-bit RGB
    return Buffer.concat([
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
    ]);
  }
}

// ── PNG chunks ─────────────────────────────────────────────────────────────

const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const name = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([name, data])), 0);
  return Buffer.concat([len, name, data, crc]);
}

export const createCanvas = (width = 300, height = 150) => new Canvas(width, height);
