function makeAdder(n) {
  return (x) => x + n;
}
const add5 = makeAdder(5);
const add10 = makeAdder(10);
console.log(add5(1), add10(1), add5(add10(0)));
const fs = [];
for (let i = 0; i < 4; i++) {
  fs.push(() => i * i);
}
console.log(fs.map((f) => f()));
let shared = 0;
const inc = () => { shared++; return shared; };
inc(); inc();
console.log(shared, inc());
