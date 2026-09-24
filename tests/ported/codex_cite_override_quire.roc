# cite-override-quire
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/cite-override-quire.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     cite-shared 1 = 2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CiteOverrideAlpha
import cdx.Text

# CiteOverrideMain -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("cite-shared 1 = ", Text.show_int(CiteOverrideAlpha.citeoverridealpha_cite_shared(1)))))
	Ok({})
}
