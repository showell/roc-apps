// refused: unsupported: printing a circular structure
const a = [];
a.push(a);
console.log(a);
