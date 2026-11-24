// Calls nest thousands deep, as in node, and a recursion with no end throws
// node's RangeError, which a `catch` takes like any other error. The depths
// stay well under node's own limit, which is near 10,000 simple calls.
function sumTo(n) {
  return n === 0 ? 0 : n + sumTo(n - 1);
}
console.log(sumTo(5000));

function isEven(n) {
  return n === 0 ? true : isOdd(n - 1);
}
function isOdd(n) {
  return n === 0 ? false : isEven(n - 1);
}
console.log(isEven(4000), isOdd(3999), isEven(3001));

// A list built and walked by recursion, its cells held by the waiting calls.
function built(n) {
  return n === 0 ? null : { n, next: built(n - 1) };
}
function length(list) {
  return list === null ? 0 : 1 + length(list.next);
}
const list = built(1500);
console.log(length(list), list.n, list.next.next.n);

function forever(n) {
  return forever(n + 1) + 1;
}
for (let round = 0; round < 2; round++) {
  try {
    forever(0);
  } catch (e) {
    console.log(round, e.name, e.message);
  }
}
console.log(sumTo(4000));

// A recursion through a builtin's callback, nested a hundred deep.
function depthByMap(n) {
  return n === 0 ? 0 : [n].map((x) => depthByMap(x - 1))[0] + 1;
}
console.log(depthByMap(100));
