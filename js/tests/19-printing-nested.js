console.log({ a: { b: { c: { d: 1 } } } });
console.log([[1, [2, [3, [4, [5]]]]]]);
console.log({ list: [1, 2, 3], nested: { deep: [{ x: 1 }, { y: [2] }] } });
console.log([{}, [], { a: [] }, [{}]]);
const long = { alpha: "some longer string here", beta: [1, 2, 3], gamma: { delta: "more text to make it long", eps: 12345 } };
console.log(long);
console.log([long, long]);
