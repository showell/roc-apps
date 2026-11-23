// A push and a pop, the array's length the same after each pass.
const a = [1, 2, 3];
for (let i = 0; i < N; i++) {
  a.push(i);
  a.pop();
}
console.log(a.length);
