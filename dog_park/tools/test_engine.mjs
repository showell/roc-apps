// The engine (web/engine.js) on the real physics.wasm, its clock fake and
// its store a browser's storage the test can read (tools/lib/page_rig.mjs):
// the park, the level and the levels unlocked kept and picked up again, a
// store that keeps nothing, a kept park that doesn't read, the levels'
// rules, and the page's own rules around the human's inputs.
//
//     zig build && node --test tools/test_engine.mjs

import { test } from "node:test";
import assert from "node:assert/strict";
import { pageRig, memoryStore, blockedStore, laidOut, laidOutCritters, letGoTicks } from "./lib/page_rig.mjs";
import { level_key, parkKey, keep_ms } from "../web/engine.js";
import { offset, world_px, world_tiles, cow_px } from "../web/scene.js";

// A position in a park's text, from whole px.
const hex = (px) => `${px.toString(16)}.00`;

// A park's text with one critter moved to (x, y), its walk kept.
function moved(text, kind, n, x, y) {
  const lines = text.split("\n");
  const at = lines.findIndex((l) => l.startsWith(`${kind} ${n} `));
  assert.ok(at >= 0, `no ${kind} ${n} in the park`);
  const words = lines[at].split(" ");
  words[2] = `${hex(x)},${hex(y)}`;
  lines[at] = words.join(" ");
  return lines.join("\n");
}

// The dog nearest the screen's middle.
function middleDog(rig) {
  const v = rig.engine.view();
  const cx = v.viewport.parkX + v.viewport.width / 2;
  const cy = v.viewport.parkY + v.viewport.height / 2;
  return [...v.dogs.values()].sort((a, b) => Math.hypot(offset(cx, a.parkX), offset(cy, a.parkY)) - Math.hypot(offset(cx, b.parkX), offset(cy, b.parkY)))[0];
}

// A loaded page on `store`.
async function loaded(store, options = {}) {
  const rig = await pageRig({ store, ...options });
  rig.load();
  return rig;
}

// A leash of the middle dog and `n` ticks of a drag, `dx` and `dy` px a
// tick, then a letgo: the same human's acts, whichever page.
function leashAndDrag(rig, n, dx, dy) {
  const dog = middleDog(rig);
  rig.engine.intent({ kind: "grab", dogId: dog.id });
  for (let k = 0; k < n; k++) {
    rig.engine.intent({ kind: "drag", dx, dy });
    rig.ticks(1);
  }
  rig.engine.intent({ kind: "letgo" });
  return dog.id;
}

test("a first load: Level One of one, its first layout, nothing leashed, the page not ticking; nothing is kept until the park moves", async () => {
  const store = memoryStore();
  const rig = await loaded(store);
  const v = rig.engine.view();
  assert.deepEqual(v.level, { now: 1, unlocked: 1 });
  assert.deepEqual(rig.physics.critters(), laidOutCritters(1));
  assert.equal(v.dogs.size, laidOutCritters(1).dogs.length);
  assert.equal(v.cows.length, 2);
  assert.deepEqual(v.leashed, { kind: "none" });
  // The view on the park's middle.
  assert.deepEqual([v.viewport.parkX, v.viewport.parkY], [world_px / 2 - 640, world_px / 2 - 400]);
  rig.ticks(40);
  assert.equal(rig.engine.debug().ticking, false);
  assert.equal(rig.engine.view().tick, 0);
  assert.deepEqual(store.writes, []);
});

