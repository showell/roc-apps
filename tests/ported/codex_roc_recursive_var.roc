# roc-recursive-var
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-recursive-var.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     6

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RocRecursiveVar -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

f : I64 -> I64
f = |n| ({
	state = n
	(if (n > 0) { ({
		inner = f((n - 1))
		(state + inner)
	}) } else { state })
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(f(3))))
	Ok({})
}
