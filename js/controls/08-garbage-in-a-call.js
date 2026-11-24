// An object made inside a call and dropped, each pass: garbage the VM's
// collector frees, so its heap stays one size and no pass copies it. The
// walker keeps every one.
function made(i) {
  const o = { x: i };
  return o.x;
}
let t = 0;
for (let i = 0; i < N; i++) t = t + made(i);
console.log(t);
