# string-escape-quote
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/string-escape-quote.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     she said "hi" loudly

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# StringEscapeQuote -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

q : List(U8)
q = [19, 20, 13, 2, 19, 15, 17, 22, 2, 72, 20, 17, 72, 2, 23, 16, 25, 22, 23, 30]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(q))
	Ok({})
}
