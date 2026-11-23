const xs = [10, 9, 1, 100, 25, 3];
console.log(xs.slice().sort(), xs.slice().sort((a, b) => a - b), xs.slice().sort((a, b) => b - a));
const people = [
  { name: "Ann", age: 30 },
  { name: "Bob", age: 25 },
  { name: "Cy", age: 30 },
  { name: "Di", age: 25 },
];
people.sort((p, q) => p.age - q.age);
console.log(people.map((p) => p.name).join(","));
console.log(["b", "a", "c"].sort(), [3, 1, 2].reverse());
