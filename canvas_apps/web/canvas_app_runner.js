// canvas_app_runner — the browser half of canvas_apps, and the twin of
// native/CanvasAppRunner.roc. It loads an app's wasm, runs the clock and the
// keyboard, and hands each frame to ShapesCanvas to paint.
//
// Not every program built against this file is a game: `camera` is a world
// you fly around and `trick_or_treat` is a movie you can scrub. What they
// share is that each is a Roc value on a canvas, stepped at its own rate and
// drawn from what it answers. The `game` in the names below is older than
// that.
//
// The app is the same Roc that runs natively. What is in here is only what a
// browser does differently: keep the input, pace the clock, show the speaker.
// Reading a frame and filling a canvas is shapes_canvas.js, which this loads
// first and which knows nothing about any of them.
//
//   window.SHOW = { wasm: 'snake.wasm', loading: '…', readsPointer: true }
//
// A page that sets `sharp: true` keeps one canvas pixel for each pixel of the
// screen, however the page has scaled the canvas, so its type stays crisp.
//
// A page that opens partway lists the words its address may name, as
// `opensAt: ['trees', 'grass']`, and `?start=grass` opens it at the second.
//
// No hint: every game draws the keys it reads in its own HUD, which is the
// only place that cannot drift from the keys it actually reads.

// ── the keyboard ───────────────────────────────────────────────────────────
// The page owns it and the game is told. Every tick carries two bit sets:
// which keys are down now, and which went down since the last tick. A game
// needs both — snake turns on the edge, a paddle moves while a key is held —
// so an event alone will not do.
//
// The bits are Keys.roc's, and safari/gates/input_bits.shale holds the two equal.
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
// A mouse, a finger and a pen all arrive as pointer events, so an app can't
// tell them apart. Position is reported in the game's own coordinates, so a
// game never learns how big the window is or how the page scaled the canvas.
// During a drag it may be off the canvas.

// `event.buttons` uses Mouse.roc's bits, and safari/gates/input_bits.shale holds the
// two equal, as it does KEY_BIT.
const MOUSE_BIT = { Left: 1, Right: 2, Middle: 4 };
const MOUSE_BITS = MOUSE_BIT.Left | MOUSE_BIT.Right | MOUSE_BIT.Middle;

function watchPointer(canvas, width, height) {
  let held = 0;
  let struck = 0;
  let at = { x: 0, y: 0 };
  let wheel = 0;
  // The pointer that pressed on the canvas, until it lets go. A second finger
  // is ignored until then.
  let dragger = null;

  const place = (event) => {
    const box = canvas.getBoundingClientRect();
    at = {
      x: ((event.clientX - box.left) / box.width) * width,
      y: ((event.clientY - box.top) / box.height) * height,
    };
  };

  const readButtons = (event) => {
    const now = event.buttons & MOUSE_BITS;
    struck |= now & ~held;
    held = now;
  };

  const release = (event) => {
    if (event.pointerId !== dragger) return;
    held = 0;
    dragger = null;
  };

  canvas.addEventListener('pointerdown', (event) => {
    if (dragger !== null && event.pointerId !== dragger) return;
    dragger = event.pointerId;
    // With capture, a drag that leaves the canvas keeps tracking and ends here.
    canvas.setPointerCapture(dragger);
    place(event);
    readButtons(event);
    event.preventDefault();
  });
  canvas.addEventListener('pointermove', (event) => {
    if (dragger !== null && event.pointerId !== dragger) return;
    place(event);
    // A mouse's other buttons arrive as moves: pointerdown and pointerup come
    // only with the first button down and the last one up.
    if (dragger !== null) readButtons(event);
  });
  canvas.addEventListener('pointerup', release);
  canvas.addEventListener('pointercancel', release);
  canvas.addEventListener('contextmenu', (event) => event.preventDefault());
  // Positive is away from the hand, as raylib reports it; a browser's deltaY
  // is the other way round.
  canvas.addEventListener('wheel', (event) => { wheel -= Math.sign(event.deltaY); event.preventDefault(); });
  window.addEventListener('blur', () => { held = 0; struck = 0; dragger = null; });

  return () => {
    const pointer = { held, struck, x: at.x, y: at.y, wheel };
    struck = 0;
    wheel = 0;
    return pointer;
  };
}

