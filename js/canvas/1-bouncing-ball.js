// A bouncing ball
// Try changing these, then press Run:
const BALL_RADIUS = 20; // the ball's size, in pixels: try 8, or 50
const BALL_COLOR = "tomato"; // any CSS color, like "gold" or "#3a7"
const SPEED_X = 4; // pixels a frame across: try 10, or 0 to bounce straight up and down
const SPEED_Y = 3; // pixels a frame down: try 1, or 0 to roll from side to side
const BACKGROUND = "#f4efe6"; // the color behind the ball: try "black"

let x = 60, y = 80;
let dx = SPEED_X, dy = SPEED_Y;

function frame(t) {
  background(BACKGROUND);
  noStroke();
  fill(BALL_COLOR);
  circle(x, y, BALL_RADIUS);
  x += dx;
  y += dy;
  if (x < BALL_RADIUS || x > 400 - BALL_RADIUS) dx = -dx;
  if (y < BALL_RADIUS || y > 400 - BALL_RADIUS) dy = -dy;
}
