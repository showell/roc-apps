// switch: cases compared by ===, fall-through, default anywhere, break,
// and one scope for all the cases.
function describe(n) {
  switch (n) {
    case 0:
      return "zero";
    case 1:
    case 2:
      return "small";
    case "1":
      return "a string";
    default:
      return "other";
  }
}
console.log([0, 1, 2, "1", 3, null].map(describe));

function fallThrough(start) {
  const seen = [];
  switch (start) {
    case "a":
      seen.push("a");
    case "b":
      seen.push("b");
      break;
    case "c":
      seen.push("c");
    default:
      seen.push("default");
    case "d":
      seen.push("d");
  }
  return seen.join(",");
}
console.log(fallThrough("a"), fallThrough("b"), fallThrough("c"), fallThrough("d"), fallThrough("z"));

const tested = [];
function probe(v) {
  tested.push(v);
  return v;
}
switch (3) {
  case probe(1):
    console.log("one");
    break;
  case probe(3):
    console.log("three");
    break;
  case probe(5):
    console.log("five");
}
console.log(tested);

for (let i = 0; i < 5; i++) {
  switch (i % 3) {
    case 0:
      continue;
    case 1: {
      const word = "one";
      console.log(i, word);
      break;
    }
    default:
      console.log(i, "two");
  }
}

function scoped(kind) {
  switch (kind) {
    case "x":
      let label = "ex";
      return label;
    case "y":
      label = "why";
      return label;
  }
  return "neither";
}
console.log(scoped("x"), scoped("w"));
try {
  scoped("y");
} catch (e) {
  console.log(e.name, e.message);
}

switch (NaN) {
  case NaN:
    console.log("NaN matched");
    break;
  default:
    console.log("NaN never matches");
}

switch ("empty") {
}
console.log("done");
