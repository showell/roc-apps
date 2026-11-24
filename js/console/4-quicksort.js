// Quicksort
const NUMBERS = [5, 3, 9, 1, 7, 2, 8, 6, 4, 0]; // the numbers sorted

function quicksort(xs) {
  if (xs.length <= 1) return xs;
  const pivot = xs[0];
  const rest = xs.slice(1);
  return quicksort(rest.filter((x) => x < pivot))
    .concat([pivot], quicksort(rest.filter((x) => x >= pivot)));
}
console.log(quicksort(NUMBERS));
