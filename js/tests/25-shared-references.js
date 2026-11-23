const a = [1, 2, 3];
const b = a;
b.push(4);
console.log(a, a === b);
const o = { items: a };
o.items.push(5);
console.log(a.length, o);
function addTo(list, x) {
  list.push(x);
}
addTo(a, 6);
console.log(b);
const grid = [];
for (let r = 0; r < 3; r++) {
  const row = [];
  for (let c = 0; c < 3; c++) row.push(r * 3 + c);
  grid.push(row);
}
grid[1][1] = "center";
console.log(grid);
