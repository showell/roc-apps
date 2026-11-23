// A property written, in a loop.
const o = { x: 0 };
for (let i = 0; i < N; i++) o.x = i;
console.log(o.x);
