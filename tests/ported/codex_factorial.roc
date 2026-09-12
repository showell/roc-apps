# factorial
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/factorial.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     literal: 42
#     mul: 12
#     if: 77
#     call: 10
#     rec: 0
#     square: 25
#     fact1: 1
#     fact2: 2
#     fact3: 6
#     fact5: 120
#     fact10: 3628800
#     fib20: 6765
#     greeting: Hello, World!
#     wrap: Wrap 7
#     unwrap: 7
#     area: 78.5
#     person: Hello, Alice!
#     number: PASS
#     safe-divide: got 6
#     paren-field: 99

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude

# Factorial -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_(a) : [Wrap(a)]
Shape : [Circle(F64), Rectangle(F64, F64)]
Result_(a) : [Success(a), Failure(Str)]
Person : { name : Str, age : I64 }
Box2 : { val : I64 }

square : I64 -> I64
square = |x| (x * x)

double : I64 -> I64
double = |x| (x + x)

add1 : I64 -> I64
add1 = |x| (x + 1)

countdown : I64 -> I64
countdown = |n| (if (n == 0) { 0 } else { countdown((n - 1)) })

fact : I64 -> I64
fact = |n| (if (n == 0) { 1 } else { (n * fact((n - 1))) })

fib : I64 -> I64
fib = |n| (if (n == 0) { 0 } else { (if (n == 1) { 1 } else { (fib((n - 1)) + fib((n - 2))) }) })

greeting : Str -> Str
greeting = |name| Str.concat(Str.concat("Hello, ", name), "!")

unwrap : Box_(I64) -> I64
unwrap = |b| (match b {
	Wrap(x) => x
})

area : Shape -> F64
area = |s| (match s {
	Circle(r) => ((3.14 * r) * r)
	Rectangle(w, h) => (w * h)
})

safe_divide : I64, I64 -> Result_(I64)
safe_divide = |x, y| (if (y == 0) { Failure("division by zero") } else { Success(I64.div_trunc_by(x, y)) })

describe : Result_(I64) -> Str
describe = |result| (match result {
	Success(n) => Str.concat("got ", I64.to_str(n))
	Failure(msg) => Str.concat("error: ", msg)
})

greet : Person -> Str
greet = |p| Str.concat(Str.concat("Hello, ", p.name), "!")

mk : Box2
mk = { val: 7 }

ignore_second : I64, I64 -> I64
ignore_second = |x, _y| x

eq_Box : Box_(a), Box_(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Box = |ex, ey| (match ex {
	Wrap(exf0) => (match ey {
		Wrap(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

eq_Result : Result_(a), Result_(a) -> Bool where [a.is_eq : a, a -> Bool]
eq_Result = |ex, ey| (match ex {
	Success(exf0) => (match ey {
		Success(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Failure(exf0) => (match ey {
		Failure(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("literal: ", I64.to_str(42)))
	line!(Str.concat("mul: ", I64.to_str((3 * 4))))
	line!(Str.concat("if: ", I64.to_str((if (1 == 1) { 77 } else { 88 }))))
	line!(Str.concat("call: ", I64.to_str(add1(9))))
	line!(Str.concat("rec: ", I64.to_str(countdown(5))))
	line!(Str.concat("square: ", I64.to_str(square(5))))
	line!(Str.concat("fact1: ", I64.to_str(fact(1))))
	line!(Str.concat("fact2: ", I64.to_str(fact(2))))
	line!(Str.concat("fact3: ", I64.to_str(fact(3))))
	line!(Str.concat("fact5: ", I64.to_str(fact(5))))
	line!(Str.concat("fact10: ", I64.to_str(fact(10))))
	line!(Str.concat("fib20: ", I64.to_str(fib(20))))
	line!(Str.concat("greeting: ", greeting("World")))
	line!(Str.concat("wrap: ", (match Wrap(7) {
		Wrap(x) => Str.concat("Wrap ", I64.to_str(x))
	})))
	line!(Str.concat("unwrap: ", I64.to_str(unwrap(Wrap(7)))))
	line!(Str.concat("area: ", Prelude.real_to_str(area(Circle(5.0)))))
	line!(Str.concat("person: ", greet({ name: "Alice", age: 30 })))
	line!(Str.concat("number: ", (if Prelude.approx_eq(3.14, 3.14) { (if Prelude.approx_eq(1.5, 2.5) { "FAIL" } else { "PASS" }) } else { "FAIL" })))
	line!(Str.concat("safe-divide: ", describe(safe_divide(42, 7))))
	line!(Str.concat("paren-field: ", I64.to_str(ignore_second(99, mk.val))))
	Ok({})
}
