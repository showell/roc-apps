// blitter — the browser half of the arcade. It loads a game's wasm, runs the
// event loop, and paints the shapes the game answers with.
//
// **THE GAME IS THE SAME ROC THAT RUNS NATIVELY.** What differs is only what is
// in this file: the keyboard, the clock, and the speaker. roc-ray's own player
// does the same three things in a window; neither knows what game it is running.
//
// THE LINE THIS FILE IS ORGANISED AROUND. Three kinds of thing live here and
// they are not the same kind:
//
//   1. CANVAS BACKEND. A vocabulary of paths and paints with no idea what it is
//      drawing — polygons, discs, rectangles, and the six brushes.
//   2. THE FRAME VOCABULARY. What a shape looks like on the wire, which is
//      ShapeWire.roc's layout read back.
//   3. THE PAGE. The loop, the keys, and the sound widget.
//
// Everything above section 4 is shared with the movies' blitter, because
// filling a polygon is the same job either way; everything below it is the
// arcade's own, because a movie has no keyboard and a game is not scrubbed.

// ── 1. CANVAS BACKEND ─────────────────────────────────────────────────────────
// Paths, paints and CSS colour strings. This is the half that cannot move: it is
// the shape of the canvas API and nothing else. There are no trucks here.

// 0xRRGGBB -> "#rrggbb". SHELL.
function hex(c) {
  return '#' + (c & 0xffffff).toString(16).padStart(6, '0');
}

// 0xRRGGBB -> "rgb(r,g,b)". SHELL.
function rgbCss(c) {
  return `rgb(${(c >> 16) & 255},${(c >> 8) & 255},${c & 255})`;
}

// 0xAARRGGBB -> "rgba(r,g,b,a)". SHELL.
function rgba(c) {
  return `rgba(${(c >> 16) & 255},${(c >> 8) & 255},${c & 255},${((c >>> 24) & 255) / 255})`;
}

// clamp a gradient stop offset to [0,1], and to >= a lower bound so a 2-stop pair
// stays ascending. A canvas rule: `addColorStop` throws outside [0,1] and ignores
// order. SHELL.
function stopAt(o, lo = 0) { return Math.max(lo, Math.min(1, o)); }

// Trace an n-point polygon starting at word `w`. Returns the word after it.
function polyPath(ctx, f32, w, n) {
  ctx.beginPath();
  ctx.moveTo(f32[w], f32[w + 1]); w += 2;
  for (let i = 1; i < n; i++) { ctx.lineTo(f32[w], f32[w + 1]); w += 2; }
  ctx.closePath();
  return w;
}

// A two-stop linear gradient between two points, in 0xAARRGGBB.
function linearPaint(ctx, ax, ay, bx, by, c0, o0, c1, o1) {
  const g = ctx.createLinearGradient(ax, ay, bx, by);
  g.addColorStop(stopAt(o0), rgba(c0));
  g.addColorStop(stopAt(o1, o0), rgba(c1));
  return g;
}

// A two-stop radial gradient from a centre out to a radius, in 0xAARRGGBB.
function radialPaint(ctx, cx, cy, r, cCol, eCol) {
  const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
  g.addColorStop(0, rgba(cCol));
  g.addColorStop(1, rgba(eCol));
  return g;
}

// A gradient across a span, from stops given as [offset, 0xRRGGBB] pairs.
function stopsPaint(ctx, x0, x1, stops) {
  const g = ctx.createLinearGradient(x0, 0, x1, 0);
  for (const [at, col] of stops) g.addColorStop(at, rgbCss(col));
  return g;
}

