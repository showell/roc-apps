// Dog Park, played: one human, the park on its physics (docs/PHYSICS.md).
//
// THE PARK IS A CHECKERBOARD of 350 px tiles, each named by its column and
// row, round a torus: the world, its critters in the park in its middle.
// **THE PAGE RUNS THE PHYSICS** (physics.wasm, beside this file), 16 ticks a
// second; the engine (engine.js) keeps the tick and the park, and the
// browser keeps each level's park, the level played and the levels
// unlocked (localStorage), so a reload picks the game up. Where the
// browser keeps nothing (storage blocked), the game plays the same and
// starts afresh at each load.
//
// Pressing a dog leashes it; dragging it moves it by how far the pointer
// moved, tick by tick, the cows ahead of it scooting aside and the other
// dogs keeping their distance or following (its own breed). A bump ends the
// drag (the pointer is let go; the leash stays), with a word on what it
// hit (quips.js). The leash comes off when
// you press another dog, or 320 ticks (20 s) after the drag ended, and the
// park sleeps. Holding a dog near an edge of the screen carries it on, the
// viewport following. Dragging anywhere else pans the park.
//
// "m", or the Map button, toggles the MAP (the overview): the whole world
// once, opening centred on your view: the critters as dots (the dog you
// leashed last ringed), and your view as a rectangle you can drag by
// pressing inside it. Its scrollbars and the wheel move it round the
// torus. "m" again, or Back, returns.
//
// The dev console says what the engine does: loads, refusals, stalls.
//
// The page's modules: scene.js (the frames, tiles, the overview's frame,
// and what a frame draws), pointer.js (what a pointer event means, and the
// edge bands), blit.js (the drawing, and what a press is on), physics.js
// (the wasm's exports), engine.js (the tick and the park kept; no DOM).
// This file gives the engine the clock, the console and the browser's
// storage, wires the DOM to it, and runs the frame loop and the drawing.
// It starts only where there is a DOM, so node can import every module.

import { nearScene, overviewScene, dogOfTarget, world_px, tile_px, largestHerd, cow_count, level, levels, levelName, wonText } from "./scene.js";
import { meaning, panPointer, pressedOn, resting } from "./pointer.js";
import { draw } from "./blit.js";
import { createEngine } from "./engine.js";
import { pressedCritter, quipper, bumper } from "./quips.js";
import { score as score_template } from "./words.js";
import { instantiatePhysics } from "./physics.js";

// ── what the browser keeps ──────────────────────────────────────────────────

// **THE BROWSER'S STORAGE**, each read and write in try/catch: storage may
// be missing, blocked or full, and then the game plays on and remembers
// nothing (a read is null, a write is dropped, and the first is said).
let storageSaid = false;
function storageFailed(what, e) {
  if (storageSaid) return;
  storageSaid = true;
  console.warn(`Dog Park can't ${what} the browser's storage (${e?.message ?? e}): the game plays on, and won't be remembered`);
}
const store = {
  read(key) {
    try { return localStorage.getItem(key); } catch (e) { storageFailed("read", e); return null; }
  },
  write(key, text) {
    try { localStorage.setItem(key, text); } catch (e) { storageFailed("write", e); }
  },
  remove(key) {
    try { localStorage.removeItem(key); } catch (e) { storageFailed("write", e); }
  },
};

// **THE REMEMBERED VIEWPORT**: a load picks the player's game up, so it
// opens where the player last looked. A new game, or Start over, opens on
// the park's middle (the key is cleared). The key names the geometry (the
// tile, the world, the level): a view kept under another would open on the
// wrong ground. Read once the level is set.
const viewportKey = () => `dogpark.viewport.${tile_px}.${world_px}.${level}`;
function savedViewport() {
  try {
    const v = JSON.parse(store.read(viewportKey()) ?? "null");
    if (v && Number.isFinite(v.parkX) && Number.isFinite(v.parkY)) return { parkX: v.parkX, parkY: v.parkY };
  } catch { /* none kept that reads */ }
  return "none";
}
function saveViewport(v) {
  store.write(viewportKey(), JSON.stringify({ parkX: v.parkX, parkY: v.parkY }));
}
function forgetViewport() {
  store.remove(viewportKey());
}

// The physics, beside the page.
async function loadPhysics() {
  const response = await fetch("physics.wasm");
  if (!response.ok) throw new Error(`physics.wasm: ${response.status}`);
  return instantiatePhysics(response);
}

// ── the page ────────────────────────────────────────────────────────────────

