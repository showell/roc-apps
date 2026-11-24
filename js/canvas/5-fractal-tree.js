// A fractal tree, each branch two smaller ones
const DEPTH = 9; // how many times the branches split
const TRUNK_LENGTH = 95; // in pixels
const SPREAD = 0.42; // how far each branch turns from its parent, in radians
const SHRINK = 0.72; // each branch's length over its parent's
const BARK_COLOR = "#6b4226"; // the trunk and the thick branches
const LEAF_COLOR = "#3a7d44"; // the thin branches at the tips
const BACKGROUND = "#eef4f8"; // the sky

function branch(x, y, angle, length, depth) {
  if (depth === 0) return;
  const x2 = x + length * Math.sin(angle);
  const y2 = y - length * Math.cos(angle);
  stroke(depth > 3 ? BARK_COLOR : LEAF_COLOR, depth);
  line(x, y, x2, y2);
  branch(x2, y2, angle - SPREAD, length * SHRINK, depth - 1);
  branch(x2, y2, angle + SPREAD, length * SHRINK, depth - 1);
}

background(BACKGROUND);
branch(200, 390, 0, TRUNK_LENGTH, DEPTH);
