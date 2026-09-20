// shapewire — ShapeWire.roc's layout, read back and painted onto a canvas.
//
// Everything about a FRAME lives here and nothing about running a game does:
// no clock, no keyboard, no speaker. Decoding is pure — it walks the words and
// answers plain descriptors — and painting is a fold over those.
//
// It answers one name, `ShapeWire`, with `decode` and `paint`.

// ── the wire ───────────────────────────────────────────────────────────────
// ShapeWire.roc's layout, read back. Decoding is pure: it walks the words and
// answers plain descriptors, and nothing here touches a canvas.

const SHAPE = { POLY: 0, DISC: 1, RECT: 2, BLEND: 3, VIEW: 4, IMAGE: 5 };
const FILL = { FLAT: 0, SPAN: 1, RADIAL: 2, LINEAR: 3, ELLIPSE: 4, GLOW: 5 };

const channel = (byte) => Math.max(0, Math.min(255, Math.round(byte)));
const cssColor = (rgb, alpha) =>
  `rgba(${channel(rgb >>> 16)},${channel((rgb >>> 8) & 255)},${channel(rgb & 255)},${alpha})`;

// Each reader takes the two views and a word index, and answers [value, next].
const readColor = (words, floats, at) => [cssColor(words[at], floats[at + 1]), at + 2];

const readFloats = (floats, at, count) =>
  [Array.from({ length: count }, (_, i) => floats[at + i]), at + count];

function readFill(words, floats, at) {
  const mode = words[at];
  const [first, afterFirst] = readColor(words, floats, at + 1);
  if (mode === FILL.FLAT) return [{ mode, colors: [first] }, afterFirst];

  const [second, afterSecond] = readColor(words, floats, afterFirst);
  if (mode === FILL.GLOW) {
    const [third, afterThird] = readColor(words, floats, afterSecond);
    const [geometry, next] = readFloats(floats, afterThird, 4);
    return [{ mode, colors: [first, second, third], geometry }, next];
  }
  const spans = { [FILL.SPAN]: 2, [FILL.RADIAL]: 4, [FILL.LINEAR]: 6, [FILL.ELLIPSE]: 8 };
  if (!(mode in spans)) throw new Error(`shapewire: no brush mode ${mode}`);
  const [geometry, next] = readFloats(floats, afterSecond, spans[mode]);
  return [{ mode, colors: [first, second], geometry }, next];
}

function readShape(words, floats, at) {
  const kind = words[at];
  if (kind === SHAPE.BLEND) return [{ kind, additive: words[at + 1] === 1 }, at + 2];
  // A space is a word saying which, and the camera's four settings if it is
  // not the screen. `null` is the screen, which is where a frame starts.
  if (kind === SHAPE.VIEW) {
    if (!words[at + 1]) return [{ kind, space: null }, at + 2];
    const [space, next] = readFloats(floats, at + 2, 6);
    return [{ kind, space }, next];
  }
  // A picture: how many cells each way, where it goes, and then one word a
  // pixel. **THE PIXELS ARE COPIED OUT**, by `slice` rather than `subarray`:
  // a view into the frame is a view into wasm memory, which the next step
  // overwrites, so anything that held one would be reading the frame after
  // this one. Decoding answers values everywhere else and it answers a value
  // here; a memcpy of a few hundred words is not what to save.
  if (kind === SHAPE.IMAGE) {
    const cols = words[at + 1];
    const rows = words[at + 2];
    const [box, afterBox] = readFloats(floats, at + 3, 4);
    const next = afterBox + cols * rows;
    return [{ kind, cols, rows, box, pixels: words.slice(afterBox, next) }, next];
  }

  const [fill, afterFill] = readFill(words, floats, at + 1);
  if (kind === SHAPE.POLY) {
    const corners = words[afterFill];
    const [points, next] = readFloats(floats, afterFill + 1, corners * 2);
    return [{ kind, fill, points }, next];
  }
  if (kind === SHAPE.RECT) {
    const [box, next] = readFloats(floats, afterFill, 4);
    return [{ kind, fill, box }, next];
  }
  if (kind !== SHAPE.DISC) throw new Error(`shapewire: no shape kind ${kind}`);
  const [disc, afterDisc] = readFloats(floats, afterFill, 3);
  if (!words[afterDisc]) return [{ kind, fill, disc }, afterDisc + 1];
  const [clip, next] = readFloats(floats, afterDisc + 1, 4);
  return [{ kind, fill, disc, clip }, next];
}

