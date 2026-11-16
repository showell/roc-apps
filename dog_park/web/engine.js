// The engine: the page's side of the park, with no DOM. The physics runs in
// the wasm (physics.js); this runs it sixteen times a second with the
// human's inputs and the pointer's drag, keeps what the page draws, and
// keeps each level's park, the level played and the levels unlocked in a
// store (park.js's, over the browser's localStorage), so a reload picks
// the game up where it was. Everything it does with a clock or the store
// goes through what `createEngine` is given, so node can drive it; one
// engine is one page load.
//
//   createEngine({ physics, store, now, log })
//     physics     physics.js's wrapper over the wasm
//     store       { read(key) -> text or null, write(key, text) }: what the
//                 browser keeps. A store that keeps nothing (storage
//                 blocked) plays the same and remembers nothing
//     now         () -> ms, the page's clock (performance.now)
//     log         { log, warn, error }, the dev console
//
//   engine.load(measure, at)  the level kept, else Level One, and its park
//                         kept, else its first layout; `measure()` ->
//                         { width, height }; `at` a viewport top-left
//                         { parkX, parkY } to open on, a function giving one
//                         once the level is known, or "none" (the park's
//                         middle)
//   engine.resize({ width, height })
//   engine.intent(i)      a pointer intent (pointer.js): grab, drag, letgo, pan
//   engine.frame(nowMs, panAt)
//                         each frame: the ticks due by `nowMs` run (the first
//                         frame starts the clock and runs none), and the park
//                         is kept when it is due; `panAt` is where the pointer
//                         holds a pan (pointer.js's panPointer). Answers the
//                         ticks run
//   engine.view()         plain data, copies: { viewport, dogs (a Map by id),
//                         cows, subscribed (a Set of tile keys), leashed,
//                         lastLeashed, tick, alpha, was, status, holding,
//                         bumped: { count, kind } (the ticks' bumps and what
//                         the last hit), visits, level: { now, unlocked } }
//   engine.goLevel(n, at) another level, played at once: "ok", or why not
//                         ("no_such_level", "locked", "not_won")
//   engine.startOver()    this level's park back to its first layout
//   engine.keep()         the park kept now (park.js, as the page is hidden)
//   engine.debug()        the engine's state, for tests and the console

import { flag } from "./physics.js";
import { subscription, tileKey, world_px, wrappedPoint, offset, dog_looks, kinds, drawn_kinds, setLevel, levels, largestHerd, cow_count } from "./scene.js";
import { edgeScroll } from "./pointer.js";
import { bumpedKind } from "./quips.js";

// A stall catches up at most this many ticks; the rest are dropped, never owed.
export const most_catch_up_ticks = 8;
// The most of the human's inputs at one tick.
export const most_humans = 16;
// The park is kept at most this often while it moves, and at once when it
// comes to rest, a leash comes off or a drag bumps.
export const keep_ms = 1000;

// **WHAT THE BROWSER KEEPS**: each level's park (physics_page.zig's
// `writePark`, the text `readPark` takes back), and the level played and
// the highest unlocked, as `level L of U`.
export const level_key = "dogpark.level";
export const parkKey = (n) => `dogpark.park.${n}`;

// The ticks a frame at `nowMs` runs, a tick every `tickMs`, the last having
// begun at `lastTickMs`: those whose start has come, at most `most_catch_up_ticks`;
// and when the last of them began (`nowMs` itself when some were dropped).
export function ticksDue(lastTickMs, nowMs, tickMs) {
  const due = Math.max(0, Math.floor((nowMs - lastTickMs) / tickMs));
  if (due <= most_catch_up_ticks) return { ticks: due, lastTickMs: lastTickMs + due * tickMs, dropped: 0 };
  return { ticks: most_catch_up_ticks, lastTickMs: nowMs, dropped: due - most_catch_up_ticks };
}

// The level played and the highest unlocked, from what the store kept:
// `level L of U`, 1 <= L <= U <= the levels there are; anything else
// (nothing kept, or another version's) is Level One of one.
export function levelsOf(text) {
  const m = /^level (\d+) of (\d+)$/.exec(text ?? "");
  const now = m ? Number(m[1]) : 0;
  const unlocked = m ? Number(m[2]) : 0;
  if (now < 1 || unlocked < now || unlocked > levels.length) return { now: 1, unlocked: 1 };
  return { now, unlocked };
}

const px = (v256) => v256 / 256;

