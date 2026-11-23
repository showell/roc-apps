// probe: fixed
// A property write in a loop, beside a heap of N objects: the writes are
// fixed (W), the heap grows. Flat means a write leaves the heap where it
// is; linear means each write copies it.
const keep = [];
for (let i = 0; i < N; i++) keep.push({ i: i });
const o = { x: 0 };
for (let i = 0; i < W; i++) o.x = i;
console.log(o.x, keep.length);
