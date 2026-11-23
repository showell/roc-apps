// Map and Set: insertion order, SameValueZero keys, their methods, their
// iterators and for ... of, and console.log's way of showing them.
const m = new Map();
m.set("a", 1).set("b", 2).set(1, "one");
console.log(m, m.size, m.get("a"), m.get("zz"), m.has("b"), m.has("1"));
m.set("a", 100);
console.log([...m], m.size);
console.log(m.delete("b"), m.delete("b"), m.size, m);
m.set("b", 3);
console.log([...m.keys()], [...m.values()], [...m.entries()]);

const keys = new Map([
  [NaN, "not a number"],
  [0, "zero"],
  [null, "null"],
  [undefined, "undefined"],
  [true, "true"],
]);
console.log(keys.get(NaN), keys.get(-0), keys.get(null), keys.get(undefined), keys.get(true));
const objectKey = { id: 1 };
const sameShape = { id: 1 };
const byObject = new Map([[objectKey, "found"]]);
console.log(byObject.get(objectKey), byObject.get(sameShape), byObject);

const s = new Set([3, 1, 3, 2, 1, NaN, NaN, 0, -0, "3"]);
console.log(s, s.size, s.has(NaN), s.has(-0), s.has("1"));
s.add(4).add(1);
s.delete(3);
console.log([...s], Array.isArray([...s]));
console.log(new Set("hello"), new Set(), new Map(), new Set(null));

const counts = new Map();
for (const word of "the cat and the hat and the bat".split(" ")) {
  counts.set(word, (counts.get(word) ?? 0) + 1);
}
for (const [word, n] of counts) {
  console.log(word, n);
}
const seen = [];
counts.forEach((n, word, map) => seen.push(`${word}=${n}:${map === counts}`));
console.log(seen.join(" "));
const setSeen = [];
new Set(["x", "y"]).forEach((v, k, set) => setSeen.push(v + k + set.size));
console.log(setSeen);

const live = new Map([
  ["a", 1],
  ["b", 2],
  ["c", 3],
]);
for (const [k] of live) {
  if (k === "a") {
    live.delete("b");
    live.set("d", 4);
  }
  console.log("visit", k);
}

const it = live.keys();
for (const k of it) {
  console.log("first", k);
  break;
}
console.log([...it], [...it]);

for (const [i, v] of ["x", "y"].entries()) {
  console.log(i, v);
}
console.log([..."ab".split("").keys()], [...[5, 6].values()]);

const [first, second] = new Set([10, 20, 30]);
const [[k1, v1]] = new Map([["key", "value"]]);
console.log(first, second, k1, v1);

const nested = new Map([
  ["list", [1, 2, 3]],
  ["set", new Set([new Map([[1, { deep: { deeper: true } }]])])],
]);
console.log(nested);
console.log({ inside: new Map([["k", new Set([1])]]) }, [new Set([[1, 2]])]);
const big = new Map();
for (let i = 0; i < 12; i++) big.set(`key${i}`, i * i);
console.log(big);
const many = new Set();
for (let i = 0; i < 30; i++) many.add(i);
console.log(many);
console.log(String(m), `${s}`, typeof m, typeof s);
m.clear();
console.log(m, m.size);
try {
  Map();
} catch (e) {
  console.log(e.name, e.message);
}
try {
  new Map([1]);
} catch (e) {
  console.log(e.name, e.message);
}
