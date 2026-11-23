// Object spread, optional chaining and the logical assignments.
const base = { a: 1, b: 2 };
const merged = { ...base, b: 20, c: 3, ...{ d: 4 } };
console.log(merged, base);
console.log({ ...[10, 20] }, { ..."hi" }, { ...null, ...undefined, ...5, ...true });
console.log({ z: 0, 2: "two", ...{ 1: "one", y: 9 } });
const copy = { ...base };
copy.a = 100;
console.log(copy.a, base.a);
const counted = (o) => ({ ...o, count: (o.count ?? 0) + 1 });
console.log(counted(counted({ name: "n" })));

const user = { name: "ann", address: { city: "paris" }, tags: ["x"], greet() { return "hi"; } };
const nobody = null;
console.log(user?.name, user.address?.city, user.phone?.number, nobody?.name);
console.log(user?.["name"], nobody?.["name"], user.tags?.[0], user.tags?.[5]);
console.log(user.greet?.(), user.missing?.(), nobody?.greet(), user?.greet());
console.log(nobody?.a.b.c.d, user.phone?.a.b.c);
const maybe = undefined;
console.log(maybe?.(), typeof maybe?.x);
const list = [1, 2, 3];
console.log(list?.map((n) => n * 2), list?.length, "word"?.length);
let calls = 0;
const counter = () => ++calls;
nobody?.[counter()];
console.log(calls);
console.log((nobody?.a) ?? "fallback");

let x = null;
x ??= "set";
x ??= "not again";
console.log(x);
let y = 0;
y ||= 5;
let z = 1;
z ||= 99;
console.log(y, z);
let w = 1;
w &&= 7;
let v = 0;
v &&= 7;
console.log(w, v);
const opts = { size: 0 };
opts.size ||= 10;
opts.color ??= "red";
opts.color ??= "blue";
opts["size"] &&= opts.size * 2;
console.log(opts);
const seen = [];
const cache = {};
function measured(key) {
  seen.push(key);
  return key.length;
}
function memo(key) {
  return (cache[key] ??= measured(key));
}
console.log(memo("abc"), memo("abc"), memo("de"), seen);
const f = null;
let named;
named ||= function () {};
console.log(named);
try {
  const c = 1;
  c ||= 2;
  console.log("no write, so no error");
  c &&= 2;
} catch (e) {
  console.log(e.name, e.message);
}
