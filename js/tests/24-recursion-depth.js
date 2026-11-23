function sumTo(n) {
  return n === 0 ? 0 : n + sumTo(n - 1);
}
console.log(sumTo(300));
function ackermann(m, n) {
  if (m === 0) return n + 1;
  if (n === 0) return ackermann(m - 1, 1);
  return ackermann(m - 1, ackermann(m, n - 1));
}
console.log(ackermann(2, 3));
function hanoi(n, from, to, via, moves) {
  if (n === 0) return moves;
  hanoi(n - 1, from, via, to, moves);
  moves.push(from + to);
  hanoi(n - 1, via, to, from, moves);
  return moves;
}
console.log(hanoi(4, "A", "C", "B", []).join(" "));
