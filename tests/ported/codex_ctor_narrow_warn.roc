# ctor-narrow-warn
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ctor-narrow-warn.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42

app [main!] {}

# CtorNarrowWarn -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Byteish : [MkByte(I64)]

use_byte : Byteish -> I64
use_byte = |b| (match b {
	MkByte(v) => v
})

make_byte_narrowed : I64 -> Byteish
make_byte_narrowed = |n| MkByte(n)

eq_Byteish : Byteish, Byteish -> Bool
eq_Byteish = |ex, ey| (match ex {
	MkByte(exf0) => (match ey {
		MkByte(eyf0) => (exf0 == eyf0)
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(I64.to_str(use_byte(make_byte_narrowed(42))))
	Ok({})
}
