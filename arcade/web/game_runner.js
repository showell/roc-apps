// game_runner — the browser half of the arcade, and the twin of
// native/GameRunner.roc. It loads a game's wasm, runs the clock and the
// keyboard, and paints the shapes the game answers with.
//
// The game is the same Roc that runs natively. What is in here is only what a
// browser does differently: decode the frame, fill a canvas, keep the key
// state, show the speaker.
//
//   window.SHOW = { wasm: 'snake.wasm', hint: '…', loading: '…' }

// ── the wire ───────────────────────────────────────────────────────────────
// ShapeWire.roc's layout, read back. Decoding is pure: it walks the words and
// answers plain descriptors, and nothing here touches a canvas.

const SHAPE = { POLY: 0, DISC: 1, RECT: 2, BLEND: 3 };
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
  const [geometry, next] = readFloats(floats, afterSecond, spans[mode]);
  return [{ mode, colors: [first, second], geometry }, next];
}

function readShape(words, floats, at) {
  const kind = words[at];
  if (kind === SHAPE.BLEND) return [{ kind, additive: words[at + 1] === 1 }, at + 2];

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
  for (let at = 0; at < words.length; ) {
    const [shape, next] = readShape(words, floats, at);
    shapes.push(shape);
    at = next;
  }
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
    if (!(r1 > r0)) return a;
    return withStops(ctx.createRadialGradient(x, y, r0, x, y, r1), [[0, a], [0.4, b], [1, c]]);
  }
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

