// A fractal tree, each branch two smaller ones
function branch(x, y, angle, length, depth) {
  if (depth === 0) return;
  const x2 = x + length * Math.sin(angle);
  const y2 = y - length * Math.cos(angle);
  stroke(depth > 3 ? "#6b4226" : "#3a7d44", depth);
  line(x, y, x2, y2);
  branch(x2, y2, angle - 0.42, length * 0.72, depth - 1);
  branch(x2, y2, angle + 0.42, length * 0.72, depth - 1);
}

background("#eef4f8");
branch(200, 390, 0, 95, 9);
