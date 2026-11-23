// probe: fixed
// A push and a pop, W times, onto an array of N items. Flat means each
// leaves the array where it is; linear means a pop leaves a list that the
// next push copies.
const a = [];
for (let i = 0; i < N; i++) a.push(i);
for (let i = 0; i < W; i++) {
  a.push(i);
  a.pop();
}
console.log(a.length);
