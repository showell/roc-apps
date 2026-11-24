// A countdown on timers
// setInterval ticks it down and a timeout rings after: no frame loop.
// A click once it has rung starts it again.
const COUNT_FROM = 3; // the first number shown
const TICK_MS = 600; // milliseconds between numbers
const GO_MS = 900; // milliseconds "go!" stays up
const COUNT_COLOR = "#3a6ea5"; // the background while it counts
const GO_COLOR = "#2e8b57"; // the background behind "go!"
const DONE_COLOR = "#555"; // the background once it's done

let left = 0;
let counting = false;

function show(words, color, size) {
  background(color);
  fill("white");
  text(words, 40, 220, size);
}

function countdown() {
  counting = true;
  left = COUNT_FROM;
  show(`${left}...`, COUNT_COLOR, 64);
  const tick = setInterval(() => {
    left--;
    console.log("left", left);
    if (left > 0) {
      show(`${left}...`, COUNT_COLOR, 64);
    } else {
      clearInterval(tick);
      show("go!", GO_COLOR, 64);
      setTimeout(() => {
        show("click to go again", DONE_COLOR, 32);
        counting = false;
      }, GO_MS);
    }
  }, TICK_MS);
}

// A click while it counts is ignored, so two intervals never run at once.
onClick(() => {
  if (!counting) countdown();
});
countdown();
