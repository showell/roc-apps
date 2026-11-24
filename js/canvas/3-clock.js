// A clock whose second hand goes round once a minute
const BACKGROUND = "#20242c"; // the color around the clock
const FACE_COLOR = "#2c323d"; // the clock's face
const INK_COLOR = "#d8d4cc"; // the rim, the ticks, the minute hand and the seconds
const SECOND_HAND_COLOR = "tomato"; // the second hand and the dot at the middle
const MINUTE_HAND_LENGTH = 90; // in pixels
const SECOND_HAND_LENGTH = 150; // in pixels

function hand(angle, length, color, width) {
  stroke(color, width);
  line(200, 200, 200 + length * Math.sin(angle), 200 - length * Math.cos(angle));
}

function frame(t) {
  background(BACKGROUND);
  stroke(INK_COLOR, 3);
  fill(FACE_COLOR);
  circle(200, 200, 170);
  for (let i = 0; i < 60; i++) {
    const a = (i / 60) * 2 * Math.PI;
    const inner = i % 5 === 0 ? 148 : 158;
    stroke(INK_COLOR, i % 5 === 0 ? 3 : 1);
    line(200 + inner * Math.sin(a), 200 - inner * Math.cos(a), 200 + 165 * Math.sin(a), 200 - 165 * Math.cos(a));
  }
  const seconds = t % 60;
  hand((seconds / 3600) * 2 * Math.PI, MINUTE_HAND_LENGTH, INK_COLOR, 6);
  hand((seconds / 60) * 2 * Math.PI, SECOND_HAND_LENGTH, SECOND_HAND_COLOR, 2);
  noStroke();
  fill(SECOND_HAND_COLOR);
  circle(200, 200, 6);
  fill(INK_COLOR);
  text(`${Math.floor(seconds)} s`, 180, 270, 20);
}
