// A countdown on timers
// setInterval ticks it down and a timeout rings after: no frame loop.
let left = 3;

function show(words, color) {
  background(color);
  fill("white");
  text(words, 40, 220, 64);
}

show(`${left}...`, "#3a6ea5");
const tick = setInterval(() => {
  left--;
  console.log("left", left);
  if (left > 0) {
    show(`${left}...`, "#3a6ea5");
  } else {
    clearInterval(tick);
    show("go!", "#2e8b57");
    setTimeout(() => show("once more? Run", "#555"), 900);
  }
}, 600);
