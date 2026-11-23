// A closure made and called each pass: its cell, and the pass's scope it
// holds, are both kept.
let t = 0;
for (let i = 0; i < 100000; i++) {
  const f = (x) => x + 1;
  t = f(t);
}
console.log(t);