// Fill the CURRENT path with a unit radial gradient mapped onto the ellipse that
// (u, v) spans at (cx, cy). Answers false when the matrix is degenerate and the
// caller should fall back to a flat fill -- a canvas fact, not a scene one.
function fillEllipseRadial(ctx, cx, cy, ux, uy, vx, vy, c0, o0, c1, o1) {
  if (Math.abs(ux * vy - uy * vx) < DEGENERATE_DET) return false;
  ctx.save();
  ctx.clip();
  ctx.transform(ux, uy, vx, vy, cx, cy); // unit space -> screen ellipse
  const g = ctx.createRadialGradient(0, 0, 0, 0, 0, 1);
  g.addColorStop(stopAt(o0), rgba(c0));
  g.addColorStop(stopAt(o1, o0), rgba(c1));
  ctx.fillStyle = g;
  ctx.fillRect(-1e4, -1e4, 2e4, 2e4); // clipped to the path; beyond r=1 the gradient clamps to stop 1
  ctx.restore();
  return true;
}

// A filled disc at a composited alpha.
function fillDisc(ctx, x, y, r, color, alpha) {
  ctx.globalAlpha = alpha;
  ctx.fillStyle = hex(color);
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalAlpha = 1;
}

// ── 2. THE FRAME VOCABULARY ────────────────────────────────────────────────────
// What a frame IS: an ordered list of geometric objects, each a polygon or a disc,
// each with a paint. Nothing here is about safari -- a different show emitting the
// same tags renders with this file untouched.
//
// Nothing in it decides anything: every number a command carries was computed by
// the guest, and this file's whole job is to turn tags into paths and paints.

// What arrives, so the dispatch below can be read without a legend. A frame is
// SHAPES, each with a BRUSH, and neither names a subject: this file fills a
// polygon under a radial gradient; it does not paint a headlight.
//
// THE TAG LIST THAT USED TO BE HERE IS GONE. It named a shape and a paint
// together -- SPAN_SHADE, RADIAL_POLY, ELLIPSE_POLY -- so every new pairing
// needed a new tag, and the sun could not be said at all: its glow is three
// colours and the tags carried two, which is why the page used to paint the sky
// and the sun itself from six extra exports. A shape and a brush are two words
// now, and a movie this file has never heard of can say anything the brush
// vocabulary can.
const KIND = { POLY: 0, DISC: 1, RECT: 2 };
const MODE = { FLAT: 0, SPAN: 1, RADIAL: 2, LINEAR: 3, ELLIPSE: 4, GLOW: 5 };

// The one threshold left, and it is a canvas fact rather than a scene one: a
// singular matrix cannot be inverted. The four that were chosen by eye -- the disc
// radius and alpha floors, the radial radius floor, the flat-fill width -- are
// `port/Blit.codex`'s now, and a command that fails one never reaches this file.
const DEGENERATE_DET = 1e-4;

// ── 2a. THE SHOW ───────────────────────────────────────────────────────────────
// A page says which game to fetch and what to tell the player; everything else
// here is about running one, not about which.
//
//   window.SHOW = {
//     wasm: 'snake.wasm',         the module to fetch
//     hint: '…',                  the key legend
//     loading: '…',               what to say while the wasm arrives
//   };

// ── 2b. THE GUEST BOUNDARY ─────────────────────────────────────────────────────
// The ONE place the guest's own names are allowed.
//
// The guest names its exports for the game it is: `riderTilt`, `riderSeg`,
// `sunVisible`. Those are good names there and bad ones here -- a renderer that
// says `riderSeg` has learned that the thing being driven is a rider, and once a
// name like that reaches `draw()` it has to be threaded through every function it
// touches. Binding them once, here, means the rest of the file speaks about a
// scene: how far it has stepped, which segment it is in, how the camera is rolled.
//
// It is also where a change to the guest gets caught. A renamed export breaks one
// object literal instead of six call sites, and the destructure below fails loudly
// if the export is gone.
function bindScene(x) {
  // **THE MOVIE'S OWN WORDS.** These were forward/backward/step/segment, which
  // were four second names for advance/back/clock/scene and four things to keep
  // straight between here, WasmApp.roc and Movie.roc.
  return {
    memory: x.memory,
    render: x.renderFrame,          // compute a frame; answers its byte length
    advance: x.advance,             // one step, given (held, struck)
    sounds: x.sounds,               // a bit per tone the last step set off
    width: x.width,                 // how big a frame is, in the game's coordinates
    height: x.height,
    fps: x.fps,                     // how often the game means to be stepped
    bufferAt: x.bufPtr,
    bufferPeak: x.bufHighWater,
    bufferCapacity: x.bufCap,
  };
}


