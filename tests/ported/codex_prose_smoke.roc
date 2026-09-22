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

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ProseSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ProseBasic : { value : I64, label : List(U8) }
ProseResult : [Ok(I64), Err(List(U8))]

add_values : I64, I64 -> I64
add_values = |a, b| (a + b)

describe : ProseBasic -> List(U8)
describe = |pb| List.concat(List.concat(pb.label, [69, 2]), Text.show_int(pb.value))

show_result : ProseResult -> List(U8)
show_result = |r| (match r {
	Ok(n) => List.concat([16, 34, 69], Text.show_int(n))
	Err(msg) => List.concat([13, 21, 21, 69], msg)
})

field_sum : I64
field_sum = ((0 + 4) + 8)

greet : List(U8) -> List(U8)
greet = |name| List.concat(List.concat([46, 13, 23, 23, 16, 66, 2], name), [67])

eq_ProseResult : ProseResult, ProseResult -> Bool
eq_ProseResult = |ex, ey| (match ex {
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
	pb = { value: add_values(10, 32), label: [15, 18, 19, 27, 13, 21] }
	desc = describe(pb)
	r1 = show_result(Ok(42))
	r2 = show_result(Err([18, 16, 14, 2, 28, 16, 25, 18, 22]))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(desc, [1]), r1), [1]), r2), [1, 28, 17, 13, 23, 22, 19, 73]), Text.show_int(field_sum)), [1]), greet([53, 16, 21, 23, 22]))))
	Ok({})
}
