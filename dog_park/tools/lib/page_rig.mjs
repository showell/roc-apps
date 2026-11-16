// A page in node: the engine (web/engine.js) on the real physics.wasm
// (zig-out/web/physics.wasm, a fresh instance per page), its clock fake and
// moved by the test, its store what the test gives: a browser's storage
// (`memoryStore`, shared by the pages of one browser) or storage that
// keeps nothing (`blockedStore`).

import { readFileSync } from "node:fs";
import { createEngine } from "../../web/engine.js";
import { instantiatePhysics, flag } from "../../web/physics.js";

// The served build, unless DOGPARK_WASM names another (the fast tier's
// Debug build, zig-out/web-debug/physics.wasm, from the folder the tests
// run in).
export const wasmBytes = () => readFileSync(process.env.DOGPARK_WASM ?? new URL("../../zig-out/web/physics.wasm", import.meta.url));

/** A browser's storage: what it keeps, by key, and every write it took. */
export function memoryStore() {
  const kept = new Map();
  const writes = [];
  return {
    kept,
    writes,
    read: (key) => (kept.has(key) ? kept.get(key) : null),
    write: (key, text) => {
      writes.push(key);
      kept.set(key, text);
    },
    remove: (key) => kept.delete(key),
  };
}

/** Storage that keeps nothing, as park.js's store is when the browser refuses it. */
export function blockedStore() {
  return { read: () => null, write: () => {}, remove: () => {} };
}

/**
 * A page on `store`, its screen `screen`, opening on `at` (a viewport
 * top-left, or "none"). `load()` loads it and starts its clock; `ticks(n)`
 * runs n frames, one a tick.
 */
export async function pageRig({ store, screen = { width: 1280, height: 800 }, at = "none" }) {
  const physics = await instantiatePhysics(wasmBytes());
  const tick_ms = 1000 / physics.ticksPerSecond();
  const said = [];
  const rig = {
    clock: 0,
    said,
    physics,
    store,
    // `n` frames, one a tick.
    ticks(n = 1, panAt = "none") {
      for (let k = 0; k < n; k++) {
        rig.clock += tick_ms;
        engine.frame(rig.clock, panAt);
      }
    },
    warnings: () => said.filter((s) => s[0] !== "log").map((s) => s.slice(1).join(" ")),
  };
  const engine = createEngine({
    physics,
    store,
    now: () => rig.clock,
    log: {
      log: (...a) => said.push(["log", ...a]),
      warn: (...a) => said.push(["warn", ...a]),
      error: (...a) => said.push(["error", ...a]),
    },
  });
  rig.engine = engine;
  rig.load = () => {
    engine.load(() => screen, at);
    engine.frame(rig.clock); // the clock starts
  };
  return rig;
}

// ── the physics' numbers, asked of the wasm itself ───────────────────────────
// So a test derives what it waits for from the code under test, never from
// a number that tuning will change. A separate instance: no page's board
// is touched.

const geometry = await instantiatePhysics(wasmBytes());

/** Level `n`'s first layout as a park's text (1-based), at tick `t`. */
export function laidOut(n, t = 0) {
  geometry.reset(n - 1);
  return geometry.writePark(t);
}

/** Level `n`'s first layout's critters, as physics.js lists them. */
export function laidOutCritters(n) {
  geometry.reset(n - 1);
  return geometry.critters();
}

/** How many ticks after a letgo the leash comes off (the physics' let_go_ticks). */
export function letGoTicks() {
  geometry.reset(0);
  const dog = geometry.critters().dogs[0].id;
  geometry.human("leash", dog);
  geometry.tick(1, []);
  geometry.human("letgo");
  for (let t = 2; t < 100_000; t++) {
    if (geometry.tick(t, []).flags & flag.release) return t - 2;
  }
  throw new Error("the leash never came off");
}