// The whole frame, as descriptors, in the order it is painted.
function decodeFrame(memory, base, bytes) {
  const words = new Uint32Array(memory.buffer, base, bytes / 4);
  const floats = new Float32Array(memory.buffer, base, bytes / 4);
  const shapes = [];
  let at = 0;
  while (at < words.length) {
    const [shape, next] = readShape(words, floats, at);
    shapes.push(shape);
    at = next;
  }
  // A frame that does not end exactly on its last word was misread, and a
  // misread frame used to come out short and silent.
  if (at !== words.length) throw new Error(`shapewire: read ${at} of ${words.length} words`);
  return shapes;
}

// ── paints ─────────────────────────────────────────────────────────────────
// A fill descriptor becomes something canvas can paint with. An ellipse is the
// exception: it paints through a transform, so it stays a descriptor.

const stopAt = (offset, floor = 0) => Math.max(floor, Math.min(1, offset));

function paintFor(ctx, { mode, colors, geometry }) {
  const [a, b, c] = colors;
  if (mode === FILL.FLAT) return a;

  if (mode === FILL.SPAN) {
    const [x0, x1] = geometry;
    return withStops(ctx.createLinearGradient(x0, 0, x1, 0), [[0, a], [0.5, b], [1, a]]);
  }
  if (mode === FILL.RADIAL) {
    const [x, y, r0, r1] = geometry;
    if (!(r1 > r0)) return b;
    return withStops(ctx.createRadialGradient(x, y, r0, x, y, r1), [[0, a], [1, b]]);
  }
  if (mode === FILL.LINEAR) {
    const [o0, o1, ax, ay, dx, dy] = geometry;
    const gradient = ctx.createLinearGradient(ax, ay, ax + dx, ay + dy);
    return withStops(gradient, [[stopAt(o0), a], [stopAt(o1, stopAt(o0)), b]]);
  }
  if (mode === FILL.GLOW) {
    const [x, y, r0, r1] = geometry;
    // Brush.shade and BrushGlsl both end at c2 when there is no ring to walk.
    if (!(r1 > r0)) return c;
    return withStops(ctx.createRadialGradient(x, y, r0, x, y, r1), [[0, a], [0.4, b], [1, c]]);
  }
  if (mode !== FILL.ELLIPSE) throw new Error(`shapewire: no brush mode ${mode}`);
  return { ellipse: geometry, colors };
}

const withStops = (gradient, stops) => {
  stops.forEach(([offset, color]) => gradient.addColorStop(offset, color));
  return gradient;
};

// ── painting ───────────────────────────────────────────────────────────────

function tracePath(ctx, shape) {
  ctx.beginPath();
  if (shape.kind === SHAPE.POLY) {
    const [x0, y0, ...rest] = shape.points;
    ctx.moveTo(x0, y0);
    for (let i = 0; i < rest.length; i += 2) ctx.lineTo(rest[i], rest[i + 1]);
  } else if (shape.kind === SHAPE.RECT) {
    ctx.rect(...shape.box);
  } else {
    const [x, y, r] = shape.disc;
    ctx.arc(x, y, r, 0, Math.PI * 2);
  }
  ctx.closePath();
}

// An ellipse brush carries the matrix that takes a scene offset TO the unit
// circle; a canvas wants the one that goes the other way, so it is inverted.
function fillThroughEllipse(ctx, { ellipse, colors }) {
  const [o0, o1, x, y, ia, ib, ic, id] = ellipse;
  const det = ia * id - ib * ic;
  if (Math.abs(det) < 1e-4) { ctx.fillStyle = colors[0]; ctx.fill(); return; }
  ctx.save();
  ctx.clip();
  ctx.transform(id / det, -ic / det, -ib / det, ia / det, x, y);
  const gradient = withStops(ctx.createRadialGradient(0, 0, 0, 0, 0, 1),
    [[stopAt(o0), colors[0]], [stopAt(o1, stopAt(o0)), colors[1]]]);
  ctx.fillStyle = gradient;
  ctx.fillRect(-1e4, -1e4, 2e4, 2e4); // clipped to the path; past r=1 the gradient holds
  ctx.restore();
}

