// mini_font reads the outlines of letters out of a TrueType file, so that
// mini_canvas can set a line of type the way a browser does.
//
// A browser picks the first face of a stack that its machine has. This picks a
// face that stands in for the stack's generic family, from fonts on this
// machine, so a shot shows type of about the size and color the viewer gets, but
// not their exact letters. It reads what those files use, and a file it can't
// read, or a letter the face lacks, stops the shot.
import { readFileSync } from 'node:fs';

const STAND_INS = {
  'sans-serif': '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
  monospace: '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
};

const CURVE_STEPS = 6;

// A composite glyph's flags, from the `glyf` table's format.
const WORDS = 1, SCALE = 8, MORE = 32, XY_SCALE = 64, TWO_BY_TWO = 128;

class TrueType {
  constructor(path) {
    const file = readFileSync(path);
    this.view = new DataView(file.buffer, file.byteOffset, file.byteLength);
    this.tables = {};
    const count = this.view.getUint16(4);
    for (let i = 0; i < count; i++) {
      const at = 12 + i * 16;
      this.tables[file.toString('latin1', at, at + 4)] = this.view.getUint32(at + 8);
    }
    for (const name of ['cmap', 'glyf', 'head', 'hhea', 'hmtx', 'loca']) {
      if (!(name in this.tables)) throw new Error(`mini_font: ${path} has no ${name} table`);
    }
    this.path = path;
    this.unitsPerEm = this.view.getUint16(this.tables.head + 18);
    this.longOffsets = this.view.getInt16(this.tables.head + 50) === 1;
    this.metrics = this.view.getUint16(this.tables.hhea + 34);
    this.cmap = this.unicodeSubtable();
  }

  // The format 4 subtable, which covers the Basic Multilingual Plane.
  unicodeSubtable() {
    const v = this.view, base = this.tables.cmap;
    const count = v.getUint16(base + 2);
    for (let i = 0; i < count; i++) {
      const at = base + v.getUint32(base + 8 + i * 8);
      if (v.getUint16(at) === 4) return at;
    }
    throw new Error(`mini_font: ${this.path} has no format 4 cmap`);
  }

  glyphOf(codePoint) {
    const v = this.view, at = this.cmap;
    const twice = v.getUint16(at + 6);
    const ends = at + 14, starts = ends + twice + 2, deltas = starts + twice, offsets = deltas + twice;
    for (let i = 0; i < twice; i += 2) {
      if (codePoint > v.getUint16(ends + i)) continue;
      const first = v.getUint16(starts + i);
      if (codePoint < first) break;
      const delta = v.getUint16(deltas + i), offset = v.getUint16(offsets + i);
      if (offset === 0) return (codePoint + delta) & 0xffff;
      const glyph = v.getUint16(offsets + i + offset + (codePoint - first) * 2);
      if (glyph !== 0) return (glyph + delta) & 0xffff;
      break;
    }
    throw new Error(`mini_font: ${this.path} has no letter U+${codePoint.toString(16)}`);
  }

  advanceOf(glyph) {
    return this.view.getUint16(this.tables.hmtx + Math.min(glyph, this.metrics - 1) * 4);
  }

  // Where a glyph's record is, or null for one with no outline, like a space.
  recordOf(glyph) {
    const v = this.view, loca = this.tables.loca;
    const start = this.longOffsets ? v.getUint32(loca + glyph * 4) : v.getUint16(loca + glyph * 2) * 2;
    const end = this.longOffsets ? v.getUint32(loca + glyph * 4 + 4) : v.getUint16(loca + glyph * 2 + 2) * 2;
    return start === end ? null : this.tables.glyf + start;
  }

  // A glyph's contours in font units, y up: lists of { x, y, on }.
  contoursOf(glyph) {
    const at = this.recordOf(glyph);
    if (at === null) return [];
    const contours = this.view.getInt16(at);
    return contours >= 0 ? this.simple(at + 10, contours) : this.composite(at + 10);
  }

