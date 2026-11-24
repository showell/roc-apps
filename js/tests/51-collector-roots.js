// Values held only through one kind of root each, with enough garbage made
// meanwhile for the VM's collector to run: a value the collector frees too
// early prints wrong, or stops the run.
function churn() {
  let n = 0;
  for (let i = 0; i < 3000; i++) {
    const g = { i, list: [i, i] };
    n = n + g.list.length;
  }
  return n;
}

// A box only a live frame holds: the closure that captured it is gone.
function boxed() {
  let kept = { name: "box" };
  let peek = () => kept;
  peek = null;
  churn();
  return kept.name;
}
console.log(boxed());

// A caller's half-made values: an array literal's first item, and the
// arguments made so far, wait on the stack while a later one is made.
function pair(a, b) {
  return a.x + b.x;
}
function later() {
  churn();
  return { x: 2 };
}
console.log([{ x: 1 }, later()][0].x, pair({ x: 10 }, later()));

// A value only an unwinding `try` holds, through a `finally` that makes
// garbage before the throw goes on.
try {
  try {
    throw { message: "held" };
  } finally {
    churn();
  }
} catch (e) {
  console.log(e.message);
}

// A Map's keys and values, and the iterator a `for ... of` walks, held only
// by the loop's slots.
function walked() {
  const out = [];
  for (const [k, v] of new Map([[{ k: "a" }, { v: 1 }], [{ k: "b" }, { v: 2 }]])) {
    churn();
    out.push(k.k + v.v);
  }
  return out.join(",");
}
console.log(walked());

// A closure that returns a closure: environments held through environments.
function adder(a) {
  const box = { a };
  return (b) => (c) => box.a + b + c;
}
const add = adder(1)(2);
churn();
console.log(add(3));

// The builtins, after many collections.
churn();
console.log(Math.max(1, 2), [3, 1, 2].sort(), Object.keys({ p: 1, q: 2 }));
