function memoize(f) {
  const cache = {};
  return (n) => {
    if (cache[n] !== undefined) return cache[n];
    const v = f(n);
    cache[n] = v;
    return v;
  };
}
const slowSquare = (n) => n * n;
const fast = memoize(slowSquare);
console.log(fast(9), fast(9), fast(12));
const memo = {};
function fib(n) {
  if (n < 2) return n;
  if (memo[n] !== undefined) return memo[n];
  const v = fib(n - 1) + fib(n - 2);
  memo[n] = v;
  return v;
}
console.log(fib(90), Object.keys(memo).length);
