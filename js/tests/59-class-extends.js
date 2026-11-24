// Classes that extend classes: `super(...)`, `super.m()`, overriding,
// inherited static methods, and instanceof up the chain.
class Animal {
  constructor(name, legs) {
    this.name = name;
    this.legs = legs;
    this.sound = this.voice();
  }
  voice() {
    return "...";
  }
  speak() {
    return `${this.name} says ${this.voice()}`;
  }
  describe() {
    return `${this.name} has ${this.legs} legs`;
  }
  static kingdom() {
    return "animalia";
  }
  static make(name) {
    return new Animal(name, 4);
  }
}

class Dog extends Animal {
  constructor(name, tricks) {
    super(name, 4);
    this.tricks = tricks;
  }
  voice() {
    return "woof";
  }
  describe() {
    return `${super.describe()} and knows ${this.tricks.length} tricks`;
  }
  static make(name) {
    return new Dog(name, ["sit"]);
  }
}

class Puppy extends Dog {
  voice() {
    return `${super.voice()} (squeaky)`;
  }
  speak() {
    return super.speak().toUpperCase();
  }
}

class Bird extends Animal {
  constructor(name) {
    const wings = 2;
    super(name, wings);
    this.flies = true;
  }
}

const a = new Animal("generic", 6);
const d = new Dog("rex", ["sit", "roll"]);
const p = new Puppy("bit", ["beg"]);
const b = new Bird("tweety");

// The parent's constructor calls `voice`, and sees the subclass's.
console.log(a.sound, d.sound, p.sound, b.sound);
console.log(a.speak());
console.log(d.speak());
console.log(p.speak());
console.log(d.describe());
console.log(p.describe());
console.log(b.describe(), b.flies);

console.log(Animal.kingdom(), Dog.kingdom(), Puppy.kingdom());
console.log(Animal.make("cow").describe(), Dog.make("fido").describe(), Puppy.make("tiny").describe());

for (const [label, x] of [["a", a], ["d", d], ["p", p], ["b", b], ["o", {}]]) {
  console.log(label, x instanceof Animal, x instanceof Dog, x instanceof Puppy, x instanceof Bird);
}

// A subclass with no constructor passes every argument to its parent's.
class Named {
  constructor(first, last = "Smith", ...titles) {
    this.full = `${titles.join(" ")} ${first} ${last}`.trim();
  }
}
class Person extends Named {
  greet() {
    return `hello, ${this.full}`;
  }
}
console.log(new Person("Ada").greet(), new Person("Alan", "Turing", "Dr", "Prof").greet());

// A chain of three, each adding to an accumulator in its constructor.
class Base {
  constructor(log) {
    this.log = log;
    log.push("base");
  }
  total() {
    return this.log.length;
  }
}
class Middle extends Base {
  constructor(log) {
    log.push("before middle");
    super(log);
    log.push("middle");
  }
}
class Top extends Middle {
  constructor(log) {
    super(log);
    this.log.push("top");
  }
  total() {
    return super.total() * 100;
  }
}
const log = [];
const t = new Top(log);
console.log(log, t.total(), new Base([]).total());

// A super method called from a callback and a timer.
class Tally {
  constructor() {
    this.sum = 0;
  }
  add(n) {
    this.sum += n;
  }
}
class LoudTally extends Tally {
  add(n) {
    super.add(n * 2);
  }
}
const tally = new LoudTally();
[1, 2, 3].forEach((n) => tally.add(n));
setTimeout(() => console.log("tally", tally.sum), 5);