// ── 3. THE COMMAND STREAM ──────────────────────────────────────────────────────

// Walk the draw buffer [base, base+len). Views over the SAME words: u32 for
// tag/color/count, f32 for coordinate bit patterns. The critters used to be tag-2
// emoji glyphs the browser font rasterised; they are now baked to tag-0 polygons
// (emoji_frames.zig), so this draws no glyphs -- polygons, gradients and one disc.
//
// This function DECODES and PAINTS, and that is now all it does: there is not one
// comparison against a threshold left in it, because the guest already made every
// call this file used to make about what is worth drawing.
function css(rgb, a) {
  return `rgba(${(rgb >> 16) & 255},${(rgb >> 8) & 255},${rgb & 255},${a})`;
}

// A colour: 0xRRGGBB, then its alpha. Two words.
function readColor(u32, f32, w) {
  return { css: css(u32[w], f32[w + 1]), w: w + 2 };
}

// A brush: its mode, then the colours and geometry that mode wants. Answers
// something that can paint, and the word after it.
function readBrush(ctx, u32, f32, w) {
  const mode = u32[w++];
  const a = readColor(u32, f32, w); w = a.w;
  if (mode === MODE.FLAT) return { paint: a.css, w };

  const b = readColor(u32, f32, w); w = b.w;
  if (mode === MODE.SPAN) {
    const x0 = f32[w++], x1 = f32[w++];
    const g = ctx.createLinearGradient(x0, 0, x1, 0);
    g.addColorStop(0, a.css); g.addColorStop(0.5, b.css); g.addColorStop(1, a.css);
    return { paint: g, w };
  }
  if (mode === MODE.RADIAL) {
    const x = f32[w++], y = f32[w++], r0 = f32[w++], r1 = f32[w++];
    if (!(r1 > r0)) return { paint: b.css, w };
    const g = ctx.createRadialGradient(x, y, r0, x, y, r1);
    g.addColorStop(0, a.css); g.addColorStop(1, b.css);
    return { paint: g, w };
  }
  if (mode === MODE.LINEAR) {
    const o0 = f32[w++], o1 = f32[w++];
    const ax = f32[w++], ay = f32[w++], dx = f32[w++], dy = f32[w++];
    const g = ctx.createLinearGradient(ax, ay, ax + dx, ay + dy);
    g.addColorStop(stopAt(o0), a.css);
    g.addColorStop(stopAt(o1, stopAt(o0)), b.css);
    return { paint: g, w };
  }
  if (mode === MODE.ELLIPSE) {
    const o0 = f32[w++], o1 = f32[w++], x = f32[w++], y = f32[w++];
    // The brush carries the matrix that takes a scene offset TO the unit
    // circle, because that is what shading a point wants. A canvas wants the
    // one that goes the other way, so it is inverted here -- a canvas fact.
    const ia = f32[w++], ib = f32[w++], ic = f32[w++], id = f32[w++];
    return { ellipse: { x, y, ia, ib, ic, id, o0, o1, c0: a.css, c1: b.css }, w };
  }
  // GLOW: three stops, at 0, 0.4 and 1, from r0 out to r1.
  const c = readColor(u32, f32, w); w = c.w;
  const x = f32[w++], y = f32[w++], r0 = f32[w++], r1 = f32[w++];
  if (!(r1 > r0)) return { paint: a.css, w };
  const g = ctx.createRadialGradient(x, y, r0, x, y, r1);
  g.addColorStop(0, a.css); g.addColorStop(0.4, b.css); g.addColorStop(1, c.css);
  return { paint: g, w };
}

