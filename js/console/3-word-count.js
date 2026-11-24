// Word count
const TEXT = "the quick brown fox jumps over the lazy dog the fox"; // the words counted
const TOP = 3; // how many of the most used words are printed

const counts = {};
for (const w of TEXT.split(" ")) counts[w] = (counts[w] ?? 0) + 1;
console.log(counts);
const top = Object.entries(counts).sort((a, b) => b[1] - a[1]);
console.log(top.slice(0, TOP));
