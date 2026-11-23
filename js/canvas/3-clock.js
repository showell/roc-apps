// A clock whose second hand goes round once a minute
function hand(angle, length, color, width) {
  stroke(color, width);
  line(200, 200, 200 + length * Math.sin(angle), 200 - length * Math.cos(angle));
}

function frame(t) {
  background("#20242c");
  stroke("#d8d4cc", 3);
  fill("#2c323d");
  circle(200, 200, 170);
  for (let i = 0; i < 60; i++) {
    const a = (i / 60) * 2 * Math.PI;
    const inner = i % 5 === 0 ? 148 : 158;
    stroke("#d8d4cc", i % 5 === 0 ? 3 : 1);
    line(200 + inner * Math.sin(a), 200 - inner * Math.cos(a), 200 + 165 * Math.sin(a), 200 - 165 * Math.cos(a));
  }
  const seconds = t % 60;
  hand((seconds / 3600) * 2 * Math.PI, 90, "#d8d4cc", 6);
  hand((seconds / 60) * 2 * Math.PI, 150, "tomato", 2);
  noStroke();
  fill("tomato");
  circle(200, 200, 6);
  fill("#d8d4cc");
  text(`${Math.floor(seconds)} s`, 180, 270, 20);
}
