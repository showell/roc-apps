function counter() {
  let count = 0;
  return {
    up: () => ++count,
    down: () => --count,
    get: () => count,
  };
}
const c1 = counter();
const c2 = counter();
c1.up(); c1.up(); c1.up();
c2.down();
console.log(c1.get(), c2.get());
console.log(c1);
