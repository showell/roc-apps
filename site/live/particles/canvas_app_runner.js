// canvas_app_runner — the browser half of canvas_apps, and the twin of
// native/CanvasAppRunner.roc. It loads an app's wasm, runs the clock and the
// keyboard, and hands each frame to ShapeWire to paint.
//
// **NOT ONLY GAMES.** Six programs are built against this file and two of them
// are not games: `camera` is a world you fly around and `trick_or_treat` is a
// movie you can scrub. What they share is that they are a Roc value on a
// canvas, stepped at their own rate and drawn from what they answer. The
// `game` in the names below is older than that and has not been made honest
// yet.
//
// The app is the same Roc that runs natively. What is in here is only what a
// browser does differently: keep the input, pace the clock, show the speaker.
// Reading a frame and filling a canvas is shapewire.js, which this loads
// first and which knows nothing about any of them.
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
  KeyQ: 4096, KeyE: 8192, KeyC: 16384,
  Digit1: 32768, Digit2: 65536, Digit3: 131072, Digit4: 262144, KeyJ: 524288,
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

// What the wasm module must provide, checked once so a missing or mismatched
// export says which, rather than surfacing later as a bare `unreachable` or as
// `Cannot read properties of undefined`.
const WANTED = ['memory', 'computeFrame', 'advance', 'sounds', 'toneCount', 'toneFreq', 'toneMs', 'width', 'height', 'fps'];

function bindApp(exports) {
  const missing = WANTED.filter((name) => !(name in exports));
  if (missing.length) throw new Error(`canvas_app_runner: the module exports no ${missing.join(', ')}`);
  if (exports.advance.length !== 7) {
    throw new Error(`canvas_app_runner: advance takes ${exports.advance.length} arguments, expected 7`);
  }
  return {
    ...exports,
    // **ONE CALL, SO THERE IS NO ORDER TO GET WRONG.** `computeFrame` is the
    // effect and answers where it put the answer: two words, the frame's
    // start and its length. Reading the start from a second export is what
    // this replaces, and what it replaces caught two people.
    // **THE FRAME IS READ BY GENERATED CODE.** computeFrame answers the
    // address of the Roc list itself; RocGlue's reader, emitted from the
    // compiler's type table, turns it into shapes.
    //
    // **THE VIEW IS MADE AFTER THE CALL, ON ITS OWN LINE.** Asking for the
    // frame allocates, which can grow wasm memory, which DETACHES every
    // DataView over the old buffer. Written as one expression --
    // `read(new DataView(memory.buffer), computeFrame())` -- JavaScript
    // evaluates left to right and builds the view first, so the page dies on
    // the frame that happens to grow memory. That is the third costume this
    // one bug has worn.
    frame: () => {
      const at = exports.computeFrame();
      return RocGlue.frame(new DataView(exports.memory.buffer), at);
    },
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
  const game = bindApp(instance.exports);
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
    ShapeWire.paint(ctx, game.frame());
    drawSpeaker(ctx, width, height, toneCount, ringing, now);
  };

  // The app sets the rate, not the display: elapsed time is banked and steps
  // are taken as they fall due.
  let owed = 0;
  let last = performance.now();
  const tick = (now) => {
    owed = Math.min(owed + (now - last), stepMs * CATCH_UP);
    last = now;
    let stepped = 0;
    while (owed >= stepMs) { step(now); owed -= stepMs; stepped++; }
    if (stepped) draw(now);
  };

  // **A LOOP THAT RE-ARMS ITSELF LAST STOPS DEAD ON A THROW**, and this one
  // clears to black before it decodes, so the page went black and silent and
  // stayed that way. Every good message in this layer -- the unknown brush
  // mode, the word-exactness check, a Roc crash arriving as `unreachable` --
  // used to end there. `main`'s catch cannot help: it settled at startup.
  const loop = (now) => {
    try {
      tick(now);
    } catch (error) {
      stopped(error);
      return;
    }
    requestAnimationFrame(loop);
  };

  const stopped = (error) => {
    canvas.remove();
    document.body.textContent = `${show.wasm} stopped: ${error.message}`;
    throw error; // and again into the console, with its stack
  };

  loading.remove();
  document.body.appendChild(canvas);
  try {
    draw(performance.now());
  } catch (error) {
    stopped(error);
    return;
  }
  last = performance.now();
  requestAnimationFrame(loop);
}

const show = window.SHOW;
if (!show) throw new Error('canvas_app_runner: the page did not set window.SHOW');
// A failure here used to leave the loading line up with the reason in the
// console, which is the one thing a blank page never tells you.
main(show).catch((error) => {
  document.body.textContent = `${show.wasm} did not start: ${error.message}`;
});
