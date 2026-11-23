const xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
console.log(xs.map((x) => x * 2));
console.log(xs.filter((x) => x % 3 === 0));
console.log(xs.reduce((a, b) => a + b, 0), xs.reduce((a, b) => a * b));
console.log(xs.some((x) => x > 9), xs.every((x) => x > 0), xs.find((x) => x > 4), xs.findIndex((x) => x > 4));
xs.forEach((x, i) => { if (i < 2) console.log("item", i, x); });
console.log(xs.indexOf(4), xs.indexOf(42), xs.includes(10), [NaN].includes(NaN), [NaN].indexOf(NaN));
const compose = (f, g) => (x) => f(g(x));
console.log(compose((x) => x + 1, (x) => x * 10)(5));
