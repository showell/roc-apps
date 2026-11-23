let a = 1;
const b = 2;
{
  let a = 10;
  const c = a + b;
  console.log(a, b, c);
}
console.log(a, b);
let x;
console.log(x);
x = 5;
x += 2;
x *= 3;
x -= 1;
x /= 4;
x %= 3;
console.log(x);
let n = 0;
n++;
++n;
console.log(n++, n, --n, n);
