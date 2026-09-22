# act-unused-bind
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/act-unused-bind.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     noisy 1
#     after

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# ActUnusedBind -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

noisy! : I64 => I64
noisy! = |n| ({
	line!(Text.printed(List.concat([18, 16, 17, 19, 30, 2], Text.show_int(n))))
	n
})

# --- Entry ---

main! = |_args| {
	_w = noisy!(1)
	line!(Text.printed([15, 28, 14, 13, 21]))
	Ok({})
}
