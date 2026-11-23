let s = "";
for (let i = 0; i < 5; i++) {
  s += i + ",";
}
console.log(s);
const parts = [];
for (let i = 0; i < 5; i++) parts.push("<" + i + ">");
console.log(parts.join(""), parts.join(), parts.join(" - "));
const name = "Roc";
console.log(`Hello, ${name}! ${1 + 1} ${[1, 2]} ${{}} ${null} ${undefined} ${true}`);
console.log("a" + 1 + 2, 1 + 2 + "a", "x" + [1, [2, 3]]);
