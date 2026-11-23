// A throw nothing catches inside a timer's callback ends the program, the
// timers still waiting never run, as node ends it.
setTimeout(() => console.log("first"), 10);
setTimeout(() => {
  try {
    throw new Error("caught in the callback");
  } catch (e) {
    console.log(e.message);
  }
}, 20);
setTimeout(() => {
  console.log("about to throw");
  throw new RangeError("not caught");
}, 30);
setTimeout(() => console.log("never"), 40);
console.log("scheduled");
