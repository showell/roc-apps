// A morning at a small bank, told with classes. Each `SUPPORTS` comment
// marks the first use of a class's feature. No account is printed whole:
// node prints `Account { owner: 'ada', ... }`, which the subset refuses
// rather than print differently.

const opened = [];

// SUPPORTS class, with a constructor and methods
class Account {
  constructor(owner, balance = 0) {
    // SUPPORTS this, in a constructor
    this.owner = owner;
    this.balance = balance;
    this.history = [];
    opened.push(owner);
  }
  deposit(amount) {
    this.balance += amount;
    this.history.push(`+${amount}`);
    // SUPPORTS a method answering this, so calls chain
    return this;
  }
  withdraw(amount) {
    if (amount > this.balance) {
      throw new RangeError(`${this.owner} has only ${this.balance}`);
    }
    this.balance -= amount;
    this.history.push(`-${amount}`);
    return this;
  }
  statement() {
    // SUPPORTS this inside an arrow, taken from the method around it
    const lines = this.history.map((entry) => `${this.owner}: ${entry}`);
    return lines.join(", ");
  }
  // SUPPORTS static methods
  static between(from, to, amount) {
    from.withdraw(amount);
    to.deposit(amount);
  }
}

// SUPPORTS extends, super(...) and super.method()
class Savings extends Account {
  constructor(owner, balance, rate) {
    super(owner, balance);
    this.rate = rate;
  }
  addInterest() {
    return this.deposit(Math.round(this.balance * this.rate));
  }
  statement() {
    return `${super.statement()} (savings at ${this.rate * 100}%)`;
  }
}

// SUPPORTS new
const ada = new Account("ada", 100);
const bob = new Savings("bob", 1000, 0.05);

ada.deposit(50).withdraw(30);
bob.addInterest();
// SUPPORTS a static method inherited from the parent class
Savings.between(bob, ada, 200);

try {
  ada.withdraw(10000);
} catch (err) {
  console.log(err.name, err.message);
}

console.log(ada.statement());
console.log(bob.statement());
console.log("balances:", ada.balance, bob.balance);

// SUPPORTS instanceof, up the chain
for (const who of [ada, bob]) {
  console.log(who.owner, who instanceof Account, who instanceof Savings);
}

// Many accounts, each with its own closures over its own `this`.
const town = Array.from({ length: 5 }, (_, i) => new Savings(`saver${i}`, 100 * (i + 1), 0.1));
town.forEach((s) => s.addInterest());
console.log(town.map((s) => s.balance).join(" "), opened.length);
