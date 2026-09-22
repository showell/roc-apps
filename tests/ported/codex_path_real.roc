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
import cdx.Text

# PathReal -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Path.path_join([81, 19, 21, 24], [26, 15, 17, 18, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_filename([81, 19, 21, 24, 81, 26, 15, 17, 18, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_stem([81, 19, 21, 24, 81, 26, 15, 17, 18, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_extension([81, 19, 21, 24, 81, 26, 15, 17, 18, 65, 24, 16, 22, 13, 36])))
	Ok({})
}
