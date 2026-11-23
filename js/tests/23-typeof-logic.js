console.log(typeof 1, typeof "s", typeof true, typeof null, typeof undefined, typeof {}, typeof [], typeof (() => 1), typeof Math.floor);
console.log(1 && 2, 0 && 2, 0 || "x", "" || null, null ?? "d", 0 ?? "d", undefined ?? null);
console.log(!0, !1, !"", !"a", ![], !null, !undefined, !NaN);
console.log(1 === 1, 1 === "1", "a" !== "a", null === undefined, [] === [], NaN === NaN);
const o = {};
const p = o;
console.log(o === p, o !== {});
console.log(3 > 2 ? "yes" : "no", 1 > 2 ? "yes" : 2 > 1 ? "inner" : "no");
