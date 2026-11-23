// An interval, cleared from its own callback after four ticks, with
// timeouts set between its ticks.
let ticks = 0;
const id = setInterval(() => {
  ticks++;
  console.log("tick", ticks);
  if (ticks === 4) {
    clearInterval(id);
    console.log("cleared after", ticks, "ticks");
  }
}, 100);
setTimeout(() => console.log("between ticks 2 and 3"), 250);
setTimeout(() => console.log("long after the last tick:", ticks), 700);
