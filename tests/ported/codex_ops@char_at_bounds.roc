# ops@char-at-bounds
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@char-at-bounds.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     codes: 0=15 1=32 2=24 3=22 4=13
#     chars=[abcde]
#     last-legal=13
#     first=15

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# CharAtBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s : CceText
s = "abcde"

walk : I64, I64, CceText -> CceText
walk = |i, n, acc| (if (i >= n) { acc } else { walk((i + 1), n, CceText.concat(CceText.concat(CceText.concat(CceText.concat(acc, " "), CceText.show_int(i)), "="), CceText.show_int(CceText.char_code_at(s, i)))) })

walk_chars : I64, I64, CceText -> CceText
walk_chars = |i, n, acc| (if (i >= n) { acc } else { walk_chars((i + 1), n, CceText.concat(acc, CceText.char_to_text(CceText.char_at(s, i)))) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("codes:", walk(0, CceText.len(s), ""))))
	line!(CceText.printed(CceText.concat(CceText.concat("chars=[", walk_chars(0, CceText.len(s), "")), "]")))
	line!(CceText.printed(CceText.concat("last-legal=", CceText.show_int(CceText.char_code_at(s, (CceText.len(s) - 1))))))
	line!(CceText.printed(CceText.concat("first=", CceText.show_int(CceText.char_code_at(s, 0)))))
	Ok({})
}
