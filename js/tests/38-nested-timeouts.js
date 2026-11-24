// A timeout that sets the next from its own callback, a chain timed from
// each callback, and a timeout of the program's set between two links,
// 100 ms from either, so node's own timers keep the order on a busy machine.
const seen = [];
function link(depth) {
  seen.push(depth);
  console.log("link", depth);
  if (depth < 3) setTimeout(() => link(depth + 1), 200);
  else console.log("the chain:", seen);
}
setTimeout(() => link(1), 10);
setTimeout(() => console.log("at 310, between links 2 and 3"), 310);
