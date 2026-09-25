# normalize-eq
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/normalize-eq.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     normalize-eq ok

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# NormalizeEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Bit : [On, Off]

flip : Bit -> Bit
flip = |b| (match b {
	On => Off
	Off => On
})

id_bit : Bit -> Bit
id_bit = |x| x

eq_Bit : Bit, Bit -> Bool
eq_Bit = |ex, ey| (match ex {
	On => (match ey {
		On => True
		_ => False
	})
	Off => (match ey {
		Off => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed("normalize-eq ok"))
	Ok({})
}
