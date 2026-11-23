// A store into an array, in a loop.
const a = [0, 0, 0, 0, 0, 0, 0, 0];
for (let i = 0; i < N; i++) a[i % 8] = i;
console.log(a[0]);
