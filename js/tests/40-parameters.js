// Default and rest parameters, and parameters that are patterns.
function greet(name, greeting = "hello", punctuation = greeting === "hello" ? "!" : ".") {
  return `${greeting}, ${name}${punctuation}`;
}
console.log(greet("ann"));
console.log(greet("bob", "bye"));
console.log(greet("cy", undefined, "?"));

function sum(first, ...rest) {
  let total = first;
  for (const n of rest) total += n;
  return total;
}
console.log(sum(1), sum(1, 2, 3, 4));

const tail = (...items) => items.slice(1);
console.log(tail(), tail(1), tail(1, 2, 3));

function area({ width, height = width }) {
  return width * height;
}
console.log(area({ width: 3 }), area({ width: 3, height: 4 }));

function point([x, y] = [0, 0], { scale = 1 } = {}) {
  return [x * scale, y * scale];
}
console.log(point(), point([1, 2]), point([1, 2], { scale: 3 }));

function later(a, b = () => a * 2) {
  a = 5;
  return b();
}
console.log(later(1), later(1, () => 0));

function counter(start = 0, step = 1) {
  let n = start;
  return () => {
    n += step;
    return n;
  };
}
const c = counter(10, 5);
c();
console.log(c());

const spread = [1, 2, 3];
console.log(sum(...spread), Math.max(...spread));

function chosen(a, b = a + 1, c = b + 1) {
  return [a, b, c];
}
console.log(chosen(1), chosen(1, 5), chosen(1, undefined, 0));
