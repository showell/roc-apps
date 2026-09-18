// blitter — the browser half of the Safari camera. It loads safari.wasm, calls
// renderFrame(camera pose), and paints what the guest wrote into linear memory.
//
// THIS IS SAFARI-CODEX'S FORK, and it is a real file rather than the symlink it
// used to be. `HISTORICAL_WASM_ROOT/` is a COPY of the angry-gopher game and this
// project never edits it -- it is the ORACLE every gold here is measured against,
// and a blitter edited through a symlink would have been an oracle edited to
// agree with us. The angry-gopher original stays exactly as it is; this fork is
// where the boundary work happens.
//
// THE LINE THIS FILE IS ORGANISED AROUND. Three kinds of thing live here and they
// are not the same kind:
//
//   1. CANVAS BACKEND. A vocabulary of paths and paints with no idea what it is
//      drawing: fill this polygon solid, or with a linear gradient between two
//      points, or with a radial one, or with a radial mapped onto an ellipse.
//      There are no trucks in this section, and there should never be.
//
//   2. BROWSER FACTS. Things that are true of canvas and of nothing else -- a
//      one-pixel overlap that beats a rasterisation seam, a degenerate-matrix
//      guard, the frame budget, the spinner, the key handling. These stay.
//
// THERE USED TO BE A THIRD KIND AND THERE IS NOT ANY MORE. A block of SCENE
// RECIPES sat between those two: which colour to shade a polygon's edges, how far
// to lift its middle, below which radius or alpha to skip a thing entirely. They
// were decisions, they were the game's rather than the canvas's, and they lived in
// the one file in this project that nothing could run. `port/Blit.codex` holds them
// now and `judge/BlitCheck.codex` grades them; what arrives over the wire is
// already decided, so this file paints and does not choose. The guest sends a
// tag-2 span shade with its colours computed, or a tag-0 flat fill, and never
// sends a disc it has decided is too faint to see.
//
// Plain hand-written JS (no TS, no bundler).

const W = 960, H = 600;

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
// Everything that is about THIS screensaver and not about rendering one, which
// is now a wasm file and some strings.
//
// **THE BACKDROP USED TO BE HERE AND IS NOT ANY MORE.** A `drawSafariBackdrop`
// painted the sky's gradient, the grass and the sun, from `skyTop`,
// `skyHorizon` and four sun readouts -- the one part of this file that could not
// be reused for a night walk through a city, because it knew what the sky of a
// country drive looks like. The movie sends its own backdrop as shapes now, so
// a second show needs no function here at all: only the literal below.

// THE DESCRIPTOR comes from the page now, because there is more than one show.
// A page sets `window.SHOW` and this file plays it; everything else here is
// about rendering one, not about which.
//
//   window.SHOW = {
//     wasm: 'safari.wasm',        the module to fetch
//     scenes: 19,                 how many the movie has; it does not export it
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
  return {
    memory: x.memory,
    render: x.renderFrame,          // compute a frame; answers its byte length
    forward: x.advance,             // one step along the route
    backward: x.back,
    step: x.clock,                  // how many steps in
    segment: x.scene,               // which scene of the movie
    roll: x.roll,                   // camera roll, in radians
    bufferAt: x.bufPtr,
    bufferPeak: x.bufHighWater,
    bufferCapacity: x.bufCap,
  };
}

// The J key steps until the segment changes; this bounds the search so a guest that
// never leaves a segment cannot hang the page.
const STEP_GUARD = 200000;

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

// The frame-budget HUD: zig can't time itself (no clock in wasm-freestanding), so the
// only place to measure the 16.7ms/60fps budget is here, where performance.now() lives
// and where BOTH halves — wasm geometry compute and canvas blit — can be timed. We keep
// a rolling window so the displayed max catches the worst recent frame, not just now.
const BUDGET_MS = 1000 / 60;
const WINDOW = 90; // ~1.5s of frames
const hud = { wasm: [], blit: [], total: [] };
function hudPush(arr, v) { arr.push(v); if (arr.length > WINDOW) arr.shift(); }
function hudMax(arr) { let m = 0; for (const v of arr) if (v > m) m = v; return m; }
function hudAvg(arr) { if (!arr.length) return 0; let s = 0; for (const v of arr) s += v; return s / arr.length; }