// Fill the current path through an ellipse brush, or flat if its matrix is
// singular -- a canvas fact, not a scene one.
function fillThroughEllipse(ctx, e) {
  const det = e.ia * e.id - e.ib * e.ic;
  if (Math.abs(det) < DEGENERATE_DET) { ctx.fillStyle = e.c0; ctx.fill(); return; }
  const ux = e.id / det, uy = -e.ic / det, vx = -e.ib / det, vy = e.ia / det;
  ctx.save();
  ctx.clip();
  ctx.transform(ux, uy, vx, vy, e.x, e.y); // unit space -> screen ellipse
  const g = ctx.createRadialGradient(0, 0, 0, 0, 0, 1);
  g.addColorStop(stopAt(e.o0), e.c0);
  g.addColorStop(stopAt(e.o1, stopAt(e.o0)), e.c1);
  ctx.fillStyle = g;
  ctx.fillRect(-1e4, -1e4, 2e4, 2e4); // clipped to the path; past r=1 the gradient holds
  ctx.restore();
}

// Walk the frame [base, base+len). Views over the SAME words: u32 for kinds,
// modes, counts and colours, f32 for coordinate bit patterns.
//
// This function DECODES and PAINTS, and that is all it does: not one comparison
// against a threshold is left in it, because the movie already made every call
// this file used to make about what is worth drawing.
function blit(ctx, mem, base, len) {
  const u32 = new Uint32Array(mem.buffer, base, len / 4);
  const f32 = new Float32Array(mem.buffer, base, len / 4);
  let w = 0;
  let shapes = 0;
  while (w * 4 < len) {
    shapes++;
    const kind = u32[w++];
    const brush = readBrush(ctx, u32, f32, w); w = brush.w;

    if (kind === KIND.POLY) {
      const n = u32[w++];
      w = polyPath(ctx, f32, w, n);
    } else if (kind === KIND.DISC) {
      const x = f32[w++], y = f32[w++], r = f32[w++];
      ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.closePath();
      // A clip: a rectangle the shape may not paint outside of, or nothing.
      if (u32[w++]) {
        const cx = f32[w++], cy = f32[w++], cw = f32[w++], ch = f32[w++];
        ctx.save();
        ctx.beginPath(); ctx.rect(cx, cy, cw, ch); ctx.clip();
        ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.closePath();
        if (brush.ellipse) fillThroughEllipse(ctx, brush.ellipse);
        else { ctx.fillStyle = brush.paint; ctx.fill(); }
        ctx.restore();
        continue;
      }
    } else {
      const x = f32[w++], y = f32[w++], rw = f32[w++], rh = f32[w++];
      ctx.beginPath(); ctx.rect(x, y, rw, rh); ctx.closePath();
    }

    if (brush.ellipse) fillThroughEllipse(ctx, brush.ellipse);
    else { ctx.fillStyle = brush.paint; ctx.fill(); }
  }
  return shapes;
}

// ── 4. THE KEYBOARD ────────────────────────────────────────────────────────────
// **THE PAGE OWNS THE KEYBOARD AND THE GAME IS TOLD.** Two bit sets go with
// every tick: `held` is every key down right now, `struck` is those that went
// down since the last tick. A game needs both — Snake turns on the edge, and a
// paddle moves while a key is held — so an event alone will not do, and the
// page has to keep the state either way.
//
// The bits are Keys.roc's, in its order. Adding a key is a line here and a tag
// there.
const BIT = {
  ArrowUp: 1, ArrowDown: 2, ArrowLeft: 4, ArrowRight: 8,
  KeyW: 16, KeyA: 32, KeyS: 64, KeyD: 128,
  Space: 256, Escape: 512, Enter: 1024, KeyP: 2048, KeyR: 4096,
};

