// refused: RangeError: Maximum call stack size exceeded
function f(n) { return f(n + 1); }
f(0);
