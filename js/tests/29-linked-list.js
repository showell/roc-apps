function cons(head, tail) {
  return { head, tail };
}
let list = null;
for (let i = 5; i > 0; i--) list = cons(i, list);
function toArray(l) {
  const out = [];
  while (l !== null) {
    out.push(l.head);
    l = l.tail;
  }
  return out;
}
console.log(toArray(list));
console.log(list);
function reverse(l) {
  let acc = null;
  while (l !== null) {
    acc = cons(l.head, acc);
    l = l.tail;
  }
  return acc;
}
console.log(toArray(reverse(list)));
