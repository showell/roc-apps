// Click to place dots
// Each click on the canvas adds a dot, joined to the last.
const DOT_COLORS = ["tomato", "gold", "#2a9d8f", "orchid", "#4a90d9"]; // the dots take these in turn
const DOT_RADIUS = 12; // in pixels
const LINE_COLOR = "#8a8178"; // the lines joining the dots
const BACKGROUND = "#f4efe6"; // the paper

let dots = [];

function draw() {
  background(BACKGROUND);
  stroke(LINE_COLOR, 2);
  for (let i = 1; i < dots.length; i++) {
    line(dots[i - 1][0], dots[i - 1][1], dots[i][0], dots[i][1]);
  }
  noStroke();
  for (let i = 0; i < dots.length; i++) {
    fill(DOT_COLORS[i % DOT_COLORS.length]);
    circle(dots[i][0], dots[i][1], DOT_RADIUS);
  }
  fill("#333");
  text(dots.length === 0 ? "click the canvas" : `${dots.length} dot${dots.length === 1 ? "" : "s"}`, 12, 28, 16);
}

onClick((x, y) => {
  dots.push([Math.round(x), Math.round(y)]);
  console.log("dot", dots.length, "at", Math.round(x), Math.round(y));
  draw();
});
draw();
