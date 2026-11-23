// throw, try, catch and finally: any value thrown and caught, a catch with
// no binding, finally after a normal end, a return, a break and a throw.
function attempt(f) {
  try {
    return `ok ${f()}`;
  } catch (e) {
    return `caught ${typeof e} ${String(e)}`;
  }
}
console.log(attempt(() => 1));
console.log(attempt(() => {
  throw 42;
}));
console.log(attempt(() => {
  throw "words";
}));
console.log(attempt(() => {
  throw null;
}));
console.log(attempt(() => {
  throw new Error("plain");
}));
console.log(attempt(() => {
  throw new RangeError("out of range");
}));

try {
  throw { code: 7, why: "an object" };
} catch ({ code, why }) {
  console.log(code, why);
}

try {
  throw [1, 2, 3];
} catch (e) {
  console.log(e, e.length);
}

try {
  throw 1;
} catch {
  console.log("caught without a binding");
}

const order = [];
function withFinally(kind) {
  try {
    order.push(`try ${kind}`);
    if (kind === "throw") throw new TypeError("thrown");
    if (kind === "return") return "returned";
    return "fell through";
  } catch (e) {
    order.push(`catch ${e.message}`);
    return "from catch";
  } finally {
    order.push(`finally ${kind}`);
  }
}
console.log(withFinally("return"), withFinally("throw"), withFinally("plain"));
console.log(order);

function finallyWins() {
  try {
    return "try";
  } finally {
    return "finally";
  }
}
console.log(finallyWins());

function finallySwallows() {
  for (let i = 0; i < 3; i++) {
    try {
      throw new Error(`pass ${i}`);
    } finally {
      if (i < 2) continue;
      break;
    }
  }
  return "swallowed";
}
console.log(finallySwallows());

function rethrows() {
  try {
    try {
      throw new Error("inner");
    } catch (e) {
      throw new Error(`${e.message}, again`);
    } finally {
      console.log("inner finally");
    }
  } catch (e) {
    return e.message;
  }
}
console.log(rethrows());

function deep(n) {
  if (n === 0) throw new Error("at the bottom");
  return deep(n - 1) + 1;
}
try {
  deep(50);
} catch (e) {
  console.log(e.name, e.message);
}

const total = [1, 2, 3].reduce((sum, n) => {
  try {
    if (n === 2) throw n;
    return sum + n;
  } catch (two) {
    return sum + two * 100;
  }
}, 0);
console.log(total);

try {
  [1, 2, 3].forEach((n) => {
    if (n === 2) throw new Error(`stopped at ${n}`);
    console.log("visited", n);
  });
} catch (e) {
  console.log(e.message);
}

const e = new Error("described");
console.log(String(e), `${e}`, e + "!", e.name, e.message, typeof e);
console.log(String(new TypeError()), String(new SyntaxError("s")), new ReferenceError("r").name);
console.log(new Error(5).message, new Error(undefined).message === "", e === e);
