# linear-capture-once
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/linear-capture-once.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Linear

# LinearCaptureOnce -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

use_closure : I64 -> I64
use_closure = |n| ({
	f = ({
		dev__1 = n
		|dev__2| lam_0(dev__1, dev__2)
	})
	f(1)
})

take2 : I64, I64 -> I64
take2 = |n, x| (Linear.freeze(n) + x)

use_partial : I64 -> I64
use_partial = |n| ({
	g = ({
		dev__1 = n
		|dev__2| take2(dev__1, dev__2)
	})
	g(5)
})

lam_0 : I64, I64 -> I64
lam_0 = |n, x| (n + x)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.show_int(use_closure(41)), " "), CceText.show_int(use_partial(37)))))
	Ok({})
}
