// do ... while, and labelled break and continue.
let n = 0;
do {
  n++;
} while (n < 5);
console.log(n);

let once = 0;
do once++;
while (false);
console.log(once);

let k = 10;
do {
  k--;
  if (k === 7) continue;
  if (k === 4) break;
  console.log("k", k);
} while (k > 0);

const grid = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
];
let found = null;
outer: for (const row of grid) {
  for (const cell of row) {
    if (cell === 5) {
      found = cell;
      break outer;
    }
  }
}
console.log(found);

const skipped = [];
rows: for (let i = 0; i < 3; i++) {
  for (let j = 0; j < 3; j++) {
    if (j === 1) continue rows;
    skipped.push(`${i}${j}`);
  }
}
console.log(skipped);

let count = 0;
loop: while (true) {
  count++;
  inner: do {
    if (count < 3) continue loop;
    break loop;
  } while (true);
}
console.log(count);

block: {
  console.log("in the block");
  if (count === 3) break block;
  console.log("never");
}
console.log("after the block");

a: b: for (let i = 0; i < 3; i++) {
  if (i === 1) continue a;
  if (i === 2) break b;
  console.log("i", i);
}

const pairs = [];
search: for (const x of [1, 2, 3]) {
  switch (x) {
    case 2:
      continue search;
    case 3:
      break search;
  }
  pairs.push(x);
}
console.log(pairs);

function firstOver(list, limit) {
  let result = -1;
  scan: {
    for (const item of list) {
      if (item > limit) {
        result = item;
        break scan;
      }
    }
    result = 0;
  }
  return result;
}
console.log(firstOver([1, 5, 9], 4), firstOver([1, 2], 4));
