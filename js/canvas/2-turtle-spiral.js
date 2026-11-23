// A turtle spiral: try it in slow motion
background("white");
for (let i = 0; i < 90; i++) {
  stroke(`hsl(${i * 4}, 70%, 45%)`, 2);
  forward(i * 2);
  turn(89);
}
console.log("the turtle ends at heading", (90 * 89) % 360);
