// A TypeError nothing catches ends the run, after what came before it is
// printed, as node ends it.
function lookup(table, key) {
  return table[key].value;
}
console.log(lookup({ a: { value: 1 } }, "a"));
console.log(lookup({}, "b"));
console.log("never printed");