function fillShape(ctx, shape) {
  const paint = paintFor(ctx, shape.fill);
  if (paint.ellipse) fillThroughEllipse(ctx, paint);
  else { ctx.fillStyle = paint; ctx.fill(); }
}

// Where the shapes after a view mark are: the camera written as the matrix a
// canvas takes. `screen = zoom · R(rotation) · (world − target) + offset`, which
// is what Camera.world_to_screen does in Roc and BeginMode2D does in raylib.
function setSpace(ctx, space) {
  if (!space) { ctx.setTransform(1, 0, 0, 1, 0, 0); return; }
  const [tx, ty, ox, oy, rotation, zoom] = space;
  const radians = (rotation * Math.PI) / 180;
  const cos = Math.cos(radians) * zoom;
  const sin = Math.sin(radians) * zoom;
  ctx.setTransform(cos, sin, -sin, cos, ox - (tx * cos - ty * sin), oy - (tx * sin + ty * cos));
}

// A picture is drawn through a scratch canvas of its own size and then
// stretched with smoothing off, which is what nearest-neighbour is on a canvas.
// One scratch canvas is kept and resized, because a frame may hold several and
// a new canvas per picture per frame is a new canvas sixty times a second.
const scratch = { canvas: null, ctx: null };

function paintImage(ctx, { cols, rows, box, pixels }) {
  if (!cols || !rows) return;
  if (!scratch.canvas) {
    scratch.canvas = document.createElement('canvas');
    scratch.ctx = scratch.canvas.getContext('2d');
  }
  if (scratch.canvas.width !== cols || scratch.canvas.height !== rows) {
    scratch.canvas.width = cols;
    scratch.canvas.height = rows;
  }
  const image = scratch.ctx.createImageData(cols, rows);
  const bytes = image.data;
  // The wire packs a pixel as 0xAARRGGBB; ImageData wants the four bytes in
  // the other order, and writing them one at a time says which is which.
  for (let i = 0; i < cols * rows; i++) {
    const pixel = pixels[i];
    bytes[i * 4] = (pixel >>> 16) & 255;
    bytes[i * 4 + 1] = (pixel >>> 8) & 255;
    bytes[i * 4 + 2] = pixel & 255;
    bytes[i * 4 + 3] = (pixel >>> 24) & 255;
  }
  scratch.ctx.putImageData(image, 0, 0);
  const smoothing = ctx.imageSmoothingEnabled;
  ctx.imageSmoothingEnabled = false;
  // drawImage goes through the current transform, so a picture inside a view
  // scope lands in the world like everything else.
  ctx.drawImage(scratch.canvas, 0, 0, cols, rows, box[0], box[1], box[2], box[3]);
  ctx.imageSmoothingEnabled = smoothing;
}

function paintFrame(ctx, shapes) {
  for (const shape of shapes) {
    // A blend mark is not a shape: it says how the shapes after it combine.
    if (shape.kind === SHAPE.BLEND) {
      ctx.globalCompositeOperation = shape.additive ? 'lighter' : 'source-over';
      continue;
    }
    // Nor is a view mark: it says where they are.
    if (shape.kind === SHAPE.VIEW) {
      setSpace(ctx, shape.space);
      continue;
    }
    // A picture is not a path, so it is not traced and filled.
    if (shape.kind === SHAPE.IMAGE) {
      paintImage(ctx, shape);
      continue;
    }
    if (shape.clip) {
      ctx.save();
      ctx.beginPath();
      ctx.rect(...shape.clip);
      ctx.clip();
      tracePath(ctx, shape);
      fillShape(ctx, shape);
      ctx.restore();
      continue;
    }
    tracePath(ctx, shape);
    fillShape(ctx, shape);
  }
  ctx.globalCompositeOperation = 'source-over';
  // A frame leaves the canvas as it found it, so whatever the page draws next
  // — the speaker, the next frame — is in the page's own pixels.
  ctx.setTransform(1, 0, 0, 1, 0, 0);
}

const ShapeWire = { decode: decodeFrame, paint: paintFrame };
