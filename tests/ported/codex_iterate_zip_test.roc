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

import cdx.CceText
import cdx.Iterate

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
		xs : List(I64)
		xs = [1, 2, 3, 4, 5]
		ys : List(I64)
		ys = [10, 20, 30]
		zipped : List(I64)
		zipped = Iterate.list_zip_with_generic(lam_0, xs, ys)
		products : List(I64)
		products = Iterate.list_zip_with_generic(lam_1, xs, ys)
		all_true : Bool
		all_true = Iterate.list_all_generic(lam_2, xs)
		any_big : Bool
		any_big = Iterate.list_any_generic(lam_3, xs)
		({
			line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(zipped)))))
			line!(CceText.printed(CceText.show_int((List.get(zipped, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))))
			line!(CceText.printed(CceText.show_int((List.get(zipped, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))))
			line!(CceText.printed(CceText.show_int((List.get(products, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))))
			line!(CceText.printed((if all_true { "True" } else { "False" })))
			line!(CceText.printed((if any_big { "True" } else { "False" })))
		})
	})
	Ok({})
}
