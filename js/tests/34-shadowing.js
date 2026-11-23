// Names placed before the run: a block's, a loop's and a call's own
// variables shadowing outer ones, a function declared after its first
// use, and closures that reach several scopes out.
const x = "outer";
function show() {
  return x;
}
{
  const x = "block";
  console.log(x, show());
  {
    let y = x + "!";
    console.log(y);
  }
}
for (let x = 0; x < 2; x++) {
  const shown = () => `${x} ${typeof show}`;
  console.log(shown());
}
console.log(later(4));
function later(n) {
  const add = (k) => {
    const inner = (j) => n + k + j;
    return inner(1);
  };
  return add(10);
}
function f(g) {
  function g() {
    return "the function";
  }
  return g();
}
console.log(f(1));
let total = 0;
for (const v of [1, 2, 3]) {
  let total2 = total + v;
  total = total2;
}
console.log(total, x);
const Math2 = Math.max(1, 2);
{
  const Math = { max: () => "mine" };
  console.log(Math.max(), Math2);
}
