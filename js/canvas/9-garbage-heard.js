// garbage, heard by onCollect
// The garbage collection sample again, listening: onCollect(fn) is this
// page's own, like onClick, not JavaScript's. After each collection, between
// two instructions as a timer runs, fn is called with what the collection
// saw: the heap's cells, those it found live, and those in use just before.
// Each collection prints a line and draws a bar, its height the share of the
// heap found live.
const ROUNDS = 8; // how many rounds of garbage
const GARBAGE = 150; // the pieces each round makes and drops
const MOST_KEPT = 80; // how many pieces stay alive by the last round, the newest

background("#faf8f4");
noStroke();
let heard = 0;
onCollect(({ cells, live }) => {
  heard++;
  console.log(`collected: ${cells} cells, ${live} live`);
  const height = (live / cells) * 360;
  fill("seagreen");
  rect(12 + (heard - 1) * 22, 380 - height, 16, height);
});

// One piece of garbage: an array, an object holding it, and a closure over it.
function piece(round, i) {
  const point = { x: i % 17, y: round, xs: [round, i] };
  return () => point.x * point.y + point.xs.length;
}

const kept = [];
let sum = 0;
for (let round = 1; round <= ROUNDS; round++) {
  for (let i = 0; i < GARBAGE; i++) {
    const weight = piece(round, i);
    sum = (sum + weight()) % 1000003;
    kept.push(weight);
    // The live set grows round by round, so each bar stands taller.
    if (kept.length > (MOST_KEPT * round) / ROUNDS) kept.shift();
  }
}
console.log(`checksum ${sum}; the collections are heard once the program ends`);