// ── the speaker ────────────────────────────────────────────────────────────
// The game says a sound happened and what it sounds like; this plays it and
// lights a pip. A browser will not start audio until the page has been
// clicked or typed in, so the context is made on the first key or button and
// the pips work either way. A finger counts only when it lifts, so `wake` runs
// again then and resumes a context its pointerdown left suspended.

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
    if (typeof AudioContext === 'undefined') return;
    audio ??= new AudioContext();
    audio.resume();
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
    // The tick's input arrives as named fields, and this is the one call that
    // puts them in the export's order. safari/gates/input_bits.shale holds
    // that order to host.zig's and lib/WasmApp.roc's.
    advance: ({ key_held, key_struck, button_held, button_struck, x, y, wheel }) =>
      exports.advance(key_held, key_struck, button_held, button_struck, x, y, wheel),
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
      const computeStart = performance.now();
      const at = exports.computeFrame();
      const decodeStart = performance.now();
      const shapes = RocGlue.frame(new DataView(exports.memory.buffer), at);
      FRAME_SPLIT.computeMs = decodeStart - computeStart;
      FRAME_SPLIT.decodeMs = performance.now() - decodeStart;
      return shapes;
    },
  };
}

const CATCH_UP = 4; // steps one animation frame may take before time is dropped

// The last frame's time in the wasm (computing its shapes), in the glue
// (decoding them out of the wasm's memory) and on the canvas (painting them),
// for the timing log.
const FRAME_SPLIT = { computeMs: 0, decodeMs: 0, paintMs: 0 };

// With `?timing=1` in the address, the first frames' times go to the console:
// how long the wasm took to load and compile and to take its opening presses,
// then per frame the gap since the last one, the steps taken, and the
// milliseconds spent stepping and drawing. Comparing the first TIMED_WINDOW of
// the TIMED_FRAMES frames with the last tells a slow start (the engine still on
// its first, unoptimized code) from a slow ride. Without it nothing is
// recorded.
const TIMED_FRAMES = 120;
const TIMED_WINDOW = 30;
function frameTimer() {
  if (new URLSearchParams(location.search).get('timing') !== '1') return null;
  const rows = [];
  const first = [0, TIMED_WINDOW];
  const last = [TIMED_FRAMES - TIMED_WINDOW, TIMED_FRAMES];
  return {
    loaded: (ms) =>
      console.log(`canvas_app_runner: wasm loaded, compiled and through its opening presses in ${ms.toFixed(0)} ms`),
    frame: (row) => {
      if (rows.length >= TIMED_FRAMES) return;
      rows.push(row);
      if (rows.length < TIMED_FRAMES) return;
      console.table(rows);
      const slow = (from, to) => rows.slice(from, to).filter((r) => r.stepMs + r.drawMs > 16).length;
      const mean = (from, to, key) =>
        (rows.slice(from, to).reduce((sum, r) => sum + r[key], 0) / (to - from)).toFixed(1);
      const steps = (from, to) => rows.slice(from, to).reduce((sum, r) => sum + r.steps, 0);
      console.log(
        `canvas_app_runner: frames over 16 ms of work: first ${TIMED_WINDOW} ${slow(...first)}, ` +
          `last ${TIMED_WINDOW} ${slow(...last)}; ` +
          `mean step ms ${mean(...first, 'stepMs')} then ${mean(...last, 'stepMs')}, ` +
          `mean draw ms ${mean(...first, 'drawMs')} then ${mean(...last, 'drawMs')} ` +
          `(wasm ${mean(...first, 'computeMs')} then ${mean(...last, 'computeMs')}, ` +
          `decode ${mean(...first, 'decodeMs')} then ${mean(...last, 'decodeMs')}, ` +
          `paint ${mean(...first, 'paintMs')} then ${mean(...last, 'paintMs')}), ` +
          `steps taken ${steps(...first)} then ${steps(...last)}`,
      );
    },
  };
}

// How many times the app hears Right before its first frame: the place in
// `opensAt` of the word the address names. An app has no way to hear an address,
// so it hears the keys a reader would press to get there.
function pressesToOpen(show) {
  const word = new URLSearchParams(location.search).get('start');
  if (word === null) return 0;
  const presses = (show.opensAt ?? []).indexOf(word);
  if (presses < 0) throw new Error(`canvas_app_runner: this page can't start at ${word}`);
  return presses;
}

