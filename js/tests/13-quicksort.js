function quicksort(xs) {
  if (xs.length <= 1) return xs;
  const pivot = xs[0];
  const rest = xs.slice(1);
  const less = rest.filter((x) => x < pivot);
  const more = rest.filter((x) => x >= pivot);
  return quicksort(less).concat([pivot], quicksort(more));
}
let seed = 7;
function next() {
  seed = (seed * 31 + 11) % 1000;
  return seed;
}
const xs = [];
for (let i = 0; i < 40; i++) xs.push(next());
console.log(quicksort(xs));
