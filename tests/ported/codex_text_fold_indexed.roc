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

import cdx.CceChar
import cdx.CceText
import cdx.TextScan

# TextFoldIndexed -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

count_vowels : CceText -> I64
count_vowels = |s| TextScan.text_fold_indexed(s, 0, lam_0)

lam_0 : I64, CceChar, I64 -> I64
lam_0 = |acc, ch, _idx| (if (ch == CceChar.of_code(15)) { (acc + 1) } else { (if (ch == CceChar.of_code(13)) { (acc + 1) } else { (if (ch == CceChar.of_code(17)) { (acc + 1) } else { (if (ch == CceChar.of_code(16)) { (acc + 1) } else { (if (ch == CceChar.of_code(25)) { (acc + 1) } else { acc }) }) }) }) })

lam_1 : I64, CceChar, I64 -> I64
lam_1 = |acc, _ch, idx| (acc + idx)

lam_2 : CceText, CceChar, I64 -> CceText
lam_2 = |acc, _ch, idx| CceText.concat(acc, CceText.show_int(idx))

lam_3 : I64, CceChar, I64 -> I64
lam_3 = |acc, _ch, _idx| (acc + 1)

# --- Entry ---

main! = |_args| {
	({
		r1 : I64
		r1 = TextScan.text_fold_indexed("abc", 0, lam_1)
		r2 : CceText
		r2 = TextScan.text_fold_indexed("hello", "", lam_2)
		r3 : I64
		r3 = count_vowels("hello world")
		r4 : I64
		r4 = TextScan.text_fold_indexed("test", 0, lam_3)
		({
			line!(CceText.printed(CceText.show_int(r1)))
			line!(CceText.printed(r2))
			line!(CceText.printed(CceText.show_int(r3)))
			line!(CceText.printed(CceText.show_int(r4)))
		})
	})
	Ok({})
}
