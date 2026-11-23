// Garbage at the top level: an object made each pass and dropped.
let keep = 0;
for (let i = 0; i < 400000; i++) {
  const o = { x: i, y: i };
  keep = keep + o.x;
}
console.log(keep);
