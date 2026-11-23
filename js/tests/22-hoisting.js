console.log(double(21));
function double(x) {
  return twice(x);
}
function twice(x) {
  return x * 2;
}
function isEven(n) {
  return n === 0 ? true : isOdd(n - 1);
}
function isOdd(n) {
  return n === 0 ? false : isEven(n - 1);
}
console.log(isEven(10), isOdd(7), isEven(7));
