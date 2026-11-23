// A countdown on timers
// setInterval ticks it down and a timeout rings after: no frame loop.
// A click once it has rung starts it again.
let left = 0;
let counting = false;

function show(words, color, size) {
  background(color);
  fill("white");
  text(words, 40, 220, size);
}

function countdown() {
  counting = true;
  left = 3;
  show(`${left}...`, "#3a6ea5", 64);
  const tick = setInterval(() => {
    left--;
    console.log("left", left);
    if (left > 0) {
      show(`${left}...`, "#3a6ea5", 64);
    } else {
      clearInterval(tick);
      show("go!", "#2e8b57", 64);
      setTimeout(() => {
        show("click to go again", "#555", 32);
        counting = false;
      }, 900);
    }
  }, 600);
}

// A click while it counts is ignored, so two intervals never run at once.
onClick(() => {
  if (!counting) countdown();
});
countdown();
