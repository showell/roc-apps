const a = 3;
const b = 4;
console.log(`${a} + ${b} = ${a + b}`);
console.log(`nested ${`inner ${a * b}`} done`);
console.log(`multi
line`);
console.log(`braces { } and ${ { x: 1 }.x } and \`ticks\``);
const items = ["x", "y"];
console.log(`${items.map((i) => `[${i}]`).join("")}`);
