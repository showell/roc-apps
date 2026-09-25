# typeclass-method-local-independent
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-method-local-independent.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     second

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeclassMethodLocalIndependent -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

first_method_Integer : I64, a -> a
first_method_Integer = |_x, y| y

second_method_Integer : I64, a -> a
second_method_Integer = |_x, y| y

first_method : I64, a -> a
first_method = |_x, y| y

second_method : I64, a -> a
second_method = |_x, y| y

# --- Entry ---

main! = |_args| {
	({
		line!(CceText.printed(CceText.show_int(first_method_Integer(0, 42))))
		line!(CceText.printed(second_method_Integer(0, "second")))
	})
	Ok({})
}