  simple(start, contours) {
    const v = this.view;
    let at = start;
    const lastPoints = [];
    for (let i = 0; i < contours; i++, at += 2) lastPoints.push(v.getUint16(at));
    const count = contours ? lastPoints[contours - 1] + 1 : 0;
    at += 2 + v.getUint16(at);
    const flags = [];
    while (flags.length < count) {
      const flag = v.getUint8(at++);
      flags.push(flag);
      if (flag & 8) for (let n = v.getUint8(at++); n > 0; n--) flags.push(flag);
    }
    // A coordinate is a change from the last one: a byte with its sign in a
    // flag, or else a word, or nothing when the flag says it is the same.
    const readAxis = (short, same) => {
      const values = [];
      let value = 0;
      for (const flag of flags) {
        if (flag & short) { const d = v.getUint8(at++); value += flag & same ? d : -d; }
        else if (!(flag & same)) { value += v.getInt16(at); at += 2; }
        values.push(value);
      }
      return values;
    };
    const xs = readAxis(2, 16);
    const ys = readAxis(4, 32);
    const out = [];
    let first = 0;
    for (const last of lastPoints) {
      const contour = [];
      for (let i = first; i <= last; i++) contour.push({ x: xs[i], y: ys[i], on: (flags[i] & 1) === 1 });
      out.push(contour);
      first = last + 1;
    }
    return out;
  }

  composite(start) {
    const v = this.view;
    const out = [];
    let at = start, flags;
    do {
      flags = v.getUint16(at);
      const part = v.getUint16(at + 2);
      at += 4;
      const dx = flags & WORDS ? v.getInt16(at) : v.getInt8(at);
      const dy = flags & WORDS ? v.getInt16(at + 2) : v.getInt8(at + 1);
      at += flags & WORDS ? 4 : 2;
      if (flags & (SCALE | XY_SCALE | TWO_BY_TWO)) throw new Error(`mini_font: ${this.path} scales a glyph's part`);
      for (const contour of this.contoursOf(part)) {
        out.push(contour.map((p) => ({ ...p, x: p.x + dx, y: p.y + dy })));
      }
    } while (flags & MORE);
    return out;
  }
}

// One contour as straight lines. Two curve points in a row have an unwritten
// point on the curve halfway between them.
function flatten(contour) {
  const points = [];
  contour.forEach((p, i) => {
    const next = contour[(i + 1) % contour.length];
    points.push(p);
    if (!p.on && !next.on) points.push({ x: (p.x + next.x) / 2, y: (p.y + next.y) / 2, on: true });
  });
  const start = points.findIndex((p) => p.on);
  const ring = [...points.slice(start), ...points.slice(0, start)];
  const out = [];
  ring.forEach((p, i) => {
    if (!p.on) return;
    out.push([p.x, p.y]);
    const control = ring[(i + 1) % ring.length];
    if (control.on) return;
    const end = ring[(i + 2) % ring.length];
    for (let step = 1; step < CURVE_STEPS; step++) {
      const t = step / CURVE_STEPS, u = 1 - t;
      out.push([u * u * p.x + 2 * u * t * control.x + t * t * end.x, u * u * p.y + 2 * u * t * control.y + t * t * end.y]);
    }
  });
  return out;
}

const fonts = new Map();

function fontFor(path) {
  if (!fonts.has(path)) fonts.set(path, new TrueType(path));
  return fonts.get(path);
}

// What a canvas's `font` string asks for: a size in pixels, then a stack.
export function faceOf(fontText) {
  const asked = fontText.match(/^([0-9.]+)px (.+)$/);
  if (!asked) throw new Error(`mini_font: cannot read the font ${fontText}`);
  const generic = asked[2].split(',').pop().trim();
  if (!(generic in STAND_INS)) throw new Error(`mini_font: no face for ${generic}`);
  const font = fontFor(STAND_INS[generic]);
  const scale = Number(asked[1]) / font.unitsPerEm;
  return {
    // Contours of [x, y] in pixels, y down, from the line's left end on its
    // baseline, and the line's width.
    outline(text) {
      const contours = [];
      let pen = 0;
      for (const letter of text) {
        const glyph = font.glyphOf(letter.codePointAt(0));
        for (const contour of font.contoursOf(glyph)) {
          contours.push(flatten(contour).map(([x, y]) => [pen + x * scale, -y * scale]));
        }
        pen += font.advanceOf(glyph) * scale;
      }
      return { contours, width: pen };
    },
  };
}
