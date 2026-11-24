// A turtle spiral: try it in slow motion
// To watch the turtle walk, change the speed menu beside Pause from
// "Full speed" to "Slow: a mark at a time", then press Run.
const STEPS = 90; // how many lines the turtle draws
const GROWTH = 2; // how much longer each line is than the one before
const TURN = 89; // degrees the turtle turns after each line
const HUE_STEP = 4; // how far round the color wheel each line moves
const LINE_WIDTH = 2; // the lines' width, in pixels

background("white");
for (let i = 0; i < STEPS; i++) {
  stroke(`hsl(${i * HUE_STEP}, 70%, 45%)`, LINE_WIDTH);
  forward(i * GROWTH);
  turn(TURN);
}
console.log("the turtle ends at heading", (STEPS * TURN) % 360);