async function start() {
  const canvas = document.getElementById("park");
  const ctx = canvas.getContext("2d");
  const engine = createEngine({
    physics: await loadPhysics(),
    store,
    now: () => performance.now(),
    log: console,
  });
  // Near (the park at its size) or the overview (a window onto the world).
  let mode = "near";
  // **DEBUGGING MODE** ("d", or the Debug button): each dog's number and the
  // critters' places in the last walk. Off by default; the tiles'
  // coordinates show either way.
  let labels = "hidden";
  // The overview's window's top-left, a park point (scene.js's
  // overviewFrame keeps it in the world); "m" centres it on the view.
  let overviewAt = { parkX: world_px / 2, parkY: world_px / 2 };
  // What the human's hand is doing (pointer.js says the shapes).
  let hand = resting;
  // What the last frame drew, and in which mode: a press is on what the
  // human saw.
  let drawn = { mode, objects: [] };

  // The canvas sized to the screen, in device pixels; the screen's size.
  function fit() {
    const ratio = window.devicePixelRatio || 1;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    canvas.width = Math.floor(width * ratio);
    canvas.height = Math.floor(height * ratio);
    return { width, height };
  }
  engine.load(fit, savedViewport);
  overviewAt = { parkX: world_px / 2, parkY: world_px / 2 };
  const score = document.getElementById("score");
  // Kept at most twice a second, when it moved.
  let savedAt = { parkX: NaN, parkY: NaN };
  let savedMs = -Infinity;

  // The park is kept as the page goes away (a closed tab, another app on a
  // phone), so nothing played since the last keep is lost.
  window.addEventListener("pagehide", () => engine.keep());
  document.addEventListener("visibilitychange", () => { if (document.visibilityState === "hidden") engine.keep(); });

  // The page does what an event means, in order: the mode and the
  // overview's window are the page's, the rest the engine's.
  function apply(intents) {
    for (const i of intents) {
      if (i.kind === "mode") mode = i.mode;
      else if (i.kind === "scroll") overviewAt = { parkX: i.parkX, parkY: i.parkY };
      else engine.intent(i);
    }
  }
  function handle(event, hitId = null) {
    const out = meaning(hand, event, hitId, mode, engine.view().viewport, overviewAt);
    hand = out.hand;
    apply(out.intents);
  }

  window.addEventListener("resize", () => engine.resize(fit()));
  window.addEventListener("keydown", (e) => {
    if (e.key === "m") handle({ type: "map" });
    if (e.key === "d") labels = labels === "hidden" ? "shown" : "hidden";
  });
  const debugButton = document.getElementById("debug");
  debugButton?.addEventListener("click", () => { labels = labels === "hidden" ? "shown" : "hidden"; });
  // The Map button: its label says what a press (or "m") does now.
  const mapButton = document.getElementById("map");
  mapButton?.addEventListener("click", () => handle({ type: "map" }));
  // A press on a cow or a chicken: a word, and nothing moves.
  const quips = quipper();
  // A drag that bumps: a word on what it hit.
  const bumps = bumper();
  let bumpsSaid = 0;
  const toast = document.getElementById("toast");
  let toastTimer = null;
  function say(line) {
    if (!toast) return;
    toast.textContent = line;
    toast.classList.add("shown");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("shown"), 3500);
  }
  canvas.addEventListener("pointerdown", (e) => {
    const hitId = pressedOn(drawn, mode, e.offsetX, e.offsetY);
    const v = engine.view();
    const dog = v.dogs.get(dogOfTarget(hitId));
    if (mode === "near" && dog === undefined) {
      const critter = pressedCritter(v.viewport, e.offsetX, e.offsetY, v.cows, v.chickens ?? [], v.others ?? []);
      if (critter !== null) return say(quips.say(critter));
    }
    if (dog !== undefined) quips.forgive();
    canvas.setPointerCapture(e.pointerId);
    handle({ type: "down", x: e.offsetX, y: e.offsetY, dogAt: dog === undefined ? "none" : { parkX: dog.parkX, parkY: dog.parkY } }, hitId);
  });
  canvas.addEventListener("pointermove", (e) => handle({ type: "move", x: e.offsetX, y: e.offsetY }));
  canvas.addEventListener("pointerup", () => handle({ type: "up" }));
  canvas.addEventListener("pointercancel", () => handle({ type: "cancel" }));
  canvas.addEventListener("wheel", (e) => {
    // The overview's own; near, the browser keeps its wheel (a pinch's zoom).
    if (mode !== "overview") return;
    e.preventDefault();
    // A line or a page of scroll as px, as a browser would scroll a page.
    const unit = e.deltaMode === 1 ? 16 : e.deltaMode === 2 ? canvas.clientHeight : 1;
    handle({ type: "wheel", dx: e.deltaX * unit, dy: e.deltaY * unit });
  }, { passive: false });

  // Each frame: the ticks due run (the edge bands, near, among them), then
  // the scene drawn, near between the last two ticks. A bump lets go of the
  // pointer: the hand rests until the next press.
  const frame = (nowMs) => {
    engine.frame(nowMs, mode === "near" ? panPointer(hand) : "none");
    const v = engine.view();
    if (hand.kind === "dragging" && !v.holding) hand = resting;
    if (v.bumped.count !== bumpsSaid) {
      bumpsSaid = v.bumped.count;
      if (v.bumped.kind !== "none") say(bumps.say(v.bumped.kind));
    }
    drawn = mode === "overview"
      ? { mode, objects: overviewScene(v.viewport, [...v.dogs.values()], v.cows, v.subscribed, v.lastLeashed, overviewAt, v.chickens ?? [], v.others ?? []) }
      : { mode, objects: nearScene(v.viewport, [...v.dogs.values()], v.cows, v.leashed, { alpha: v.alpha, was: v.was }, v.visits, { chickens: v.chickens ?? [], poops: v.poops ?? [], others: v.others ?? [], labels }) };
    draw(ctx, drawn.objects);
    // The goal, shown when it changes.
    // Out of the park's cows, never the ones this page happens to know.
    if (v.cows.length > 0) {
      const herd = largestHerd(v.cows);
      const won = herd === cow_count;
      const text = won ? wonText(cow_count) : score_template.replace("{herd}", herd).replace("{cows}", cow_count);
      if (score && score.textContent !== text) {
        score.textContent = text;
        score.classList.toggle("won", won);
      }
      showLevels(v.level, won);
    }
    if (mapButton) {
      const label = mode === "overview" ? "Back (m)" : "Map (m)";
      if (mapButton.textContent !== label) mapButton.textContent = label;
    }
    if (debugButton) {
      const pressed = labels === "shown" ? "true" : "false";
      if (debugButton.getAttribute("aria-pressed") !== pressed) debugButton.setAttribute("aria-pressed", pressed);
    }
    if (nowMs - savedMs >= 500 && (v.viewport.parkX !== savedAt.parkX || v.viewport.parkY !== savedAt.parkY)) {
      savedAt = { parkX: v.viewport.parkX, parkY: v.viewport.parkY };
      savedMs = nowMs;
      saveViewport(savedAt);
    }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);

  // **THE LEVELS**: a level won offers the next, which the player may take
  // or not ("Keep playing here": some practise, some explore); once more
  // than one is unlocked, a button each, so a player moves between them
  // freely. Each level's park is kept apart. Shown only when what it says
  // changes.
  const levelsBox = document.getElementById("levels");
  const nextBox = document.getElementById("next");
  let shownLevels = "";
  let declined = false;
  function showLevels(lv, won) {
    const offerNext = won && !declined && lv.now < levels.length && lv.unlocked <= lv.now;
    const key = `${lv.now} ${lv.unlocked} ${offerNext}`;
    if (key === shownLevels) return;
    shownLevels = key;
    if (nextBox) {
      nextBox.hidden = !offerNext;
      const go = document.getElementById("next-go");
      if (go) go.textContent = `Go to ${levelName(lv.now + 1)}`;
    }
    if (levelsBox) {
      levelsBox.replaceChildren();
      levelsBox.hidden = lv.unlocked < 2;
      for (let n = 1; n <= lv.unlocked; n++) {
        const b = document.createElement("button");
        b.type = "button";
        b.textContent = levelName(n);
        if (n === lv.now) b.setAttribute("aria-current", "true");
        else b.addEventListener("click", () => goLevel(n));
        levelsBox.append(b);
      }
    }
  }
  // Another level, at once: its park as kept, the view where the player
  // last looked there; the page's own state as a load leaves it.
  function goLevel(n) {
    const said = engine.goLevel(n, savedViewport);
    if (said !== "ok") return console.error(`level ${n}: ${said}`);
    mode = "near";
    hand = resting;
    overviewAt = { parkX: world_px / 2, parkY: world_px / 2 };
    declined = false;
    shownLevels = "";
    savedAt = { parkX: NaN, parkY: NaN };
  }
  document.getElementById("next-go")?.addEventListener("click", () => goLevel(level + 1));
  document.getElementById("next-stay")?.addEventListener("click", () => {
    declined = true;
    shownLevels = "";
  });

  // **START OVER**: this level's park back to its first layout, the view
  // on its middle.
  document.getElementById("reset")?.addEventListener("click", () => {
    if (!confirm(`Start over ${levelName(level)}? Every critter goes back to where the level began.`)) return;
    engine.startOver();
    forgetViewport();
    savedAt = { parkX: NaN, parkY: NaN };
    hand = resting;
  });
}

if (typeof document !== "undefined") start().catch((e) => console.error("Dog Park did not start:", e.message));
