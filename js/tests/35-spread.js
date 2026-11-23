// Spread in array literals and in calls: an array's items, a string's
// characters, arrays built from others, and arguments spread into a
// function's parameters and into builtins.
const a = [1, 2, 3];
const b = [0, ...a, 4];
console.log(b, b.length);
console.log(Math.max(...a), Math.min(...b, -1));
console.log([...a, ...b]);
console.log([..."hey"], [..."héllo"].length);
function sum(x, y, z) {
  return x + y + z;
}
console.log(sum(...a), sum(1, ...[2, 3]));
const copy = [...a];
copy.push(9);
console.log(a, copy);
const nested = [[1, 2], [3]];
console.log([...nested[0], ...nested[1]], [...[]].length);
const more = [];
more.push(...a, ...a);
console.log(more);
