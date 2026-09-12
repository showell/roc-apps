# path-real
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/path-real.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     /src/main.codex
#     main.codex
#     main
#     codex

app [main!] { cdx: "./codex/main.roc" }

import cdx.Path

# PathReal -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Path.path_join("/src", "main.codex"))
	line!(Path.path_filename("/src/main.codex"))
	line!(Path.path_stem("/src/main.codex"))
	line!(Path.path_extension("/src/main.codex"))
	Ok({})
}
