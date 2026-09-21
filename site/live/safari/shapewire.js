// shapewire — painting a frame onto a canvas.
//
// EXPERIMENT: the decoder that used to be the first half of this file is GONE.
// The platform declares `frame : Box(model) -> List(Frame.Shape)`, so the
// compiler's own type table carries the vocabulary and `roc_glue.js` — which
// `roc glue` generates from it — reads a frame. What is left here is what a
// canvas does with one, which no generator can know.
//
// It answers one name, `ShapeWire`, with `paint`.

const stopAt = (offset, floor = 0) => Math.max(floor, Math.min(1, offset));
const channel = (v) => Math.max(0, Math.min(255, Math.round(v)));
const cssColor = (c) => `rgba(${channel(c.r)},${channel(c.g)},${channel(c.b)},${c.a})`;

const withStops = (gradient, stops) => {
  stops.forEach(([offset, color]) => gradient.addColorStop(offset, color));
  return gradient;
};

// A fill becomes something canvas can paint with. An ellipse is the exception:
// it paints through a transform, so it stays a descriptor.
function paintFor(ctx, fill) {
  const p = fill.value;
  switch (fill.tag) {
    case "Skip":
      return null;
    case "Flat":
      return cssColor(p);
    case "Span":
      return withStops(ctx.createLinearGradient(p.x0, 0, p.x1, 0),
        [[0, cssColor(p.edge)], [0.5, cssColor(p.middle)], [1, cssColor(p.edge)]]);
    case "Radial":
      if (!(p.r1 > p.r0)) return cssColor(p.outer);
      return withStops(ctx.createRadialGradient(p.x, p.y, p.r0, p.x, p.y, p.r1),
        [[0, cssColor(p.inner)], [1, cssColor(p.outer)]]);
    case "Linear":
      return withStops(ctx.createLinearGradient(p.ax, p.ay, p.ax + p.dx, p.ay + p.dy),
        [[stopAt(p.o0), cssColor(p.c0)], [stopAt(p.o1, stopAt(p.o0)), cssColor(p.c1)]]);
    case "Glow":
      // Brush.shade and BrushGlsl both end at c2 when there is no ring to walk.
      if (!(p.r1 > p.r0)) return cssColor(p.c2);
      return withStops(ctx.createRadialGradient(p.x, p.y, p.r0, p.x, p.y, p.r1),
        [[0, cssColor(p.c0)], [0.4, cssColor(p.c1)], [1, cssColor(p.c2)]]);
    case "Ellipse":
      return { ellipse: p };
    default:
      throw new Error(`shapewire: no brush ${fill.tag}`);
  }
}

// An ellipse brush carries the matrix that takes a scene offset TO the unit
// circle; a canvas wants the one that goes the other way, so it is inverted.
function fillThroughEllipse(ctx, p) {
  const det = p.ia * p.id - p.ib * p.ic;
  if (Math.abs(det) < 1e-4) { ctx.fillStyle = cssColor(p.c0); ctx.fill(); return; }
  ctx.save();
  ctx.clip();
  ctx.transform(p.id / det, -p.ic / det, -p.ib / det, p.ia / det, p.x, p.y);
  ctx.fillStyle = withStops(ctx.createRadialGradient(0, 0, 0, 0, 0, 1),
    [[stopAt(p.o0), cssColor(p.c0)], [stopAt(p.o1, stopAt(p.o0)), cssColor(p.c1)]]);
  ctx.fillRect(-1e4, -1e4, 2e4, 2e4); // clipped to the path; past r=1 the gradient holds
  ctx.restore();
}

function fillShape(ctx, fill) {
  const paint = paintFor(ctx, fill);
  if (paint === null) return;
  if (paint.ellipse) fillThroughEllipse(ctx, paint.ellipse);
  else { ctx.fillStyle = paint; ctx.fill(); }
}

function tracePoly(ctx, pts) {
  ctx.beginPath();
  ctx.moveTo(pts[0], pts[1]);
  for (let i = 2; i < pts.length; i += 2) ctx.lineTo(pts[i], pts[i + 1]);
  ctx.closePath();
}

// Where the shapes after a view mark are: the camera written as the matrix a
// canvas takes. Camera.world_to_screen does this in Roc, BeginMode2D in raylib.
function setSpace(ctx, space) {
  if (space.tag === "Screen") { ctx.setTransform(1, 0, 0, 1, 0, 0); return; }
  const c = space.value;
  const radians = (c.rotation * Math.PI) / 180;
  const cos = Math.cos(radians) * c.zoom;
  const sin = Math.sin(radians) * c.zoom;
  ctx.setTransform(cos, sin, -sin, cos,
    c.offset.x - (c.target.x * cos - c.target.y * sin),
    c.offset.y - (c.target.x * sin + c.target.y * cos));
}

const scratch = { canvas: null, ctx: null };

function paintImage(ctx, p) {
  if (!p.cols || !p.rows) return;
  if (!scratch.canvas) {
    scratch.canvas = document.createElement('canvas');
    scratch.ctx = scratch.canvas.getContext('2d');
  }
  if (scratch.canvas.width !== p.cols || scratch.canvas.height !== p.rows) {
    scratch.canvas.width = Number(p.cols);
    scratch.canvas.height = Number(p.rows);
  }
  const image = scratch.ctx.createImageData(Number(p.cols), Number(p.rows));
  const bytes = image.data;
  for (let i = 0; i < p.pixels.length; i++) {
    const c = p.pixels[i];
    bytes[i * 4] = channel(c.r);
    bytes[i * 4 + 1] = channel(c.g);
    bytes[i * 4 + 2] = channel(c.b);
    bytes[i * 4 + 3] = channel(c.a * 255);
  }
  scratch.ctx.putImageData(image, 0, 0);
  const smoothing = ctx.imageSmoothingEnabled;
  ctx.imageSmoothingEnabled = false;
  ctx.drawImage(scratch.canvas, 0, 0, Number(p.cols), Number(p.rows), p.x, p.y, p.w, p.h);
  ctx.imageSmoothingEnabled = smoothing;
}

function paintFrame(ctx, shapes) {
  for (const shape of shapes) {
    const p = shape.value;
    switch (shape.tag) {
      // The two marks are not shapes: one says how the shapes after it
      // combine, the other says where they are.
      case "Blend":
        ctx.globalCompositeOperation = p.tag === "Add" ? 'lighter' : 'source-over';
        break;
      case "View":
        setSpace(ctx, p);
        break;
      case "Image":
        paintImage(ctx, p);
        break;
      case "Poly":
        tracePoly(ctx, p.pts);
        fillShape(ctx, p.fill);
        break;
      case "Rect":
        ctx.beginPath();
        ctx.rect(p.x, p.y, p.w, p.h);
        ctx.closePath();
        fillShape(ctx, p.fill);
        break;
      case "Disc":
        if (p.clip.tag === "Within") {
          const r = p.clip.value;
          ctx.save();
          ctx.beginPath();
          ctx.rect(r.x, r.y, r.w, r.h);
          ctx.clip();
        }
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.closePath();
        fillShape(ctx, p.fill);
        if (p.clip.tag === "Within") ctx.restore();
        break;
      default:
        throw new Error(`shapewire: a page is never sent ${shape.tag}`);
    }
  }
  ctx.globalCompositeOperation = 'source-over';
  ctx.setTransform(1, 0, 0, 1, 0, 0);
}

const ShapeWire = { paint: paintFrame };
