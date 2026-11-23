// A call of a closure that writes the variable it holds.
let c = 0;
const f = () => ++c;
for (let i = 0; i < N; i++) f();
console.log(c);
