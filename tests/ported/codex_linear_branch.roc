# linear-branch
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/linear-branch.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     15 25 20 30 10 100

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Linear

# LinearBranch -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

consume_in_branch : I64, I64 -> I64
consume_in_branch = |n, cond| (if (cond > 0) { (Linear.freeze(n) + 10) } else { (Linear.freeze(n) + 20) })

consume_in_match : I64, I64 -> I64
consume_in_match = |n, tag| (match tag {
	1 => (Linear.freeze(n) * 2)
	2 => (Linear.freeze(n) * 3)
	_ => Linear.freeze(n)
})

pass_linear : I64 -> I64
pass_linear = |n| ({
	result : I64
	result = Linear.freeze(n)
	(result + 1)
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.show_int(consume_in_branch(5, 1)), " "), CceText.show_int(consume_in_branch(5, 0))), " "), CceText.show_int(consume_in_match(10, 1))), " "), CceText.show_int(consume_in_match(10, 2))), " "), CceText.show_int(consume_in_match(10, 0))), " "), CceText.show_int(pass_linear(99)))))
	Ok({})
}
