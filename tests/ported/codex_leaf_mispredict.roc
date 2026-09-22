# leaf-mispredict
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/leaf-mispredict.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     222
#     -33

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# LeafMispredict -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

m_swap : I64, I64, I64 -> I64
m_swap = |n, a, b| (if (n == 0) { a } else { m_swap((n - 1), b, a) })

p_shift : I64, I64 -> I64
p_shift = |n, a| (if (n == 0) { a } else { p_shift((n - 1), ((a + a) - n)) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(m_swap(7, 111, 222))))
	line!(Text.printed(Text.show_int(p_shift(5, 3))))
	Ok({})
}
