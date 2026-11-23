// The array and string methods added beside the first set.
const a = [5, 1, 4, 1, 5, 9, 2, 6];
console.log(a.indexOf(1), a.indexOf(1, 2), a.indexOf(5, -3), a.indexOf(7));
console.log(a.includes(9), a.includes(9, 6), a.includes(NaN), [NaN].includes(NaN));
console.log(a.lastIndexOf(5), a.lastIndexOf(1), a.lastIndexOf(8));
console.log(a.at(0), a.at(-1), a.at(-20), a.at(100));

const q = [1, 2, 3];
console.log(q.shift(), q, q.unshift(-1, 0), q, [].shift());

const s = ["a", "b", "c", "d", "e"];
console.log(s.splice(1, 2), s);
console.log(s.splice(1, 0, "x", "y"), s);
console.log(s.splice(-2), s);
console.log(s.splice(), s.splice(0, 1, "z"), s);

console.log([0, 0, 0, 0].fill(7, 1, 3), [1, 2, 3].fill(0), [1, 2, 3].fill(9, -1));
console.log([1, [2, [3, [4]]]].flat(), [1, [2, [3, [4]]]].flat(2), [1, [2, [3, [4]]]].flat(Infinity), [[1], 2].flat(0));
console.log([1, 2, 3].flatMap((x) => [x, x * 10]), ["a b", "c"].flatMap((w) => w.split(" ")));
console.log(a.findLast((x) => x < 5), a.findLastIndex((x) => x < 5), a.findLast((x) => x > 100), a.findLastIndex((x) => x > 100));
console.log(["a", "b", "c"].reduceRight((acc, x) => acc + x), [1, 2, 3].reduceRight((acc, x) => acc - x, 0));
try {
  [].reduceRight((x) => x);
} catch (e) {
  console.log(e.message);
}

console.log(Array.from("abc"), Array.from([1, 2], (x, i) => x * 10 + i), Array.from({ length: 3 }, (_, i) => i * i));
console.log(Array.from(new Set([3, 3, 4])), Array.from(new Map([["k", 1]])), Array.from({ length: 2 }), Array.of(7, 8));
console.log(Array.from({ 0: "x", 1: "y", length: 2 }), Array.from(5));
const squares = Array.from({ length: 5 }, (_, i) => i ** 2).filter((n) => n % 2 === 0);
console.log(squares);

const t = "the quick brown fox jumps over the lazy dog";
console.log(t.indexOf("the"), t.indexOf("the", 1), t.lastIndexOf("the"), t.lastIndexOf("cat"));
console.log(t.includes("fox"), t.includes("fox", 20), t.at(0), t.at(-1), t.at(99));
console.log(t.replace("the", "a"), t.replaceAll("the", "a"), t.replace("cat", "dog"));
console.log("a-b-c".replaceAll("-", ""), "aaa".replace("a", "b"), "x".replaceAll("x", "xx"));
console.log(`[${"  pad  ".trimStart()}]`, `[${"  pad  ".trimEnd()}]`, `[${"\t pad \n".trim()}]`);
console.log("a,b,c,d".split(",", 2), "a,b,c".split(",", 0), "abc".split("", 2), "a,b".split(",", 10));
const words = "one two three".split(" ");
console.log(words.map((w) => w.at(0).toUpperCase() + w.slice(1)).join(" "));
