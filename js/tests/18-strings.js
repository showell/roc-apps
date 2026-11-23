const s = "Hello, World";
console.log(s.length, s[0], s.charAt(4), s.charCodeAt(0), s.indexOf("World"), s.indexOf("x"));
console.log(s.slice(7), s.slice(-5, -1), s.substring(5, 0), s.toUpperCase(), s.toLowerCase());
console.log(s.includes("lo, "), s.startsWith("Hell"), s.endsWith("ld"), "  pad  ".trim() + "|");
console.log("a,b,,c".split(","), "abc".split(""), "ab".repeat(3), "7".padStart(3, "0"), "x".padEnd(4, "-.") + "|");
console.log(String(42), String([1, 2]), String(null), String.fromCharCode(72, 105), "a".concat("b", 1));
console.log("apple" < "banana", "b" > "a", "abc" < "ab", "Z" < "a");
