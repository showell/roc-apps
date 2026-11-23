function fib(n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}
const out = [];
for (let i = 0; i <= 20; i++) out.push(fib(i));
console.log(out);
console.log(fib(22));
