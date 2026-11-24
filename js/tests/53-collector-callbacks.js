// What a builtin holds while its callback runs and makes garbage: the item
// `filter` and `find` keep, the items `sort` orders, the pairs
// `Array.from` maps and the array `map` builds.
function churn() {
  let n = 0;
  for (let i = 0; i < 3000; i++) {
    const g = [i];
    n = n + g[0];
  }
  return n;
}

const a = [{ n: 1 }, { n: 2 }, { n: 3 }];
const kept = a.filter((x, i, arr) => {
  if (i === 0) {
    arr.shift();
    x = null;
  }
  churn();
  return true;
});
console.log(kept.map((x) => x.n));

const b = [{ n: 1 }];
const found = b.find((x, i, arr) => {
  arr.pop();
  x = null;
  churn();
  return i === 0;
});
console.log(found.n);

const c = [{ n: 3 }, { n: 1 }, { n: 2 }];
const sorted = c.slice().sort((x, y) => {
  churn();
  return x.n - y.n;
});
console.log(sorted.map((x) => x.n));

const m = new Map([["a", { v: 1 }], ["b", { v: 2 }]]);
console.log(Array.from(m, ([k, v]) => {
  churn();
  return k + v.v;
}));

console.log([1, 2, 3].map((x) => {
  churn();
  return { x };
}).map((o) => o.x));

console.log([{ n: 1 }, { n: 2 }].reduce((acc, x) => {
  churn();
  return { n: acc.n + x.n };
}, { n: 0 }).n);
