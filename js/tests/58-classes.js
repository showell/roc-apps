// Classes: a constructor, methods, static methods, `this` in arrows, and
// instanceof. No instance is printed whole: node prints `Point { x: 1 }`.
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
  plus(other) {
    return new Point(this.x + other.x, this.y + other.y);
  }
  scaled(k) {
    return new Point(this.x * k, this.y * k);
  }
  length() {
    return Math.sqrt(this.x * this.x + this.y * this.y);
  }
  toText() {
    return `(${this.x}, ${this.y})`;
  }
  static origin() {
    return new Point(0, 0);
  }
  static between(a, b) {
    return a.plus(b).scaled(0.5);
  }
}

const p = new Point(3, 4);
console.log(p.x, p.y, p.length());
console.log(p.plus(new Point(1, 1)).toText());
console.log(Point.origin().toText(), Point.between(p, Point.origin()).toText());
console.log(typeof Point, typeof p, p instanceof Point, {} instanceof Point, 3 instanceof Point);

// A method calls another through `this`, and an arrow inside a method sees
// the same `this`.
class Counter {
  constructor(name, start = 0) {
    this.name = name;
    this.count = start;
    this.log = [];
  }
  bump(by) {
    this.count += by;
    this.log.push(by);
    return this;
  }
  bumpAll(list) {
    list.forEach((n) => this.bump(n));
    return this.count;
  }
  report() {
    const parts = this.log.map((n) => `${this.name}+${n}`);
    return parts.join(" ");
  }
  later() {
    return () => this.count * 10;
  }
}

const c = new Counter("c");
console.log(c.bump(1).bump(2).count, c.bumpAll([3, 4]), c.report());
const later = c.later();
c.bump(5);
console.log(later());
const d = new Counter("d", 100);
console.log(d.count, c.count, d.bump(1).count, c.count);

// A constructor's defaults, destructuring and rest parameters.
class Shape {
  constructor({ kind, sides = 0 }, ...tags) {
    this.kind = kind;
    this.sides = sides;
    this.tags = tags;
  }
  describe() {
    return `${this.kind} with ${this.sides} sides [${this.tags.join(",")}]`;
  }
}
console.log(new Shape({ kind: "square", sides: 4 }, "flat", "even").describe());
console.log(new Shape({ kind: "blob" }).describe());

// No constructor at all, and `new` without parentheses.
class Empty {
  hello() {
    return "hello from an empty class";
  }
}
const e = new Empty;
console.log(e.hello(), e instanceof Empty, e instanceof Point);

// An instance's fields read and written like an object's.
const q = new Point(1, 2);
q.x = 10;
q["y"] = 20;
q.extra = "yes";
console.log(q.x, q.y, q.extra, q.missing, q.toText());
console.log(`${q}`, String(q), q === q, q === new Point(10, 20));

// A method that throws, caught.
class Account {
  constructor(balance) {
    this.balance = balance;
  }
  withdraw(amount) {
    if (amount > this.balance) {
      throw new RangeError(`only ${this.balance} left`);
    }
    this.balance -= amount;
    return this.balance;
  }
}
const account = new Account(50);
try {
  account.withdraw(20);
  account.withdraw(40);
} catch (err) {
  console.log(err.name, err.message, account.balance);
}

// A class declared in a function, and an instance in an array, a Map and
// as a property.
function makeStack() {
  class Stack {
    constructor() {
      this.items = [];
    }
    push(v) {
      this.items.push(v);
      return this.items.length;
    }
    pop() {
      return this.items.pop();
    }
  }
  return new Stack();
}
const s = makeStack();
s.push(1);
s.push(2);
console.log(s.pop(), s.push(3), s.items);
const shelf = [new Point(1, 1), new Point(2, 2)];
const named = new Map([["a", new Point(5, 5)]]);
console.log(shelf.map((pt) => pt.toText()).join(" "), named.get("a").length() > 7);
const holder = { pt: new Point(7, 8) };
console.log(holder.pt.toText(), shelf.every((pt) => pt instanceof Point));