test("a drag moves the park and it is kept: a new page on the same storage finds every critter where the drag left it, nothing leashed, its tick carried on", async () => {
  const store = memoryStore();
  const rig = await loaded(store);
  const dog = leashAndDrag(rig, 40, 6, 2);
  assert.notDeepEqual(rig.physics.critters(), laidOutCritters(1));
  // Kept while it moved, at most once a keep_ms (40 ticks are 2.5 s).
  const during = store.writes.filter((k) => k === parkKey(1)).length;
  assert.ok(during >= 2 && during <= 1 + Math.ceil((40 * 62.5) / keep_ms), `${during} keeps`);
  // The leash comes off, the park rests, and it is kept as it stands.
  rig.ticks(letGoTicks() + 2);
  assert.deepEqual(rig.engine.view().leashed, { kind: "none" });
  assert.equal(rig.engine.debug().ticking, false);
  assert.equal(rig.engine.debug().unkept, false);
  const tick = rig.engine.view().tick;
  assert.ok(tick > 300);
  const before = rig.physics.critters();
  // A reload: another page on the same storage.
  const again = await loaded(store);
  assert.deepEqual(again.physics.critters(), before);
  assert.deepEqual(again.engine.view().leashed, { kind: "none" });
  assert.equal(again.engine.view().tick, tick);
  assert.match(again.said.find((s) => s[0] === "log").slice(1).join(" "), new RegExp(`the park kept at tick ${tick}`));
  // A drag there plays on from it: the dog moves from where it was left.
  again.engine.intent({ kind: "grab", dogId: dog });
  again.engine.intent({ kind: "drag", dx: 3, dy: 0 });
  again.ticks(1);
  assert.equal(again.engine.view().tick, tick + 1);
  assert.equal(again.engine.view().dogs.get(dog).parkX, before.dogs.find((d) => d.id === dog).x / 256 + 3);
});

test("a park kept while a dog is leashed comes back with nothing leashed; the page is kept as it goes away (engine.keep)", async () => {
  const store = memoryStore();
  const rig = await loaded(store);
  const dog = middleDog(rig).id;
  rig.engine.intent({ kind: "grab", dogId: dog });
  rig.engine.intent({ kind: "drag", dx: 5, dy: 0 });
  rig.ticks(1);
  rig.engine.intent({ kind: "drag", dx: 5, dy: 0 });
  rig.ticks(1);
  // The second tick's moves are kept only by the page's going away.
  rig.engine.keep();
  const again = await loaded(store);
  assert.deepEqual(again.physics.critters(), rig.physics.critters());
  assert.deepEqual(again.engine.view().leashed, { kind: "none" });
  assert.equal(again.engine.view().holding, false);
  assert.equal(again.engine.debug().ticking, false);
});

test("storage that keeps nothing: the game plays the same, the levels too, and each load starts afresh", async () => {
  const kept = await loaded(memoryStore());
  const blocked = await loaded(blockedStore());
  leashAndDrag(kept, 30, -4, 3);
  leashAndDrag(blocked, 30, -4, 3);
  kept.ticks(20);
  blocked.ticks(20);
  assert.deepEqual(blocked.physics.critters(), kept.physics.critters());
  assert.notDeepEqual(blocked.physics.critters(), laidOutCritters(1));
  const again = await loaded(blockedStore());
  assert.deepEqual(again.physics.critters(), laidOutCritters(1));
  assert.deepEqual(again.engine.view().level, { now: 1, unlocked: 1 });
});

test("a kept park that doesn't read is refused and said, and the level's first layout played: another version's text, another level's park, other critters", async () => {
  for (const [text, why] of [
    ["not a park", "unreadable"],
    [laidOut(2), "other_level"],
    [laidOut(1).replace(/\ncow 1 [^\n]*/, ""), "other_critters"],
    [moved(laidOut(1), "cow", 0, laidOutCritters(1).cows[1].x / 256, laidOutCritters(1).cows[1].y / 256), "overlapping"],
  ]) {
    const store = memoryStore();
    store.kept.set(parkKey(1), text);
    const rig = await loaded(store);
    assert.deepEqual(rig.physics.critters(), laidOutCritters(1), why);
    assert.match(rig.warnings().join("\n"), new RegExp(`the park kept for level 1 is refused \\(${why}\\): its first layout instead`));
  }
  // The near miss: Level One's own layout, kept, reads, and says nothing.
  const store = memoryStore();
  store.kept.set(parkKey(1), laidOut(1, 77));
  const rig = await loaded(store);
  assert.deepEqual(rig.warnings(), []);
  assert.equal(rig.engine.view().tick, 77);
});

