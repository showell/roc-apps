# prose-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/prose-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     answer: 42
#     ok:42
#     err:not found
#     fields-12
#     Hello, World!

app [main!] {}

# ProseSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ProseBasic : { value : I64, label : Str }
ProseResult : [Ok(I64), Err(Str)]

add_values : I64, I64 -> I64
add_values = |a, b| (a + b)

describe : ProseBasic -> Str
describe = |pb| Str.concat(Str.concat(pb.label, ": "), I64.to_str(pb.value))

show_result : ProseResult -> Str
show_result = |r| (match r {
	Ok(n) => Str.concat("ok:", I64.to_str(n))
	Err(msg) => Str.concat("err:", msg)
})

field_sum : I64
field_sum = ((0 + 4) + 8)

greet : Str -> Str
greet = |name| Str.concat(Str.concat("Hello, ", name), "!")

eq_proseresult : ProseResult, ProseResult -> Bool
eq_proseresult = |ex, ey| (match ex {
	Ok(exf0) => (match ey {
		Ok(eyf0) => (exf0 == eyf0)
		_ => False
	})
	Err(exf0) => (match ey {
		Err(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	pb = { value: add_values(10, 32), label: "answer" }
	desc = describe(pb)
	r1 = show_result(Ok(42))
	r2 = show_result(Err("not found"))
	line!(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(desc, "\n"), r1), "\n"), r2), "\nfields-"), I64.to_str(field_sum)), "\n"), greet("World")))
	Ok({})
}
