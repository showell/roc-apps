// The same garbage made inside a call, as most programs make theirs.
function main() {
  let keep = 0;
  for (let i = 0; i < 400000; i++) {
    const o = { x: i, y: i };
    keep = keep + o.x;
  }
  return keep;
}
console.log(main());
