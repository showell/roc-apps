// probe: growing
// A string built by N appends. Flat means an append costs the same at any
// length; linear means each append copies the string.
let s = "";
for (let i = 0; i < N; i++) s += "x";
console.log(s.length);
