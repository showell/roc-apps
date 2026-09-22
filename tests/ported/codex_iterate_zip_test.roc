# iterate-zip-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/iterate-zip-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3
#     11
#     33
#     40
#     True
#     False

app [main!] { cdx: "./codex/main.roc" }

import cdx.Iterate
import cdx.Text

# IterateZipTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

lam_0 : I64, I64 -> I64
lam_0 = |a, b| (a + b)

lam_1 : I64, I64 -> I64
lam_1 = |a, b| (a * b)

lam_2 : I64 -> Bool
lam_2 = |x| (x > 0)

lam_3 : I64 -> Bool
lam_3 = |x| (x > 100)

# --- Entry ---

main! = |_args| {
	({
		xs = [1, 2, 3, 4, 5]
		ys = [10, 20, 30]
		zipped = Iterate.list_zip_with_generic(lam_0, xs, ys)
		products = Iterate.list_zip_with_generic(lam_1, xs, ys)
		all_true = Iterate.list_all_generic(lam_2, xs)
		any_big = Iterate.list_any_generic(lam_3, xs)
		({
			line!(Text.printed(Text.show_int(U64.to_i64_wrap(List.len(zipped)))))
			line!(Text.printed(Text.show_int((List.get(zipped, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))))
			line!(Text.printed(Text.show_int((List.get(zipped, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))))
			line!(Text.printed(Text.show_int((List.get(products, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))))
			line!(Text.printed((if all_true { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })))
			line!(Text.printed((if any_big { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })))
		})
	})
	Ok({})
}
