// An array and a closure made each pass by `map`.
const a = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
let t = 0;
for (let i = 0; i < 20000; i++) {
  const b = a.map((x) => x + i);
  t = t + b[0];
}
console.log(t);
