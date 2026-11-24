// A tiny game: click the canvas, then steer with the arrow keys
const SPEED = 5; // pixels the square moves a frame while a key is down
const PLAYER_COLOR = "#7fdbca"; // the square you steer
const COIN_COLOR = "gold"; // the coin
const BACKGROUND = "#1d2433"; // the field
const SEED = 7; // a different number puts the coins in other places

let seed = SEED;
function random(n) {
  seed = (seed * 16807) % 2147483647;
  return seed % n;
}

let px = 200, py = 200;
let coinX = 40 + random(320), coinY = 40 + random(320);
let score = 0;

function frame(t) {
  if (keyIsDown("ArrowLeft")) px -= SPEED;
  if (keyIsDown("ArrowRight")) px += SPEED;
  if (keyIsDown("ArrowUp")) py -= SPEED;
  if (keyIsDown("ArrowDown")) py += SPEED;
  px = Math.max(10, Math.min(390, px));
  py = Math.max(10, Math.min(390, py));
  if (Math.abs(px - coinX) < 18 && Math.abs(py - coinY) < 18) {
    score++;
    console.log("coin", score, "at", coinX, coinY);
    coinX = 40 + random(320);
    coinY = 40 + random(320);
  }
  background(BACKGROUND);
  noStroke();
  fill(COIN_COLOR);
  circle(coinX, coinY, 9);
  fill(PLAYER_COLOR);
  rect(px - 10, py - 10, 20, 20);
  fill("white");
  text(`score ${score}`, 12, 28, 18);
}
