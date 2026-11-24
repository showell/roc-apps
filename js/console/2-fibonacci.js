// Fibonacci
const UP_TO = 15; // the last Fibonacci number printed

// Recursive: the definition itself, short and slow for a big n.
function fib(n) {
  return n < 2 ? n : fib(n - 1) + fib(n - 2);
}
const out = [];
for (let i = 0; i <= UP_TO; i++) out.push(fib(i));
console.log("recursive:", out);

// Iterative, two numbers a step: from a = F(n) and b = F(n + 1), the
// next pair is F(n + 2) = a + b and F(n + 3) = a + 2 * b.
const pairs = [];
let [a, b] = [0, 1];
while (pairs.length <= UP_TO) {
  pairs.push(a, b);
  [a, b] = [a + b, a + 2 * b];
}
console.log("iterative:", pairs.slice(0, UP_TO + 1));
