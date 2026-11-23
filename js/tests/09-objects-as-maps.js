const counts = {};
const words = ["apple", "pear", "apple", "fig", "pear", "apple"];
for (const w of words) {
  if (counts[w] === undefined) counts[w] = 0;
  counts[w] += 1;
}
console.log(counts);
console.log(Object.keys(counts), Object.values(counts));
console.log(Object.entries(counts));
const byNumber = {};
byNumber[10] = "ten";
byNumber[2] = "two";
byNumber.name = "numbers";
byNumber["1"] = "one";
console.log(byNumber, Object.keys(byNumber));
console.log(counts.missing, counts["fig"]);