export function createEngine({ physics, store, now, log }) {
  // The tick, from the physics itself (the wasm, already instantiated).
  const tick_ms = 1000 / physics.ticksPerSecond();

  // ── what the page shows ───────────────────────────────────────────────────

  const viewport = { parkX: 0, parkY: 0, width: 0, height: 0 };
  // "loading" | "playing"
  let status = { kind: "loading" };
  // The critters on the board, drawn; and where they were at the tick
  // before (the frames draw between).
  let dogs = new Map();
  let cows = new Map();
  let chickens = new Map();
  let poops = [];
  // Every critter of a kind the page has no art for (a kind World.roc adds
  // before the page knows it): { kind, id, parkX, parkY }.
  let others = [];
  let wasDogs = new Map();
  let wasCows = new Map();
  let wasChickens = new Map();
  // The others by `kind:id`, as they stood a tick ago.
  let wasOthers = new Map();
  const byKey = (os) => new Map(os.map((o) => [`${o.kind}:${o.id}`, o]));
  const wasViewport = { parkX: 0, parkY: 0 };
  let lastLeashed = { kind: "none" };

  // **THE LEVEL** played, and the highest the player has unlocked
  // (1-based); the board and scene.js's geometry are set to it.
  let level = { now: 1, unlocked: 1 };

  // ── the tick ──────────────────────────────────────────────────────────────

  // The last tick run: tick numbers carry on across a reload, as the park
  // keeps them.
  let tick = 0;
  // The human's inputs at the next tick, so far.
  let humansNext = 0;
  let clock = "unstarted";
  let alpha = 1;
  // Whether the page ticks: a rest or a release stops it; the human's input
  // starts it.
  let ticking = false;
  // The last walk's visit numbers, by "dog:ID" or "cow:ID" (1 to the walk's size).
  let visits = new Map();
  // Whether the pointer holds the leashed dog (a grab or leash until a
  // letgo or a bump).
  let holding = false;
  // The ticks' bumps so far, and what the last one hit (quips.js's
  // bumpedKind), for the page's word on it.
  let bumped = { count: 0, kind: "none" };
  // The pointer's displacements since the last tick, in 256ths ([dx, dy,
  // ms]), and the fractions of a 256th not yet given.
  let pendingDrag = [];
  const fraction = { x: 0, y: 0 };

  // ── what the browser keeps ────────────────────────────────────────────────

  // The park has changed since it was last kept; and when that was.
  let unkept = false;
  let keptMs = -Infinity;

  function keepPark() {
    store.write(parkKey(level.now), physics.writePark(tick));
    unkept = false;
    keptMs = now();
  }

  function keepLevels() {
    store.write(level_key, `level ${level.now} of ${level.unlocked}`);
  }

  // **ONE OF THE HUMAN'S INPUTS** at the next tick, on the board at once. A
  // 17th at one tick is dropped, as is one whose precondition fails; both
  // are said.
  function writeHuman(h, dog = 0) {
    const t = tick + 1;
    if (humansNext >= most_humans) {
      log.warn(`a ${h} at tick ${t} dropped: ${most_humans} inputs there already`);
      return false;
    }
    const r = physics.human(h, t, dog);
    if (r.refused !== undefined) {
      log.warn(`a ${h} ${dog} at tick ${t} refused (${r.refused}), dropped`);
      return false;
    }
    humansNext++;
    ticking = true;
    return true;
  }

  // ── the tick ──────────────────────────────────────────────────────────────

  // One tick's slot: when the page ticks, the next tick with the pointer's
  // drag and the edge bands'.
  function slot(panAt) {
    wasViewport.parkX = viewport.parkX;
    wasViewport.parkY = viewport.parkY;
    wasDogs = dogs;
    wasCows = cows;
    wasChickens = chickens;
    wasOthers = byKey(others);
    if (status.kind !== "playing") return;
    const dragOn = physics.drag() === "on";
    if (!(holding && dragOn) && panAt !== "none") {
      for (const e of edgeScroll({ kind: "pan", x: panAt.x, y: panAt.y }, viewport)) moveViewport(e.parkX, e.parkY);
    }
    if (pendingDrag.length && dragOn) ticking = true;
    if (!ticking) return;
    const t = tick + 1;
    const drag = pendingDrag;
    pendingDrag = [];
    // The edge band carries the held dog, and the viewport follows it as
    // far as the tick took it that way.
    const leashedDog = physics.leashed();
    const before = leashedDog === "none" ? null : dogs.get(leashedDog);
    let band = { x: 0, y: 0 };
    if (holding && dragOn && before) {
      const e = edgeScroll({ kind: "dog", dogId: leashedDog, parkX: before.parkX, parkY: before.parkY }, viewport);
      if (e.length) band = { x: offset(before.parkX, e[0].parkX), y: offset(before.parkY, e[0].parkY) };
      if (band.x !== 0 || band.y !== 0) drag.push([Math.round(band.x * 256), Math.round(band.y * 256), 0]);
    }
    const r = physics.tick(t, drag);
    tick = t;
    humansNext = 0;
    ticked(r.flags);
    if (r.flags & flag.bump) bumped = { count: bumped.count + 1, kind: bumpedKind(r.checked) ?? "none" };
    // The last walk's order, for the labels: kept until a tick walks again.
    if (r.walk.length) visits = new Map(r.walk.map((id, k) => [id, k + 1]));
    refresh(false);
    if (before && (band.x !== 0 || band.y !== 0)) {
      const after = dogs.get(leashedDog);
      const follow = (b, moved) => (b === 0 || Math.sign(moved) !== Math.sign(b) ? 0 : Math.sign(b) * Math.min(Math.abs(b), Math.abs(moved)));
      moveViewport(viewport.parkX + follow(band.x, offset(before.parkX, after.parkX)), viewport.parkY + follow(band.y, offset(before.parkY, after.parkY)));
    }
    if (r.flags & (flag.moved | flag.bump | flag.release)) unkept = true;
    // A park that stops is kept at once, so a reload finds it as it stood.
    if (unkept && (r.flags & (flag.rest | flag.release | flag.bump))) keepPark();
  }

  function ticked(flags) {
    if (flags & flag.bump) {
      // The drag is over: the pointer is let go (the leash stays on).
      holding = false;
      pendingDrag = [];
    }
    ticking = !(flags & (flag.rest | flag.release));
  }

  // ── what the page draws ───────────────────────────────────────────────────

  // The board's critters, in park px; `snap`: drawn where they are, with
  // no slide from before (a load, a new level, a start over).
  function refresh(snap) {
    const c = physics.critters();
    dogs = new Map(c.dogs.map((d) => [d.id, { id: d.id, emoji: dog_looks[d.id % dog_looks.length], parkX: px(d.x), parkY: px(d.y) }]));
    cows = new Map(c.cows.map((d) => [d.id, { id: d.id, parkX: px(d.x), parkY: px(d.y) }]));
    chickens = new Map(c.chickens.map((d) => [d.id, { id: d.id, parkX: px(d.x), parkY: px(d.y) }]));
    poops = c.poops.map((d) => ({ id: d.id, parkX: px(d.x), parkY: px(d.y) }));
    others = kinds.filter((k) => !drawn_kinds.includes(k.name)).flatMap((k) => c[`${k.name}s`].map((d) => ({ kind: k.name, id: d.id, parkX: px(d.x), parkY: px(d.y) })));
    if (snap) {
      wasDogs = dogs;
      wasCows = cows;
      wasChickens = chickens;
      wasOthers = byKey(others);
    }
  }

  // The viewport's top-left, named in the world: it scrolls on across the seam.
  function moveViewport(parkX, parkY) {
    Object.assign(viewport, wrappedPoint(parkX, parkY));
  }

  // The viewport on `at` (a point, or "none": the world's centre, the
  // park's middle).
  function openOn(at) {
    if (at !== "none") moveViewport(at.parkX, at.parkY);
    else {
      viewport.parkX = Math.round(world_px / 2 - viewport.width / 2);
      viewport.parkY = Math.round(world_px / 2 - viewport.height / 2);
    }
    wasViewport.parkX = viewport.parkX;
    wasViewport.parkY = viewport.parkY;
  }

  // Nothing in hand, leashed or ticking: a park as a load finds it.
  function still() {
    humansNext = 0;
    ticking = false;
    holding = false;
    pendingDrag = [];
    visits = new Map();
    lastLeashed = { kind: "none" };
    refresh(true);
  }

  // **A LEVEL ENTERED**: the board on its park as kept, else its first
  // layout (a kept park that doesn't read, from another version of the
  // game, is said and set aside); nothing leashed, nothing ticking.
  function enter(n, at) {
    level.now = n;
    setLevel(n);
    physics.reset(n - 1);
    tick = 0;
    const kept = store.read(parkKey(n));
    let found = "a new park";
    if (kept !== null) {
      const r = physics.readPark(kept);
      if (r.refused !== undefined) log.warn(`the park kept for level ${n} is refused (${r.refused}): its first layout instead`);
      else {
        tick = r.tick;
        found = `the park kept at tick ${tick}`;
      }
    }
    unkept = false;
    status = { kind: "playing" };
    still();
    // The scene's geometry is the level's now, so `at` may ask for it.
    openOn(typeof at === "function" ? at() : at);
    log.log(`level ${n} of ${level.unlocked}: ${found}, ${dogs.size} dogs and ${cows.size} cows`);
  }

  const won = () => largestHerd([...cows.values()]) === cow_count;

  return {
    load(measure, at = "none") {
      Object.assign(viewport, measure());
      level = levelsOf(store.read(level_key));
      enter(level.now, at);
    },

    resize({ width, height }) {
      viewport.width = width;
      viewport.height = height;
    },

    intent(i) {
      if (status.kind !== "playing") return;
      switch (i.kind) {
        case "grab": {
          const leashedNow = physics.leashed();
          if (leashedNow === i.dogId) {
            if (!writeHuman("grab")) return;
          } else {
            if (leashedNow !== "none" && !writeHuman("release", leashedNow)) return;
            if (!writeHuman("leash", i.dogId)) return;
          }
          holding = true;
          pendingDrag = [];
          fraction.x = 0;
          fraction.y = 0;
          lastLeashed = { kind: "dog", dogId: i.dogId };
          break;
        }
        case "drag": {
          if (!holding) return;
          // Whole 256ths go to the tick; the fraction stays for the next.
          const x = fraction.x + i.dx * 256;
          const y = fraction.y + i.dy * 256;
          const dx = Math.trunc(x);
          const dy = Math.trunc(y);
          fraction.x = x - dx;
          fraction.y = y - dy;
          const ms = clock === "unstarted" ? 0 : Math.max(0, Math.round(now() - clock.lastTickMs));
          if (dx !== 0 || dy !== 0) pendingDrag.push([dx, dy, ms]);
          break;
        }
        case "letgo":
          if (!holding) return;
          holding = false;
          writeHuman("letgo");
          break;
        case "pan":
          // The viewport moves now, and what the frames slide from with it.
          wasViewport.parkX += offset(viewport.parkX, i.parkX);
          wasViewport.parkY += offset(viewport.parkY, i.parkY);
          moveViewport(i.parkX, i.parkY);
          break;
        default: throw new Error(`no intent ${i.kind}`);
      }
    },

    frame(nowMs, panAt = "none") {
      if (clock === "unstarted") clock = { lastTickMs: nowMs };
      const due = ticksDue(clock.lastTickMs, nowMs, tick_ms);
      if (due.dropped > 0) log.warn(`a stall of ${Math.round(nowMs - clock.lastTickMs)} ms: ${due.ticks} ticks run, ${due.dropped} dropped`);
      for (let k = 0; k < due.ticks; k++) slot(panAt);
      clock.lastTickMs = due.lastTickMs;
      alpha = Math.min(1, Math.max(0, (nowMs - clock.lastTickMs) / tick_ms));
      if (unkept && now() - keptMs >= keep_ms) keepPark();
      return due.ticks;
    },

    view() {
      const points = (m) => new Map([...m].map(([id, p]) => [id, { parkX: p.parkX, parkY: p.parkY }]));
      const leashedDog = physics.leashed();
      const leashed = leashedDog === "none" ? { kind: "none" } : { kind: physics.drag() === "on" ? "in_hand" : "kept", dogId: leashedDog };
      return {
        viewport: { ...viewport },
        dogs: new Map([...dogs].map(([id, d]) => [id, { ...d }])),
        cows: [...cows.values()].map((c) => ({ ...c })),
        chickens: [...chickens.values()].map((c) => ({ ...c })),
        poops: poops.map((p) => ({ ...p })),
        others: others.map((o) => ({ ...o })),
        // The page holds the whole world: every tile.
        subscribed: new Set(subscription().map(tileKey)),
        leashed,
        lastLeashed: { ...lastLeashed },
        tick,
        alpha,
        was: { viewport: { ...wasViewport }, dogs: points(wasDogs), cows: points(wasCows), chickens: points(wasChickens), others: points(wasOthers) },
        status: { ...status },
        holding,
        bumped: { ...bumped },
        visits: new Map(visits),
        level: { ...level },
      };
    },

    // **ANOTHER LEVEL**: allowed when it is unlocked, or is the next one
    // and the level played is won (every cow in one herd), which unlocks
    // it. This level's park is kept, and the other's entered at once,
    // opening on `at` as a load does.
    goLevel(n, at = "none") {
      if (!Number.isInteger(n) || n < 1 || n > levels.length) return "no_such_level";
      if (n > level.unlocked + 1) return "locked";
      if (n === level.unlocked + 1 && !won()) return "not_won";
      keepPark();
      level.unlocked = Math.max(level.unlocked, n);
      level.now = n;
      keepLevels();
      enter(n, at);
      return "ok";
    },

    // **START OVER**: every critter back where the level began, kept so;
    // the view on the park's middle.
    startOver() {
      physics.reset(level.now - 1);
      still();
      keepPark();
      openOn("none");
    },

    keep() {
      if (status.kind === "playing") keepPark();
    },

    debug() {
      return { tick, ticking, holding, humansNext, unkept, level: { ...level } };
    },
  };
}
