// Keys pass through a Map and a Set many times over, and walks under way
// meet the rest in order while deletes drop the gone entries.
const m = new Map();
for (let i = 0; i < 5000; i++) {
  m.set(i, i * 2);
  if (i >= 3) m.delete(i - 3);
}
console.log(m.size, [...m]);

const s = new Set();
for (let i = 0; i < 5000; i++) {
  s.add(`k${i}`);
  s.delete(`k${i - 2}`);
}
console.log(s.size, [...s]);

// A loop that deletes most of what it walks, and adds as it goes.
const walked = new Map();
for (let i = 0; i < 20; i++) walked.set(i, `v${i}`);
const met = [];
for (const [k, v] of walked) {
  met.push(k);
  if (k < 15) walked.delete(k + 1);
  if (k === 0) for (let j = 2; j < 14; j++) walked.delete(j);
  if (k === 19) walked.set(20, "late");
}
console.log(met.join(" "), walked.size, [...walked.keys()]);

// An iterator kept aside while the table is emptied and refilled.
const held = new Map([["a", 1], ["b", 2], ["c", 3], ["d", 4]]);
const it = held.keys();
const first = [];
for (const k of it) {
  first.push(k);
  break;
}
held.delete("b");
held.delete("c");
held.delete("a");
held.set("e", 5);
held.set("b", 6);
const rest = [];
for (const k of it) rest.push(k);
console.log(first, rest, [...held]);

// forEach over a Set that deletes the entry after the one it is at, and
// re-adds the one it is at, so each comes round again at the end.
const ring = new Set([1, 2, 3, 4, 5, 6]);
const order = [];
let turns = 0;
ring.forEach((x) => {
  order.push(x);
  turns++;
  if (turns < 12) {
    ring.delete(x);
    ring.add(x);
  }
});
console.log(order.join(","), [...ring]);

// clear() under a walk: what is set after it is met.
const cleared = new Map([["x", 1], ["y", 2], ["z", 3]]);
const seen = [];
for (const [k] of cleared) {
  seen.push(k);
  if (k === "x") {
    cleared.clear();
    cleared.set("p", 4);
    cleared.set("q", 5);
  }
}
console.log(seen, cleared);

// Deleting every key while walking, then walking what is set after.
const all = new Map();
for (let i = 0; i < 50; i++) all.set(`n${i}`, i);
let total = 0;
for (const [k, v] of all) {
  total += v;
  all.delete(k);
}
all.set("again", 1);
console.log(total, all.size, [...all.entries()]);