function drawHud(ctx, bufBytes, bufCap, cmds, step, seg, segments, debug) {
  // Off by default — prod is completely clean (nothing drawn). D toggles the dev
  // overlay on; the bottom-of-page hint is where it stays discoverable.
  if (!debug) return;
  ctx.save();
  ctx.font = '12px ui-monospace,Menlo,monospace';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  // Color the total line by the RATE of missed frames, not the single worst one: a lone
  // GC/jank spike shouldn't pin it red for the whole window. green = no misses; amber =
  // occasional (≤20%, likely jank); red = consistently over budget (a real problem).
  const totMax = hudMax(hud.total);
  let overCount = 0;
  for (const v of hud.total) if (v > BUDGET_MS) overCount++;
  const frac = hud.total.length ? overCount / hud.total.length : 0;
  const fill = bufCap ? (bufBytes / bufCap) : 0;
  const lines = [
    `t ${step}   seg ${seg}/${segments}`,
    `wasm ${hudAvg(hud.wasm).toFixed(2)}ms  blit ${hudAvg(hud.blit).toFixed(2)}ms`,
    `total ${hudAvg(hud.total).toFixed(2)}ms  max ${totMax.toFixed(2)}  over ${overCount}/${hud.total.length} (${BUDGET_MS.toFixed(2)})`,
    `${cmds} draw-calls   buf-peak ${(bufBytes / 1024).toFixed(1)}/${(bufCap / 1024).toFixed(0)} KiB (${(fill * 100).toFixed(0)}%)`,
    `D · hide debug`,
  ];
  const totColor = frac === 0 ? '#9be29b' : frac <= 0.2 ? '#ffd166' : '#ff6b6b';
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  ctx.fillRect(8, 8, 290, 8 + lines.length * 16 + 4);
  for (let i = 0; i < lines.length; i++) {
    ctx.fillStyle = (i === 0) ? '#ffe14d'      // the step `t`, highlighted — it's what Steve reports
      : (i === 2) ? totColor                   // the total-frame-time line, coloured by miss rate
      : (i === 3 && fill > 0.9) ? '#ffd166'     // the buffer line, amber when nearly full
      : (i === 4) ? '#8a93a0'                   // the dim D-toggle hint
      : '#cfe0f0';
    ctx.fillText(lines[i], 14, 14 + i * 16);
  }
  ctx.restore();
}

