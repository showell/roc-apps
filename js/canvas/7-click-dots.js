// Click to place dots
// Each click on the canvas adds a dot, joined to the last.
let dots = [];
const colors = ["tomato", "gold", "#2a9d8f", "orchid", "#4a90d9"];

function draw() {
  background("#f4efe6");
  stroke("#8a8178", 2);
  for (let i = 1; i < dots.length; i++) {
    line(dots[i - 1][0], dots[i - 1][1], dots[i][0], dots[i][1]);
  }
  noStroke();
  for (let i = 0; i < dots.length; i++) {
    fill(colors[i % colors.length]);
    circle(dots[i][0], dots[i][1], 12);
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