// Level One with its two cows side by side in the empty ring round the
// park: won.
function wonPark() {
  return moved(moved(laidOut(1, 5), "cow", 0, 100, 100), "cow", 1, 100 + cow_px + 4, 100);
}

test("the levels: the next is locked until this one is won; won, it unlocks and is played at once, each level's park kept apart, and the levels kept", async () => {
  const store = memoryStore();
  const rig = await loaded(store);
  assert.equal(rig.engine.goLevel(2), "not_won");
  for (const n of [0, 3, 1.5]) assert.equal(rig.engine.goLevel(n), "no_such_level");
  assert.deepEqual(rig.engine.view().level, { now: 1, unlocked: 1 });
  assert.equal(store.read(level_key), null);

  store.kept.set(parkKey(1), wonPark());
  const won = await loaded(store);
  assert.deepEqual(won.engine.view().level, { now: 1, unlocked: 1 });
  assert.equal(won.engine.goLevel(2), "ok");
  let v = won.engine.view();
  assert.deepEqual(v.level, { now: 2, unlocked: 2 });
  assert.equal(store.read(level_key), "level 2 of 2");
  assert.equal(v.cows.length, 8);
  assert.deepEqual(won.physics.critters(), laidOutCritters(2));
  // Level Two played: a drag there, kept.
  leashAndDrag(won, 20, 5, 0);
  won.ticks(letGoTicks() + 2);
  const two = won.physics.critters();
  assert.notDeepEqual(two, laidOutCritters(2));
  // Back to Level One, unlocked: its won park as it was left.
  assert.equal(won.engine.goLevel(1), "ok");
  v = won.engine.view();
  assert.deepEqual(v.level, { now: 1, unlocked: 2 });
  assert.equal(store.read(level_key), "level 1 of 2");
  assert.deepEqual([v.cows[0].parkX, v.cows[1].parkX], [100, 100 + cow_px + 4]);
  // A reload opens on the level played; Level Two's park is its own.
  const again = await loaded(store);
  assert.deepEqual(again.engine.view().level, { now: 1, unlocked: 2 });
  assert.equal(again.engine.goLevel(2), "ok");
  assert.deepEqual(again.physics.critters(), two);
});

test("the levels with storage that keeps nothing: won, the next is played at once all the same", async () => {
  const store = memoryStore();
  store.kept.set(parkKey(1), wonPark());
  // A store that hands out a won park once, then keeps nothing.
  const once = { read: (k) => store.read(k), write: () => {}, remove: () => {} };
  const rig = await loaded(once);
  assert.equal(rig.engine.goLevel(2), "ok");
  assert.deepEqual(rig.engine.view().level, { now: 2, unlocked: 2 });
  assert.equal(rig.engine.view().cows.length, 8);
});

test("start over: every critter back where the level began, kept so, the view on the park's middle; tick numbers carry on", async () => {
  const store = memoryStore();
  const rig = await loaded(store);
  leashAndDrag(rig, 20, 4, 4);
  rig.engine.intent({ kind: "pan", parkX: 10, parkY: 10 });
  const tick = rig.engine.view().tick;
  rig.engine.startOver();
  const v = rig.engine.view();
  assert.deepEqual(rig.physics.critters(), laidOutCritters(1));
  assert.deepEqual(v.leashed, { kind: "none" });
  assert.deepEqual([v.viewport.parkX, v.viewport.parkY], [world_px / 2 - 640, world_px / 2 - 400]);
  const again = await loaded(store);
  assert.deepEqual(again.physics.critters(), laidOutCritters(1));
  assert.equal(again.engine.view().tick, tick);
});

