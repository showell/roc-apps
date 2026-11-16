// The physics, as the page calls it: physics.wasm's exports
// (src/physics_page.zig, compiled to wasm32) behind plain JavaScript
// values. No state of its own: the board lives in the wasm, and a park's
// text is written and read there (the page never formats a number of it).
//
//   createPhysics(exports)
//     raw                          the exports themselves (tests, the console)
//     ticksPerSecond()             the physics' clock: a tick every 1000 / this ms
//     reset(level)                 a new game of `level` (Level One is 0):
//                                  its first layout, nothing leashed
//     leashed()                    the leashed dog's number, or "none"
//     drag()                       "none" | "on" | { ended: tick }
//     human(h, dog)                h: "release" | "leash" | "grab" | "letgo",
//                                  for the next tick: {} or { refused }
//     tick(t, drag)                drag: [[dx, dy, ms], ...] in 256ths, as the
//                                  pointer made them; merged, capped and run:
//                                  { checked (text), drag (as capped), flags,
//                                    walk: ["KIND:ID"], the last walk's
//                                    critters in visit order }
//     critters()                   { dogs: [{ id, x, y }], cows: [...], ... }, in 256ths,
//                                  the critters the board has, a list for
//                                  each kind (its name + "s"), and poops
//     writePark(t)                 the park as text, `t` the last tick run
//     readPark(text)               a park's text onto the board's level:
//                                  { tick }, nothing leashed; or { refused:
//                                  "unreadable" | "other_level" |
//                                  "other_critters" | "overlapping" }, the
//                                  board unchanged

import { kinds as world_kinds } from "./world.js";

// physics_page.zig's Flag.
export const flag = { bump: 1, rest: 2, release: 4, moved: 8 };

const human_kinds = ["release", "leash", "grab", "letgo"];
// physics_page.zig's ParkRefusal, by number.
const park_refusals = ["unreadable", "other_level", "other_critters", "overlapping"];

export function createPhysics(x) {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const bytes = (ptr, len) => new Uint8Array(x.memory.buffer, ptr, len);
  const ints = () => new Int32Array(x.memory.buffer, x.ints(), x.intsCap());
  // THE KINDS, by number, as the wasm counts them (its world, which
  // world.js names: test_page_modules.mjs holds the two together): each
  // one's name, how many, and where its critters begin among all.
  const kinds = Array.from({ length: x.kindCount() }, (_, k) => ({ name: world_kinds[k].name, base: x.kindBase(k), size: x.kindSize(k) }));
  const nameOf = (i) => {
    const k = kinds.find((k) => i >= k.base && i < k.base + k.size);
    return `${k.name}:${i - k.base}`;
  };
  // The last tick's walk: the critters it moved, in visit order, as
  // "KIND:ID" ("dog:3", "cow:0").
  const takeWalk = () => [...new Uint16Array(x.memory.buffer, x.walkAt(), x.walkLen())].map(nameOf);
  const text = (len) => decoder.decode(bytes(x.outBuf(), len));
  const putDrag = (drag) => {
    const a = ints();
    const room = Math.floor(a.length / 3);
    // Past the room, the rest are added into the last (the shared Zig adds
    // every one past 16 into the 16th, so the sum is the same).
    const list = drag.length <= room ? drag : [...drag.slice(0, room - 1), drag.slice(room - 1).reduce((s, d) => [s[0] + d[0], s[1] + d[1], d[2]])];
    list.forEach((d, i) => { a[3 * i] = d[0]; a[3 * i + 1] = d[1]; a[3 * i + 2] = d[2]; });
    return list.length;
  };
  const takeDrag = (n) => {
    const a = ints();
    const out = [];
    for (let i = 0; i < n; i++) out.push([a[3 * i], a[3 * i + 1], a[3 * i + 2]]);
    return out;
  };
  const listOf = (positions, known, count) => {
    const p = new Int32Array(x.memory.buffer, positions, 2 * count);
    const k = new Uint8Array(x.memory.buffer, known, count);
    const out = [];
    for (let i = 0; i < count; i++) if (k[i] === 1) out.push({ id: i, x: p[2 * i], y: p[2 * i + 1] });
    return out;
  };

  return {
    // The wasm's exports themselves, for tests and the console.
    raw: x,
    ticksPerSecond: () => x.ticksPerSecond(),
    reset: (level) => x.reset(level),
    leashed() {
      const d = x.leashedDog();
      return d < 0 ? "none" : d;
    },
    drag() {
      const d = x.dragOf();
      return d === -1 ? "none" : d === -2 ? "on" : { ended: d };
    },
    human(h, dog = 0) {
      const kind = human_kinds.indexOf(h);
      if (kind < 0) throw new Error(`no human input ${h}`);
      const r = x.human(kind, dog);
      return r < 0 ? { refused: -1 - r } : {};
    },
    tick(t, drag) {
      const len = x.tick(t, putDrag(drag));
      return { checked: text(len), drag: takeDrag(x.cappedLen()), flags: x.tickFlags(), walk: takeWalk() };
    },
    critters() {
      const out = { poops: listOf(x.poopsAt(), x.poopKnown(), x.poopCount()) };
      for (const k of kinds) out[`${k.name}s`] = listOf(x.crittersAt() + 8 * k.base, x.crittersKnown() + k.base, k.size);
      return out;
    },
    writePark: (t) => text(x.writePark(t)),
    readPark(park) {
      const b = encoder.encode(park);
      if (b.length > x.inCap()) return { refused: "unreadable" };
      bytes(x.inBuf(), b.length).set(b);
      const r = x.readPark(b.length);
      return r < 0 ? { refused: park_refusals[-1 - r] } : { tick: x.parkTick() };
    },
  };
}

// The wasm's exports, from its bytes (node) or a response (the page).
export async function instantiatePhysics(source) {
  const { instance } = source instanceof Response
    ? await WebAssembly.instantiateStreaming(source)
    : await WebAssembly.instantiate(source);
  return createPhysics(instance.exports);
}