function paintFrame(ctx, shapes) {
  for (const shape of shapes) {
    // A blend mark is not a shape: it says how the shapes after it combine.
    if (shape.kind === SHAPE.BLEND) {
      ctx.globalCompositeOperation = shape.additive ? 'lighter' : 'source-over';
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
}

// ── the keyboard ───────────────────────────────────────────────────────────
// The page owns it and the game is told. Every tick carries two bit sets:
// which keys are down now, and which went down since the last tick. A game
// needs both — snake turns on the edge, a paddle moves while a key is held —
// so an event alone will not do.
//
// The bits are Keys.roc's, in its order.
const KEY_BIT = {
  ArrowUp: 1, ArrowDown: 2, ArrowLeft: 4, ArrowRight: 8,
  KeyW: 16, KeyA: 32, KeyS: 64, KeyD: 128,
  Space: 256, Escape: 512, Enter: 1024, KeyF: 2048, KeyP: 4096, KeyR: 8192,
};

const maskOf = (codes) => [...codes].reduce((bits, code) => bits | (KEY_BIT[code] ?? 0), 0);

function watchKeyboard(target) {
  const held = new Set();
  let struck = new Set();
  const known = (event) => event.code in KEY_BIT;

  target.addEventListener('keydown', (event) => {
    if (!known(event)) return;
    if (!event.repeat) struck.add(event.code);
    held.add(event.code);
    event.preventDefault();
  });
  target.addEventListener('keyup', (event) => {
    if (!known(event)) return;
    held.delete(event.code);
    event.preventDefault();
  });
  // A window that loses focus loses its keys with it, or a paddle sticks.
  target.addEventListener('blur', () => { held.clear(); struck.clear(); });

  // Reading a snapshot consumes the edges, as one tick's worth.
  return () => {
    const snapshot = { held: maskOf(held), struck: maskOf(struck) };
    struck = new Set();
    return snapshot;
  };
}

// ── the speaker ────────────────────────────────────────────────────────────
// There is no audio here yet, and the game does not know that: it reports that
// a sound happened, exactly as it does natively, and here that lights a pip.

const FADE_MS = 420;
const bitsOf = (word) => [...Array(32).keys()].filter((bit) => word & (1 << bit));

function drawSpeaker(ctx, width, height, toneCount, ringing, now) {
  const age = now - ringing.at;
  if (age > FADE_MS) return;
  const fade = 1 - age / FADE_MS;
  const x = width - 30 - toneCount * 9;
  const y = height - 26;

  ctx.save();
  ctx.globalAlpha = 0.3 + 0.7 * fade;
  ctx.fillStyle = '#d7e3ff';
  ctx.fillRect(x - 9, y - 4, 5, 8);
  ctx.beginPath();
  ctx.moveTo(x - 4, y - 4);
  ctx.lineTo(x + 2, y - 9);
  ctx.lineTo(x + 2, y + 9);
  ctx.lineTo(x - 4, y + 4);
  ctx.closePath();
  ctx.fill();
  // One pip per tone the game has; the ones that just sounded are lit.
  for (let tone = 0; tone < toneCount; tone++) {
    ctx.fillStyle = ringing.tones.includes(tone) ? '#7ef7d1' : '#2a3566';
    ctx.beginPath();
    ctx.arc(x + 14 + tone * 9, y, 3, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}

// ── the page ───────────────────────────────────────────────────────────────

function bindGame(exports) {
  return {
    memory: exports.memory,
    render: exports.renderFrame,      // compute a frame; answers its byte length
    advance: exports.advance,         // one step, given (held, struck)
    sounds: exports.sounds,           // a bit per tone the last step set off
    toneCount: exports.toneCount,     // how many tones the game has
    width: exports.width,
    height: exports.height,
    fps: exports.fps,                 // how often the game means to be stepped
    frameAt: exports.bufPtr,
  };
}

const CATCH_UP = 4; // steps one animation frame may take before time is dropped

async function main(show) {
  document.body.style.cssText =
    'margin:0;background:#06080f;height:100vh;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;font:13px system-ui,sans-serif;color:#6d7aa8';
  const loading = document.createElement('div');
  loading.textContent = show.loading ?? 'Loading…';
  document.body.appendChild(loading);

  const { instance } = await WebAssembly.instantiateStreaming(fetch(show.wasm), { env: {} });
  const game = bindGame(instance.exports);
  const width = game.width();
  const height = game.height();
  const toneCount = game.toneCount();
  const stepMs = 1000 / game.fps();

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  canvas.style.cssText = 'background:#06080f;max-width:100%;max-height:88vh';
  const ctx = canvas.getContext('2d');

  const hint = document.createElement('div');
  hint.textContent = show.hint ?? '';
  hint.style.cssText = 'margin-top:10px;letter-spacing:.04em';

  const snapshot = watchKeyboard(window);
  const ringing = { at: -Infinity, tones: [] };

  const step = (now) => {
    const { held, struck } = snapshot();
    game.advance(held, struck);
    const rung = game.sounds();
    if (rung) { ringing.at = now; ringing.tones = bitsOf(rung); }
  };

  const draw = (now) => {
    // The canvas keeps what was drawn, so a frame starts from nothing —
    // as the native runner's clear does.
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, width, height);
    // render() computes the frame and may move the buffer, so its pointer is
    // read after, never as a sibling argument.
    const bytes = game.render();
    paintFrame(ctx, decodeFrame(game.memory, game.frameAt(), bytes));
    drawSpeaker(ctx, width, height, toneCount, ringing, now);
  };

  // The game sets the rate, not the display: elapsed time is banked and steps
  // are taken as they fall due.
  let owed = 0;
  let last = performance.now();
  const loop = (now) => {
    owed = Math.min(owed + (now - last), stepMs * CATCH_UP);
    last = now;
    let stepped = 0;
    while (owed >= stepMs) { step(now); owed -= stepMs; stepped++; }
    if (stepped) draw(now);
    requestAnimationFrame(loop);
  };

  loading.remove();
  document.body.appendChild(canvas);
  document.body.appendChild(hint);
  draw(performance.now());
  last = performance.now();
  requestAnimationFrame(loop);
}

const show = window.SHOW;
if (!show) throw new Error('game_runner: the page did not set window.SHOW');
main(show);
