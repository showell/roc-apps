function sort(xs) {
  const a = xs.slice();
  for (let i = 1; i < a.length; i++) {
    const v = a[i];
    let j = i - 1;
    while (j >= 0 && a[j] > v) {
      a[j + 1] = a[j];
      j--;
    }
    a[j + 1] = v;
  }
  return a;
}
const data = [5, 3, 9, 1, 7, 2, 8, 6, 4, 0];
console.log(sort(data), data);
console.log(sort(["pear", "apple", "fig"]));
