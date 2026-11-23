// A bouncing ball
let x = 60, y = 80;
let dx = 4, dy = 3;
const r = 20;

function frame(t) {
  background("#f4efe6");
  noStroke();
  fill("tomato");
  circle(x, y, r);
  x += dx;
  y += dy;
  if (x < r || x > 400 - r) dx = -dx;
  if (y < r || y > 400 - r) dy = -dy;
}
