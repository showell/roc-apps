// A starfield, flown through
let seed = 42;
function random() {
  seed = (seed * 16807) % 2147483647;
  return seed / 2147483647;
}

const stars = [];
for (let i = 0; i < 80; i++) {
  stars.push({ x: random() * 2 - 1, y: random() * 2 - 1, z: random() });
}

function frame(t) {
  background("black");
  noStroke();
  for (const s of stars) {
    s.z -= 0.01;
    if (s.z <= 0.02) {
      s.z = 1;
      s.x = random() * 2 - 1;
      s.y = random() * 2 - 1;
    }
    const sx = 200 + (s.x / s.z) * 100;
    const sy = 200 + (s.y / s.z) * 100;
    const shade = Math.round(255 * (1 - s.z));
    fill(`rgb(${shade}, ${shade}, ${shade})`);
    circle(sx, sy, (1 - s.z) * 3);
  }
}
