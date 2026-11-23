// probe: growing
// N pushes onto one array. Flat means a push costs the same at any length;
// linear means each push copies the array.
const a = [];
for (let i = 0; i < N; i++) a.push(i);
console.log(a.length);
