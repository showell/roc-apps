// Closures
function counter() {
  let count = 0;
  return { up: () => ++count, get: () => count };
}
const c = counter();
c.up(); c.up(); c.up();
console.log("count:", c.get());

const fs = [];
for (let i = 0; i < 4; i++) fs.push(() => i * i);
console.log(fs.map((f) => f()));
