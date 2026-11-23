const square = (x) => x * x;
const add = (a, b) => a + b;
const answer = () => 42;
const block = (x) => {
  const y = x * 2;
  return y + 1;
};
const one = x => x;
console.log(square(7), add(2, 3), answer(), block(5), one("one"));
console.log(square, add, (() => 1), function named() {}, function () {});
const obj = { f: () => 1, g() { return 2; }, h: function () { return 3; } };
console.log(obj.f() + obj.g() + obj.h(), obj);
