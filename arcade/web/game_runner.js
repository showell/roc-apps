// game_runner — the browser half of the arcade, and the twin of
// native/GameRunner.roc. It loads a game's wasm, runs the clock and the
// keyboard, and hands each frame to ShapeWire to paint.
//
// The game is the same Roc that runs natively. What is in here is only what a
// browser does differently: keep the input, pace the clock, show the speaker.
// Reading a frame and filling a canvas is shapewire.js, which this loads
// first and which knows nothing about games.
//
//   window.SHOW = { wasm: 'snake.wasm', loading: '…' }
//
// No hint: every game draws the keys it reads in its own HUD, which is the
// only place that cannot drift from the keys it actually reads.

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
  Space: 256, Enter: 512, KeyP: 1024, KeyR: 2048,
  KeyQ: 4096, KeyE: 8192,
};

const maskOf = (codes) => [...codes].reduce((bits, code) => bits | (KEY_BIT[code] ?? 0), 0);

function watchKeyboard(target) {
  const held = new Set();
  let struck = new Set();
  // A shortcut belongs to the browser: Ctrl+R reloads, Ctrl+F finds.
  const known = (event) => event.code in KEY_BIT && !(event.ctrlKey || event.metaKey || event.altKey);

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

// ── the pointer ────────────────────────────────────────────────────────────
// Position is reported in the game's own coordinates, so a game never learns
// how big the window is or how the page scaled the canvas.

const MOUSE_BIT = { 0: 1, 2: 2, 1: 4 }; // left, right, middle — Mouse.roc's bits

function watchPointer(canvas, width, height) {
  const held = new Set();
  let struck = new Set();
  let at = { x: 0, y: 0 };
  let wheel = 0;

  const place = (event) => {
    const box = canvas.getBoundingClientRect();
    at = {
      x: ((event.clientX - box.left) / box.width) * width,
      y: ((event.clientY - box.top) / box.height) * height,
    };
  };

  canvas.addEventListener('mousemove', place);
  canvas.addEventListener('mousedown', (event) => {
    place(event);
    held.add(event.button);
    struck.add(event.button);
    event.preventDefault();
  });
  // On the window, not the canvas: a drag that ends outside it still ends.
  window.addEventListener('mouseup', (event) => { held.delete(event.button); });
  canvas.addEventListener('contextmenu', (event) => event.preventDefault());
  // Positive is away from the hand, as raylib reports it; a browser's deltaY
  // is the other way round.
  canvas.addEventListener('wheel', (event) => { wheel -= Math.sign(event.deltaY); event.preventDefault(); });
  window.addEventListener('blur', () => { held.clear(); struck.clear(); });

  const bits = (buttons) => [...buttons].reduce((m, b) => m | (MOUSE_BIT[b] ?? 0), 0);
  return () => {
    const pointer = { held: bits(held), struck: bits(struck), x: at.x, y: at.y, wheel };
    struck = new Set();
    wheel = 0;
    return pointer;
  };
}

// ── the speaker ────────────────────────────────────────────────────────────
// The game says a sound happened and what it sounds like; this plays it and
// lights a pip. A browser will not start audio until the page has been
// clicked or typed in, so the context is made on the first key or button and
// the pips work either way.

const FADE_MS = 420;
const bitsOf = (word) => [...Array(32).keys()].filter((bit) => word & (1 << bit));

// One oscillator per sound, gated to nothing quickly enough not to click.
function makeSpeaker(game) {
  let audio = null;
  const tones = [...Array(game.toneCount()).keys()].map((i) => ({
    freq: game.toneFreq(i),
    seconds: game.toneMs(i) / 1000,
  }));

  const wake = () => {
    if (audio || typeof AudioContext === 'undefined') return;
    audio = new AudioContext();
  };

  const play = (which) => {
    if (!audio) return;
    for (const index of which) {
      const tone = tones[index];
      if (!tone) continue;
      const osc = audio.createOscillator();
      const gain = audio.createGain();
      osc.frequency.value = tone.freq;
      gain.gain.setValueAtTime(0.18, audio.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audio.currentTime + tone.seconds);
      osc.connect(gain).connect(audio.destination);
      osc.start();
      osc.stop(audio.currentTime + tone.seconds);
    }
  };

  return { wake, play, count: tones.length };
}

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
  // The one thing this wrapper is worth: an arity that disagrees with the
  // host's used to surface as a bare `unreachable` with no message at all.
  if (exports.advance.length !== 7) {
    throw new Error(`game_runner: advance takes ${exports.advance.length} arguments, expected 7`);
  }
  return {
    memory: exports.memory,
    computeFrame: exports.computeFrame, // the effect: answers the new frame's byte length
    advance: exports.advance,         // one step, given (held, struck)
    sounds: exports.sounds,           // a bit per tone the last step set off
    toneCount: exports.toneCount,     // how many tones the game has
    toneFreq: exports.toneFreq,       // and what each one sounds like
    toneMs: exports.toneMs,
    width: exports.width,
    height: exports.height,
    fps: exports.fps,                 // how often the game means to be stepped
    frameAt: exports.frameAt,         // where those bytes start
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

  const keyboard = watchKeyboard(window);
  const pointer = watchPointer(canvas, width, height);
  const speaker = makeSpeaker(game);
  window.addEventListener('keydown', speaker.wake);
  window.addEventListener('mousedown', speaker.wake);
  const ringing = { at: -Infinity, tones: [] };

  const step = (now) => {
    const keys = keyboard();
    const mouse = pointer();
    game.advance(keys.held, keys.struck, mouse.held, mouse.struck, mouse.x, mouse.y, mouse.wheel);
    const rung = game.sounds();
    if (rung) {
      ringing.at = now;
      ringing.tones = bitsOf(rung);
      speaker.play(ringing.tones);
    }
  };

  const draw = (now) => {
    // The canvas keeps what was drawn, so a frame starts from nothing —
    // as the native runner's clear does.
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, width, height);
    // The verb first: it may move the buffer, so the pointer is read after.
    const bytes = game.computeFrame();
    ShapeWire.paint(ctx, ShapeWire.decode(game.memory, game.frameAt(), bytes));
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
  draw(performance.now());
  last = performance.now();
  requestAnimationFrame(loop);
}

const show = window.SHOW;
if (!show) throw new Error('game_runner: the page did not set window.SHOW');
// A failure here used to leave the loading line up with the reason in the
// console, which is the one thing a blank page never tells you.
main(show).catch((error) => {
  document.body.textContent = `${show.wasm} did not start: ${error.message}`;
});
