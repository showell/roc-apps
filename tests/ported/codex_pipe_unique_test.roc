# pipe-unique-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/pipe-unique-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     7
#     True
#     True
#     False

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Pipeline

# PipeUniqueTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		xs : List(I64)
		xs = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
		unique : List(I64)
		unique = Pipeline.pipe_unique(xs)
		count : I64
		count = U64.to_i64_wrap(List.len(unique))
		({
			line!(CceText.printed(CceText.show_int(count)))
			line!(CceText.printed((if Pipeline.pipe_contains(unique, 1) { "True" } else { "False" })))
			line!(CceText.printed((if Pipeline.pipe_contains(unique, 9) { "True" } else { "False" })))
			line!(CceText.printed((if Pipeline.pipe_contains(unique, 7) { "True" } else { "False" })))
		})
	})
	Ok({})
}
