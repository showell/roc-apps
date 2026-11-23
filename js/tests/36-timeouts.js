// Timeouts run after the program, in the order of their times, and two at
// one time in the order they were set. A delay left out, or 0, is 1 ms.
setTimeout(() => console.log("at 300"), 300);
setTimeout(() => console.log("at 100"), 100);
setTimeout(() => console.log("at 200, set first"), 200);
setTimeout(() => console.log("at 200, set second"), 200);
setTimeout(() => console.log("at 1, its delay 0"), 0);
setTimeout(() => console.log("at 1, its delay left out"));
const never = setTimeout(() => console.log("never: cleared"), 150);
clearTimeout(never);
clearTimeout(undefined);
console.log("the program's end comes first;", typeof never);
