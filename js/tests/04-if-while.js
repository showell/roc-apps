let i = 0;
let evens = 0;
while (i < 20) {
  i++;
  if (i % 2 === 0) {
    evens++;
  } else if (i % 5 === 0) {
    console.log("five-ish", i);
  } else {
    continue;
  }
  if (i > 15) break;
}
console.log(i, evens);
