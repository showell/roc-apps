# tuple-syntax
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tuple-syntax.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     30
#     20 10
#     1
#     12
#     300

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Tuple

# TupleSyntax -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

swap : Tuple.Tup2(I64, I64) -> Tuple.Tup2(I64, I64)
swap = |p| (match p {
	MkTup2(x, y) => MkTup2(y, x)
})

sum_pair : Tuple.Tup2(I64, I64) -> I64
sum_pair = |p| (match p {
	MkTup2(x, y) => (x + y)
})

fst3 : Tuple.Tup3(I64, I64, I64) -> I64
fst3 = |t| (match t {
	MkTup3(a, _b, _c) => a
})

nested_sum : Tuple.Tup2(Tuple.Tup2(I64, I64), I64) -> I64
nested_sum = |outer| (match outer {
	MkTup2(inner, z) => (sum_pair(inner) + z)
})

# --- Entry ---

main! = |_args| {
	({
		p = MkTup2(10, 20)
		({
			({
				line!(CceText.printed(CceText.show_int(sum_pair(p))))
				(match swap(p) {
					MkTup2(a, b) => ({
						line!(CceText.printed(CceText.concat(CceText.concat(CceText.show_int(a), " "), CceText.show_int(b))))
					})
				})
			})
			line!(CceText.printed(CceText.show_int(fst3(MkTup3(1, 2, 3)))))
			({
				q = MkTup2(MkTup2(3, 4), 5)
				({
					line!(CceText.printed(CceText.show_int(nested_sum(q))))
					line!(CceText.printed(CceText.show_int(sum_pair(MkTup2(100, 200)))))
				})
			})
		})
	})
	Ok({})
}
