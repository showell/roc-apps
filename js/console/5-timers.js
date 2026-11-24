// Timers
// Each callback runs when its time comes, on the page's frames.
const TICKS = 3; // how many times the interval ticks before it's cleared
const TICK_MS = 300; // milliseconds between ticks

setTimeout(() => console.log("half a second"), 500);
setTimeout(() => console.log("a tenth of a second"), 100);
let n = 0;
const every = setInterval(() => {
  n++;
  console.log("tick", n);
  if (n === TICKS) clearInterval(every);
}, TICK_MS);
console.log("the program's end comes first");