async function main(show) {
  document.body.style.cssText =
    'margin:0;background:#06080f;height:100vh;display:flex;flex-direction:column;' +
    'align-items:center;justify-content:center;font:13px system-ui,sans-serif;color:#6d7aa8';
  const loading = document.createElement('div');
  loading.textContent = show.loading ?? 'Loading…';
  document.body.appendChild(loading);

  const timer = frameTimer();
  const loadStart = performance.now();
  const { instance } = await WebAssembly.instantiateStreaming(fetch(show.wasm), { env: {} });
  const game = bindApp(instance.exports);
  const width = game.width();
  const height = game.height();
  const toneCount = game.toneCount();
  const stepMs = 1000 / game.fps();

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  // A sharp canvas's own size follows the screen, so its place on the page is
  // said outright: the same one the other canvases get from their own size.
  canvas.style.cssText = 'background:#06080f;' + (show.sharp
    ? `width:min(${width}px,100%,${(88 * width) / height}vh);height:auto;aspect-ratio:${width}/${height}`
    : 'max-width:100%;max-height:88vh');
  // A finger on a canvas that reads the pointer is a drag. On any other canvas
  // it is the reader scrolling the page.
  canvas.style.touchAction = show.readsPointer ? 'none' : 'auto';
  const ctx = canvas.getContext('2d');

  const keyboard = watchKeyboard(window);
  const pointer = watchPointer(canvas, width, height);
  const speaker = makeSpeaker(game);
  window.addEventListener('keydown', speaker.wake);
  window.addEventListener('pointerdown', speaker.wake);
  window.addEventListener('pointerup', speaker.wake);
  const ringing = { at: -Infinity, tones: [] };

  const step = (now) => {
    const keys = keyboard();
    const mouse = pointer();
    game.advance({
      key_held: keys.held,
      key_struck: keys.struck,
      button_held: mouse.held,
      button_struck: mouse.struck,
      x: mouse.x,
      y: mouse.y,
      wheel: mouse.wheel,
    });
    const rung = game.sounds();
    if (rung) {
      ringing.at = now;
      ringing.tones = bitsOf(rung);
      speaker.play(ringing.tones);
    }
  };

  // How many canvas pixels the app's pixel takes this frame. Setting a canvas's
  // size clears it and its transform, so only a change of size sets it.
  const matchScreen = () => {
    const across = Math.round(canvas.getBoundingClientRect().width * (window.devicePixelRatio ?? 1));
    if (across > 0 && across !== canvas.width) {
      canvas.width = across;
      canvas.height = Math.round((across * height) / width);
    }
    const scale = canvas.width / width;
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
    return scale;
  };

  const draw = (now) => {
    const scale = show.sharp ? matchScreen() : 1;
    // The canvas keeps what was drawn, so a frame starts from nothing —
    // as the native runner's clear does.
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, width, height);
    const shapes = game.frame();
    const paintStart = performance.now();
    ShapesCanvas.paint(ctx, shapes, scale);
    FRAME_SPLIT.paintMs = performance.now() - paintStart;
    drawSpeaker(ctx, width, height, toneCount, ringing, now);
  };

  // The app sets the rate, not the display: elapsed time is banked and steps
  // are taken as they fall due.
  let owed = 0;
  let last = performance.now();
  const tick = (now) => {
    const gap = now - last;
    owed = Math.min(owed + gap, stepMs * CATCH_UP);
    last = now;
    let stepped = 0;
    const stepStart = performance.now();
    while (owed >= stepMs) { step(now); owed -= stepMs; stepped++; }
    const drawStart = performance.now();
    if (stepped) draw(now);
    timer?.frame({
      gapMs: +gap.toFixed(1),
      steps: stepped,
      stepMs: +(drawStart - stepStart).toFixed(1),
      drawMs: +(performance.now() - drawStart).toFixed(1),
      computeMs: stepped ? +FRAME_SPLIT.computeMs.toFixed(1) : 0,
      decodeMs: stepped ? +FRAME_SPLIT.decodeMs.toFixed(1) : 0,
      paintMs: stepped ? +FRAME_SPLIT.paintMs.toFixed(1) : 0,
    });
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

  for (let press = pressesToOpen(show); press > 0; press--) {
    game.advance({ key_held: 0, key_struck: KEY_BIT.ArrowRight, button_held: 0, button_struck: 0, x: 0, y: 0, wheel: 0 });
  }

  timer?.loaded(performance.now() - loadStart);

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
