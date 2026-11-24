// A starfield, flown through
const STAR_COUNT = 80; // how many stars there are at once
const SPEED = 0.01; // how fast the stars come closer, each frame
const STAR_SIZE = 3; // a star's radius, in pixels, as it passes
const BACKGROUND = "black"; // the sky
const SEED = 42; // a different number gives different stars

let seed = SEED;
function random() {
  seed = (seed * 16807) % 2147483647;
  return seed / 2147483647;
}

const stars = [];
for (let i = 0; i < STAR_COUNT; i++) {
  stars.push({ x: random() * 2 - 1, y: random() * 2 - 1, z: random() });
}

function frame(t) {
  background(BACKGROUND);
  noStroke();
  for (const s of stars) {
    s.z -= SPEED;
    if (s.z <= 0.02) {
      s.z = 1;
      s.x = random() * 2 - 1;
      s.y = random() * 2 - 1;
    }
    const sx = 200 + (s.x / s.z) * 100;
    const sy = 200 + (s.y / s.z) * 100;
    const shade = Math.round(255 * (1 - s.z));
    fill(`rgb(${shade}, ${shade}, ${shade})`);
    circle(sx, sy, (1 - s.z) * STAR_SIZE);
  }
}
