# let-else-scope
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/let-else-scope.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     7018
#     7098

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# LetElseScope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pick : I64, I64 -> I64
pick = |n, m| ({
	base = (m * 1000)
	reuse = (n - 1)
	(if (reuse >= 0) { ({
		s = (reuse + 10)
		((s + reuse) + base)
	}) } else { ({
		loc = (n + 2)
		s = (loc + 100)
		((s + loc) + base)
	}) })
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.show_int(pick(5, 7))))
	line!(Text.printed(Text.show_int(pick((-3), 7))))
	Ok({})
}
