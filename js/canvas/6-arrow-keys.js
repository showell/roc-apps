// A tiny game: click the canvas, then steer with the arrow keys
let seed = 7;
function random(n) {
  seed = (seed * 16807) % 2147483647;
  return seed % n;
}

let px = 200, py = 200;
let coinX = 40 + random(320), coinY = 40 + random(320);
let score = 0;

function frame(t) {
  if (keyIsDown("ArrowLeft")) px -= 5;
  if (keyIsDown("ArrowRight")) px += 5;
  if (keyIsDown("ArrowUp")) py -= 5;
  if (keyIsDown("ArrowDown")) py += 5;
  px = Math.max(10, Math.min(390, px));
  py = Math.max(10, Math.min(390, py));
  if (Math.abs(px - coinX) < 18 && Math.abs(py - coinY) < 18) {
    score++;
    console.log("coin", score, "at", coinX, coinY);
    coinX = 40 + random(320);
    coinY = 40 + random(320);
  }
  background("#1d2433");
  noStroke();
  fill("gold");
  circle(coinX, coinY, 9);
  fill("#7fdbca");
  rect(px - 10, py - 10, 20, 20);
  fill("white");
  text(`score ${score}`, 12, 28, 18);
}
