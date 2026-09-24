# roc-returned-closure
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-returned-closure.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     9

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RocReturnedClosure -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Wrapped : { next : (I64 -> I64) }

wrap : (I64 -> I64) -> Wrapped
wrap = |transform| { next: ({
	dev__1 = transform
	|dev__2| lam_0(dev__1, dev__2)
}) }

lam_0 : (I64 -> I64), I64 -> I64
lam_0 = |transform, _ignored| transform(1)

lam_1 : I64 -> I64
lam_1 = |_x| 9

# --- Entry ---

main! = |_args| {
	({
		wrapped = wrap(lam_1)
		line!(CceText.printed(CceText.show_int((wrapped.next)(0))))
	})
	Ok({})
}
