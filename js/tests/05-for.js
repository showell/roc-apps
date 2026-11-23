let total = 0;
for (let i = 1; i <= 100; i++) total += i;
console.log(total);
for (let i = 0, j = 10; i < j; i += 3) {
  console.log(i, j);
}
let k = 0;
for (; k < 3; ) k++;
console.log(k);
for (let i = 0; ; i++) {
  if (i === 4) { console.log("stopped at", i); break; }
}
