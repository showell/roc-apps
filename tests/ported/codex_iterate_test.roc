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
		xs = [10, 20, 30, 40, 50]
		doubled = Iterate.list_map_generic(lam_0, xs)
		evens = Iterate.list_filter_generic(lam_1, xs)
		idx = Iterate.list_find_index(lam_2, xs)
		count = Iterate.list_count_where(lam_3, xs)
		first3 = Iterate.list_take_generic(xs, 3)
		last2 = Iterate.list_drop_generic(xs, 3)
		({
			line!(I64.to_str(U64.to_i64_wrap(List.len(doubled))))
			line!(I64.to_str(U64.to_i64_wrap(List.len(evens))))
			line!(I64.to_str(idx))
			line!(I64.to_str(count))
			line!(I64.to_str(U64.to_i64_wrap(List.len(first3))))
			line!(I64.to_str(U64.to_i64_wrap(List.len(last2))))
		})
	})
	Ok({})
}
