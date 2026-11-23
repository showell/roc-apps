// probe: fixed
// Stores into an array of N items: the stores are fixed (W), the array
// grows. Flat means a store writes one item; linear means it copies them all.
const a = [];
for (let i = 0; i < N; i++) a.push(0);
for (let i = 0; i < W; i++) a[i % N] = i;
console.log(a[0]);