async function main(show) {
  document.body.style.cssText =
    'margin:0;background:#0b0b0d;height:100vh;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;font-family:ui-monospace,Menlo,monospace;color:#cfd2d6';
  const canvas = document.createElement('canvas');
  canvas.width = W;
  canvas.height = H;
  canvas.style.cssText = 'display:block;background:#000;box-shadow:0 10px 40px rgba(0,0,0,0.6)';
  document.body.appendChild(canvas);
  const hint = document.createElement('div');
  hint.textContent = show.hint;
  hint.style.cssText = 'margin-top:10px;font-size:12px;color:#9aa0a6;letter-spacing:0.4px';
  document.body.appendChild(hint);
  const ctx = canvas.getContext('2d');

  // a loading spinner over the canvas while the wasm loads + the first frames warm up (see the warmup
  // before the loop). The cold first frames blow the 16.7ms budget, which read as a stutter at startup.
  const spinStyle = document.createElement('style');
  spinStyle.textContent = '@keyframes sg-spin{to{transform:rotate(360deg)}}';
  document.head.appendChild(spinStyle);
  const spinner = document.createElement('div');
  spinner.style.cssText = 'position:fixed;inset:0;z-index:10;display:flex;flex-direction:column;gap:16px;' +
    'align-items:center;justify-content:center;background:#0b0b0d;color:#9aa0a6;' +
    'font-family:ui-monospace,Menlo,monospace;font-size:13px;letter-spacing:0.5px';
  spinner.innerHTML = '<div style="width:42px;height:42px;border:4px solid #2a2c30;' +
    'border-top-color:#cfd2d6;border-radius:50%;animation:sg-spin 0.8s linear infinite"></div>' +
    `<div>${show.loading}</div>`;
  document.body.appendChild(spinner);

  const { instance } = await WebAssembly.instantiateStreaming(fetch(show.wasm), {});
  const scene = bindScene(instance.exports);
  const capBytes = scene.bufferCapacity();

  let auto = true;
  let debug = false; // the dev overlay (frame-budget HUD) — off by default (prod is clean); D toggles it.

  function draw() {
    // time the two halves separately: guest geometry compute, then canvas blit.
    const t0 = performance.now();
    const len = scene.render();
    const t1 = performance.now();
    ctx.save();
    // the whole frame rolls with the camera, so the world banks into a turn
    ctx.translate(W / 2, H / 2);
    ctx.rotate(-scene.roll());
    ctx.translate(-W / 2, -H / 2);
    const cmds = blit(ctx, scene.memory, scene.bufferAt(), len);
    ctx.restore();
    const t2 = performance.now();
    hudPush(hud.wasm, t1 - t0);
    hudPush(hud.blit, t2 - t1);
    hudPush(hud.total, t2 - t0);
    drawHud(ctx, scene.bufferPeak(), capBytes, cmds, scene.step(), scene.segment() + 1, show.scenes, debug); // unrolled overlay, on top
  }
  function loop() {
    if (auto) { scene.forward(); draw(); }
    requestAnimationFrame(loop);
  }

  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space') { auto = !auto; e.preventDefault(); }
    else if (e.code === 'ArrowUp') { auto = false; scene.forward(); draw(); e.preventDefault(); }
    else if (e.code === 'ArrowDown') { auto = false; scene.backward(); draw(); e.preventDefault(); }
    else if (e.code === 'KeyJ') {
      // Step until the scene enters the next segment, landing at its start — every step
      // is a real one, so velocity, acceleration and the day→dusk dimming stay faithful.
      // Repeated presses walk the route a segment at a time; it pauses after so you can
      // look. Mirrors the J hotkey in main.ts.
      if (!e.repeat) {
        auto = false;
        const from = scene.segment();
        let guard = 0;
        while (scene.segment() === from && guard++ < STEP_GUARD) scene.forward();
        draw();
      }
      e.preventDefault();
    } else if (e.code === 'KeyD') {
      // toggle the dev overlay (frame-budget HUD). Off by default; redraw now so it
      // responds even while paused.
      if (!e.repeat) { debug = !debug; draw(); }
      e.preventDefault();
    }
  });

  // Warm the JIT + canvas BEFORE the live loop and behind the spinner: the first few frames are cold
  // (gradient objects, first paints) and overshoot the 16.7ms budget, which looked like a startup stutter.
  // Render the opening frame across a few rAF ticks (so the spinner keeps spinning) until one comes in
  // under budget — then reveal and start. draw() doesn't advance, so no animation is skipped.
  await new Promise((resolve) => {
    let i = 0;
    (function warm() {
      const t = performance.now();
      draw();
      const dt = performance.now() - t;
      if (++i >= 30 || (i >= 4 && dt < 12)) resolve();
      else requestAnimationFrame(warm);
    })();
  });
  spinner.remove();

  draw();
  requestAnimationFrame(loop);
}

const show = window.SHOW;
if (!show) throw new Error('blitter: the page did not set window.SHOW');
main(show);
