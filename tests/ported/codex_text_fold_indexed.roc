# text-fold-indexed
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/text-fold-indexed.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3
#     01234
#     3
#     4

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.TextScan

# TextFoldIndexed -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

count_vowels : List(U8) -> I64
count_vowels = |s| TextScan.text_fold_indexed(s, 0, lam_0)

lam_0 : I64, I64, I64 -> I64
lam_0 = |acc, ch, _idx| (if (ch == 15) { (acc + 1) } else { (if (ch == 13) { (acc + 1) } else { (if (ch == 17) { (acc + 1) } else { (if (ch == 16) { (acc + 1) } else { (if (ch == 25) { (acc + 1) } else { acc }) }) }) }) })

lam_1 : I64, I64, I64 -> I64
lam_1 = |acc, _ch, idx| (acc + idx)

lam_2 : List(U8), I64, I64 -> List(U8)
lam_2 = |acc, _ch, idx| List.concat(acc, Text.show_int(idx))

lam_3 : I64, I64, I64 -> I64
lam_3 = |acc, _ch, _idx| (acc + 1)

# --- Entry ---

main! = |_args| {
	({
		r1 = TextScan.text_fold_indexed([15, 32, 24], 0, lam_1)
		r2 = TextScan.text_fold_indexed([20, 13, 23, 23, 16], [], lam_2)
		r3 = count_vowels([20, 13, 23, 23, 16, 2, 27, 16, 21, 23, 22])
		r4 = TextScan.text_fold_indexed([14, 13, 19, 14], 0, lam_3)
		({
			line!(Text.printed(Text.show_int(r1)))
			line!(Text.printed(r2))
			line!(Text.printed(Text.show_int(r3)))
			line!(Text.printed(Text.show_int(r4)))
		})
	})
	Ok({})
}
