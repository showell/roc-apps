// probe: fixed
// A closure's variable written W times, with N closures, and their N
// scopes, alive beside it. Flat means a write leaves the other scopes where
// they are; linear means each write copies the scope list.
const counters = [];
for (let i = 0; i < N; i++) {
  let c = 0;
  counters.push(() => ++c);
}
const f = counters[0];
for (let i = 0; i < W; i++) f();
console.log(f());
