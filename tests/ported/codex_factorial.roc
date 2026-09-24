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
import cdx.Text

# Factorial -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_(a) : [Wrap(a)]
Shape : [Circle(F64), Rectangle(F64, F64)]
Result_(a) : [Success(a), Failure(Text)]
Person : { name : Text, age : I64 }
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

greeting : Text -> Text
greeting = |name| Text.concat(Text.concat("Hello, ", name), "!")

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

describe : Result_(I64) -> Text
describe = |result| (match result {
	Success(n) => Text.concat("got ", Text.show_int(n))
	Failure(msg) => Text.concat("error: ", msg)
})

greet : Person -> Text
greet = |p| Text.concat(Text.concat("Hello, ", p.name), "!")

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
	line!(Text.printed(Text.concat("literal: ", Text.show_int(42))))
	line!(Text.printed(Text.concat("mul: ", Text.show_int((3 * 4)))))
	line!(Text.printed(Text.concat("if: ", Text.show_int((if (1 == 1) { 77 } else { 88 })))))
	line!(Text.printed(Text.concat("call: ", Text.show_int(add1(9)))))
	line!(Text.printed(Text.concat("rec: ", Text.show_int(countdown(5)))))
	line!(Text.printed(Text.concat("square: ", Text.show_int(square(5)))))
	line!(Text.printed(Text.concat("fact1: ", Text.show_int(fact(1)))))
	line!(Text.printed(Text.concat("fact2: ", Text.show_int(fact(2)))))
	line!(Text.printed(Text.concat("fact3: ", Text.show_int(fact(3)))))
	line!(Text.printed(Text.concat("fact5: ", Text.show_int(fact(5)))))
	line!(Text.printed(Text.concat("fact10: ", Text.show_int(fact(10)))))
	line!(Text.printed(Text.concat("fib20: ", Text.show_int(fib(20)))))
	line!(Text.printed(Text.concat("greeting: ", greeting("World"))))
	line!(Text.printed(Text.concat("wrap: ", (match Wrap(7) {
		Wrap(x) => Text.concat("Wrap ", Text.show_int(x))
	}))))
	line!(Text.printed(Text.concat("unwrap: ", Text.show_int(unwrap(Wrap(7))))))
	line!(Text.printed(Text.concat("area: ", Text.of_str(Prelude.real_to_str(area(Circle(5.0)))))))
	line!(Text.printed(Text.concat("person: ", greet({ name: "Alice", age: 30 }))))
	line!(Text.printed(Text.concat("number: ", (if Prelude.approx_eq(3.14, 3.14) { (if Prelude.approx_eq(1.5, 2.5) { "FAIL" } else { "PASS" }) } else { "FAIL" }))))
	line!(Text.printed(Text.concat("safe-divide: ", describe(safe_divide(42, 7)))))
	line!(Text.printed(Text.concat("paren-field: ", Text.show_int(ignore_second(99, mk.val)))))
	Ok({})
}
