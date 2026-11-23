// A value thrown that is no error, and caught by nothing: node shows it as
// console.log would.
function check(n) {
  if (n > 2) {
    throw { tooBig: n, limit: 2 };
  }
  return n;
}
for (const n of [1, 2, 3, 4]) {
  console.log(check(n));
}
