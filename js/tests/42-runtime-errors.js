// The interpreter's own errors are JavaScript's: each caught, by name and
// message, as node words them.
const cases = [
  () => {
    const o = null;
    return o.x;
  },
  () => {
    const o = undefined;
    return o.x.y;
  },
  () => {
    const o = null;
    o.x = 1;
  },
  () => {
    let o;
    o[3] = 1;
  },
  () => {
    const n = 3;
    n();
  },
  () => {
    const o = {};
    o.f();
  },
  () => {
    const o = { a: {} };
    o.a.b();
  },
  () => {
    const a = [1];
    a[0]();
  },
  () => {
    const f = () => 1;
    f()();
  },
  () => notDeclared,
  () => {
    const x = 1;
    x = 2;
  },
  () => {
    let q = q + 1;
  },
  () => {
    function f(a = b, b) {}
    f();
  },
  () => {
    let early = later;
    let later = 1;
  },
  () => {
    const i = 3;
    for (let i = i + 1; i < 5; i++) {
    }
  },
  () => {
    let x = 1;
    {
      x = 2;
      let x = 3;
    }
  },
  () => [...5],
  () => {
    const t = 5;
    for (const x of t) {
    }
  },
  () => {
    const x = 5;
    const [a] = x;
  },
  () => {
    const o = null;
    const { a } = o;
  },
  () => {
    const o = { p: null };
    const { a } = o.p;
  },
  () => {
    function f({ a }) {}
    f(null);
  },
  () => {
    function f([a]) {}
    f(5);
  },
  () => {
    const { a: { b } } = {};
  },
  () => [].reduce((a, b) => a),
  () => {
    const m = Math.floor;
    new m();
  },
  () => {
    function f(n) {
      return f(n + 1);
    }
    f(0);
  },
];
for (const c of cases) {
  try {
    c();
    console.log("no error");
  } catch (e) {
    console.log(`${e.name} | ${e.message}`);
  }
}
