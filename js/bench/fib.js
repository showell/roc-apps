// The call path: fib(22), 28,657 calls, each reading its parameter and the
// name `fib` from the scope it was made in.
function fib(n) {
  return n < 2 ? n : fib(n - 1) + fib(n - 2);
}
console.log(fib(22));
