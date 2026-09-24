# iterate-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/iterate-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     5
#     3
#     2
#     3
#     3
#     2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Iterate

# IterateTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

lam_0 : I64 -> I64
lam_0 = |x| (x * 2)

lam_1 : I64 -> Bool
lam_1 = |x| (x > 20)

lam_2 : I64 -> Bool
lam_2 = |x| (x == 30)

lam_3 : I64 -> Bool
lam_3 = |x| (x >= 30)

# --- Entry ---

main! = |_args| {
	({
		xs : List(I64)
		xs = [10, 20, 30, 40, 50]
		doubled : List(I64)
		doubled = Iterate.list_map_generic(lam_0, xs)
		evens : List(I64)
		evens = Iterate.list_filter_generic(lam_1, xs)
		idx : I64
		idx = Iterate.list_find_index(lam_2, xs)
		count : I64
		count = Iterate.list_count_where(lam_3, xs)
		first3 : List(I64)
		first3 = Iterate.list_take_generic(xs, 3)
		last2 : List(I64)
		last2 = Iterate.list_drop_generic(xs, 3)
		({
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(doubled)))))
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(evens)))))
			line!(CceText.printed(CceText.show_int(idx)))
			line!(CceText.printed(CceText.show_int(count)))
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(first3)))))
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(last2)))))
		})
	})
	Ok({})
}