test("at most 16 of the human's inputs a tick: the 17th is dropped and said", async () => {
  const rig = await loaded(memoryStore());
  const [a, b] = [...rig.engine.view().dogs.keys()];
  // Between two frames every input takes the next tick. A grab of dog a
  // (a leash), then seven of b, a, ...: a release and a leash each, 15;
  // then a grab of the dog leashed is the 16th, and a 17th is dropped.
  rig.engine.intent({ kind: "grab", dogId: a });
  for (let i = 1; i <= 7; i++) rig.engine.intent({ kind: "grab", dogId: i % 2 ? b : a });
  rig.engine.intent({ kind: "grab", dogId: b });
  assert.equal(rig.engine.debug().humansNext, 16);
  rig.engine.intent({ kind: "grab", dogId: b });
  assert.equal(rig.engine.debug().humansNext, 16);
  assert.match(rig.warnings().join("\n"), /a grab at tick 1 dropped: 16 inputs there already/);
  // The tick runs them, and the next tick takes inputs again.
  rig.ticks(1);
  assert.equal(rig.engine.debug().humansNext, 0);
  assert.deepEqual(rig.engine.view().leashed, { kind: "in_hand", dogId: b });
});

// Level Two, with dog 0, dog 1 and cow 0 in a row in the empty ring round
// the park: dog 1 35 px east of dog 0 (7 px between their squares), and
// the cow touching dog 1's east side, so dog 1 can't step out of the
// drag's way (straight east, away from dog 0), and the drag bumps it.
function pinnedPark() {
  return moved(moved(moved(laidOut(2), "dog", 0, 100, 100), "dog", 1, 135, 100), "cow", 0, 170, 100);
}

test("a bump lets go of the pointer: the drags after it are not the dog's, the leash stays, and the view says what it hit (the page's quip)", async () => {
  const store = memoryStore();
  store.kept.set(level_key, "level 2 of 2");
  store.kept.set(parkKey(2), pinnedPark());
  const rig = await loaded(store, { screen: { width: 200, height: 200 }, at: { parkX: 0, parkY: 0 } });
  rig.engine.intent({ kind: "grab", dogId: 0 });
  rig.ticks(4);
  assert.equal(rig.engine.view().holding, true);
  // A step east, kept at the frame's end (the first keep).
  rig.engine.intent({ kind: "drag", dx: 1, dy: 0 });
  rig.ticks(1);
  assert.deepEqual(rig.engine.view().bumped, { count: 0, kind: "none" });
  assert.deepEqual(store.writes, [parkKey(2)]);
  rig.engine.intent({ kind: "drag", dx: 30, dy: 0 });
  rig.ticks(1);
  assert.equal(rig.engine.view().holding, false);
  assert.deepEqual(rig.engine.view().bumped, { count: 1, kind: "dog" });
  // Kept at the bump, though the last keep was a tick ago.
  assert.equal(rig.engine.debug().unkept, false);
  assert.deepEqual(store.writes, [parkKey(2), parkKey(2)]);
  assert.equal(store.read(parkKey(2)), rig.physics.writePark(rig.engine.view().tick));
  const at = rig.engine.view().dogs.get(0).parkX;
  rig.engine.intent({ kind: "drag", dx: 30, dy: 0 });
  rig.ticks(3);
  assert.deepEqual(rig.engine.view().leashed, { kind: "kept", dogId: 0 });
  assert.equal(rig.engine.view().dogs.get(0).parkX, at);
});

test("across the seam: a pan past the world's corner names the viewport in the world and glides the short way; the page holds every tile", async () => {
  const rig = await loaded(memoryStore());
  rig.ticks(2);
  rig.engine.intent({ kind: "pan", parkX: -600, parkY: world_px + 100 });
  const v = rig.engine.view();
  assert.deepEqual([v.viewport.parkX, v.viewport.parkY], [world_px - 600, 100]);
  // What the frames slide from moved with it: no glide across the world.
  // (Named either side of the seam: the frames' `between` takes the short way.)
  assert.deepEqual([offset(v.was.viewport.parkX, v.viewport.parkX), offset(v.was.viewport.parkY, v.viewport.parkY)], [0, 0]);
  assert.equal(v.subscribed.size, world_tiles * world_tiles);
  for (const k of [`${world_tiles - 1},0`, "0,0", `${world_tiles - 2},${world_tiles - 1}`, "1,2"]) assert.ok(v.subscribed.has(k), `${k} held`);
});
