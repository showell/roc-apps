// A closure only a timer holds, and an interval's, while the program and
// the callbacks make garbage: the queue is a root of the VM's collector.
function churn() {
  let n = 0;
  for (let i = 0; i < 3000; i++) {
    const g = { i };
    n = n + g.i;
  }
  return n;
}

function later(name) {
  const held = { name };
  return () => console.log("timer", held.name, churn() > 0);
}
setTimeout(later("first"), 1000);

let runs = 0;
const state = { count: 0 };
const interval = setInterval(() => {
  churn();
  state.count = state.count + 1;
  runs++;
  console.log("interval", state.count);
  if (runs === 3) clearInterval(interval);
}, 2);

churn();
console.log("main done");
