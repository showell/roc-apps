let s = "ab";
s += s;
s += 1;
s += [2, 3];
s += `-${s.length}-`;
console.log(s);
let calls = 0;
function bump() {
  calls++;
  s = "reset";
  return "!";
}
s += bump();
console.log(s, calls);
let n = 1;
n += 2;
n += "x";
console.log(n);
const parts = [];
let line = "";
for (let i = 0; i < 30; i++) {
  line += i % 10;
  if (line.length === 10) {
    parts.push(line);
    line = "";
  }
}
console.log(parts);
function keep() {
  let t = "";
  const add = (x) => { t += x; return t; };
  add("a"); add("b");
  return add("c");
}
console.log(keep(), keep());
