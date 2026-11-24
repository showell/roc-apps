// garbage: makes plenty of short-lived garbage, so the VM's collector runs
// again and again, then points at the page's memory view. Each round builds
// and drops many small pieces (an object, an array and a closure each), and
// keeps a few of them alive; how many it keeps rises and then falls over the
// rounds, so each collection finds a different number of cells live. On the
// page, the memory link draws the heap: cells in use climb as a round makes
// garbage and drop at each collection. Each `SUPPORTS` comment marks the
// first use of a feature of the subset (js/README.md, "The subset").
// SUPPORTS let and const
const ROUNDS = 12; // how many rounds of garbage
const GARBAGE = 150; // the pieces each round makes and drops
const MOST_KEPT = 60; // about the most pieces kept alive at once, in the middle rounds

// One piece of garbage: an array, an object holding it, and a closure over
// the object.
// SUPPORTS function declarations
function piece(round, i) {
  // SUPPORTS array literals
  const xs = [round, i, round * i];
  // SUPPORTS object literals, with shorthand properties
  const point = { x: i % 17, y: round, xs };
  // SUPPORTS arrow functions and closures: the arrow keeps `point`
  const weight = () => point.x * point.y + point.xs.length;
  return { point, weight };
}

// How many pieces stay alive after `round`: up to MOST_KEPT at the middle
// of the rounds, then back down.
function keptAfter(round) {
  const middle = (ROUNDS + 1) / 2;
  // SUPPORTS Math, and ?:
  const distance = Math.abs(round - middle);
  return distance >= middle ? 0 : Math.round((MOST_KEPT * (middle - distance)) / middle);
}

const kept = [];
let made = 0;
let sum = 0;
let mostKept = 0;
// SUPPORTS the C-form for, and ++
for (let round = 1; round <= ROUNDS; round++) {
  for (let i = 0; i < GARBAGE; i++) {
    const p = piece(round, i);
    made++;
    // SUPPORTS compound assignment, and calling a closure
    sum = (sum + p.weight()) % 1000003;
    // Every fifth piece joins the live set; the rest are garbage at once.
    // SUPPORTS if, and ===
    if (i % 5 === 0) kept.push(p);
  }
  // The live set trimmed from its oldest end to this round's size.
  // SUPPORTS splice
  const target = keptAfter(round);
  if (kept.length > target) kept.splice(0, kept.length - target);
  mostKept = Math.max(mostKept, kept.length);
}

// SUPPORTS reduce, over what is still alive
const stillAlive = kept.reduce((total, p) => total + p.weight(), 0);
// SUPPORTS template strings
console.log(`${made} pieces made in ${ROUNDS} rounds, ${mostKept} kept alive at most`);
console.log(`${kept.length} alive at the end, weighing ${stillAlive}; checksum ${sum}`);
console.log("Now look at the memory link above.");
