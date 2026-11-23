for (const x of [1, 2, 3]) console.log(x);
for (const c of "hey") console.log(c);
const grow = [1];
for (const x of grow) {
  if (x < 5) grow.push(x + 1);
}
console.log(grow);
const fs = [];
for (const name of ["a", "b"]) fs.push(() => name);
console.log(fs[0](), fs[1]());
for (let x of [1, 2, 3]) {
  x = x * 10;
  if (x === 20) continue;
  console.log(x);
}
