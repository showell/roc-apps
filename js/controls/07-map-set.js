// A Map's entry written, in a loop, over a hundred keys.
const m = new Map();
for (let i = 0; i < N; i++) m.set(i % 100, i);
console.log(m.size);
