function gcd(a, b) {
  while (b !== 0) {
    const t = b;
    b = a % b;
    a = t;
  }
  return a;
}
console.log(gcd(1071, 462), gcd(17, 5));
const primes = [];
for (let n = 2; primes.length < 25; n++) {
  let isPrime = true;
  for (const p of primes) {
    if (p * p > n) break;
    if (n % p === 0) { isPrime = false; break; }
  }
  if (isPrime) primes.push(n);
}
console.log(primes);
