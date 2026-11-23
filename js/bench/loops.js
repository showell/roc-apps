// The statement path: nested loops over local variables and an array,
// 200,000 passes of the inner body.
const a = [];
for (let i = 0; i < 100; i++) a.push(i);
let total = 0;
for (let k = 0; k < 2000; k++) {
  for (let i = 0; i < 100; i++) {
    total = total + a[i] * k;
  }
}
console.log(total);
