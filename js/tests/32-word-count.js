const text = "the quick brown fox jumps over the lazy dog the fox";
const counts = {};
for (const w of text.split(" ")) counts[w] = (counts[w] ?? 0) + 1;
const entries = Object.entries(counts);
entries.sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1));
console.log(entries.slice(0, 3));
console.log(entries.map((e) => e[0] + "=" + e[1]).join(" "));
