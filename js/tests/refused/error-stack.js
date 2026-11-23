// refused: unsupported: an error's `stack`
const e = new Error("x");
console.log(e.stack);
