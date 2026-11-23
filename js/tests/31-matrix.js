function multiply(a, b) {
  const out = [];
  for (let i = 0; i < a.length; i++) {
    const row = [];
    for (let j = 0; j < b[0].length; j++) {
      let sum = 0;
      for (let k = 0; k < b.length; k++) sum += a[i][k] * b[k][j];
      row.push(sum);
    }
    out.push(row);
  }
  return out;
}
const m = [[1, 2], [3, 4]];
let p = m;
for (let i = 0; i < 5; i++) p = multiply(p, m);
console.log(p);
console.log(multiply([[1, 2, 3]], [[4], [5], [6]]));
