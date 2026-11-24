// 50,000 keys pass through a Map and a Set that never hold more than ten:
// each delete leaves a gone entry, and the table drops them once they
// outnumber the standing ones, so its memory stays that of ten entries.
const m = new Map();
const s = new Set();
let t = 0;
for (let i = 0; i < 50000; i++) {
  m.set(i, i);
  s.add(`k${i}`);
  if (i >= 10) {
    t = t + m.get(i - 10);
    m.delete(i - 10);
    s.delete(`k${i - 10}`);
  }
}
console.log(t, m.size, s.size);