// ── 5. THE SPEAKER ─────────────────────────────────────────────────────────────
// **THERE IS NO AUDIO HERE YET, AND THE GAME DOES NOT KNOW THAT.** It reports
// that a sound happened, the same as it does natively, where roc-ray plays the
// tone. Here the report lights a widget in the corner, so nothing had to be
// taken out of the game to run it on a page.
const SOUND_MS = 420;
function drawSpeaker(ctx, W, H, lit, now) {
  const age = now - lit.at;
  if (age > SOUND_MS) return;
  const fade = 1 - age / SOUND_MS;
  const x = W - 34, y = H - 30;
  ctx.save();
  ctx.globalAlpha = 0.25 + 0.75 * fade;
  ctx.fillStyle = '#d7e3ff';
  // A speaker: a box and a cone.
  ctx.fillRect(x - 9, y - 4, 5, 8);
  ctx.beginPath();
  ctx.moveTo(x - 4, y - 4); ctx.lineTo(x + 2, y - 9);
  ctx.lineTo(x + 2, y + 9); ctx.lineTo(x - 4, y + 4);
  ctx.closePath(); ctx.fill();
  // One arc per tone that fired, so three sounds look different from one.
  ctx.strokeStyle = '#7ef7d1';
  ctx.lineWidth = 1.5;
  for (let i = 0; i < lit.count; i++) {
    ctx.beginPath();
    ctx.arc(x + 2, y, 6 + i * 4 + (1 - fade) * 6, -0.9, 0.9);
    ctx.stroke();
  }
  ctx.restore();
}

// ── 6. THE PAGE ────────────────────────────────────────────────────────────────
async function main(show) {
  document.body.style.cssText =
    'margin:0;background:#06080f;height:100vh;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;font:13px system-ui,sans-serif;color:#6d7aa8';

  const canvas = document.createElement('canvas');
  canvas.style.cssText = 'background:#06080f;max-width:100%;max-height:88vh;image-rendering:auto';
  const hint = document.createElement('div');
  hint.textContent = show.hint ?? '';
  hint.style.cssText = 'margin-top:10px;letter-spacing:.04em';
  const spinner = document.createElement('div');
  spinner.textContent = show.loading ?? 'Loading…';
  document.body.appendChild(spinner);

  const { instance } = await WebAssembly.instantiateStreaming(fetch(show.wasm), { env: {} });
  const scene = bindScene(instance.exports);
  const W = scene.width(), H = scene.height();
  canvas.width = W; canvas.height = H;
  const ctx = canvas.getContext('2d');

  const held = new Set(), struck = new Set();
  const lit = { at: -1e9, count: 0 };

  function mask(set) { let m = 0; for (const code of set) m |= BIT[code] ?? 0; return m; }

  function step(now) {
    scene.advance(mask(held), mask(struck));
    struck.clear();
    const rung = scene.sounds();
    if (rung) { lit.at = now; lit.count = (rung & 1) + ((rung >> 1) & 1) + ((rung >> 2) & 1); }
  }

  function draw(now) {
    const len = scene.render();
    blit(ctx, scene.memory, scene.bufferAt(), len);
    drawSpeaker(ctx, W, H, lit, now);
  }

  const STEP_MS = 1000 / (scene.fps() || 60);
  const CATCH_UP = 4;
  let owed = 0, last = performance.now(), running = true;

  function loop(now) {
    const since = Math.min(now - last, 250);
    last = now;
    if (running) {
      owed += since;
      let steps = 0;
      while (owed >= STEP_MS && steps < CATCH_UP) { step(now); owed -= STEP_MS; steps++; }
      if (steps) draw(now);
    } else {
      owed = 0;
    }
    requestAnimationFrame(loop);
  }

  window.addEventListener('keydown', (e) => {
    if (!(e.code in BIT)) return;
    if (!e.repeat) struck.add(e.code);
    held.add(e.code);
    e.preventDefault();
  });
  window.addEventListener('keyup', (e) => {
    if (!(e.code in BIT)) return;
    held.delete(e.code);
    e.preventDefault();
  });
  // A game that loses the window loses its keys with it, or a paddle sticks.
  window.addEventListener('blur', () => { held.clear(); struck.clear(); });

  spinner.remove();
  document.body.appendChild(canvas);
  document.body.appendChild(hint);
  draw(performance.now());
  last = performance.now();
  requestAnimationFrame(loop);
}

const show = window.SHOW;
if (!show) throw new Error('blitter: the page did not set window.SHOW');
main(show);
