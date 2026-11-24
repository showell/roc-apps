// Maps, patterns and errors
const scores = new Map([["ann", 3], ["bob", 5]]);
scores.set("cy", 4);
for (const [name, score] of scores) console.log(name, score);

const { ann = 0, dee = 0, ...others } = { ann: scores.get("ann"), bob: 5, cy: 4 };
console.log(ann, dee, others);

function best([first, ...rest], key = (x) => x) {
  return rest.reduce((top, x) => (key(x) > key(top) ? x : top), first);
}
console.log(best([...scores], ([, score]) => score));

try {
  const nobody = null;
  console.log(nobody.name);
} catch (e) {
  console.log(`caught ${e.name}: ${e.message}`);
}
console.log(new Set("mississippi"), scores.get("dee")?.length ?? "no dee");
