// Destructuring in declarations, assignments and `for ... of`: array
// patterns with holes, defaults and rest; object patterns with renames,
// defaults and rest; patterns inside patterns.
const [a, , b, ...more] = [1, 2, 3, 4, 5];
console.log(a, b, more);

const [x = 10, y = 20, z = x + y] = [1];
console.log(x, y, z);

const { p, q: why = 2, ...others } = { p: 1, r: 3, s: 4 };
console.log(p, why, others);

const {
  name,
  pos: [row, col],
  tags: [first, ...restTags] = ["none"],
} = { name: "ann", pos: [3, 4] };
console.log(name, row, col, first, restTags);

const [h, ...letters] = "hey";
console.log(h, letters);

const { length } = "four";
console.log(length);

let left = 1;
let right = 2;
[left, right] = [right, left];
console.log(left, right);

const box = { inner: [0, 0] };
let cursor;
({ cursor = "start", ...cursor } = { k: 1 });
console.log(cursor);
[box.inner[1], box.first] = ["one", "two"];
console.log(box);

const pairs = [
  ["a", 1],
  ["b", 2],
];
for (const [key, value] of pairs) {
  console.log(key, value);
}
for (const { id, size = "m" } of [{ id: 1 }, { id: 2, size: "l" }]) {
  console.log(id, size);
}

const makers = [];
for (const [n, label = `item ${n}`] of [[1], [2, "two"]]) {
  makers.push(() => label);
}
console.log(makers.map((f) => f()));

const named = { f: () => 1 };
const { g = function () {}, h: hidden = () => 2 } = named;
console.log(g, hidden, named.f);

const swap = ([m, n]) => [n, m];
console.log(swap([1, 2]));

const nested = [[1, [2, [3]]]];
const [[one, [two, [three]]]] = nested;
console.log(one + two + three);
