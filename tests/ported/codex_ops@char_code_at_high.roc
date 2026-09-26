# ops@char-code-at-high
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@char-code-at-high.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     127: 127
#     128: 192 128
#     2175: 223 191
#     100000: 240 135 184 160

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceChar
import cdx.CceText

# CharCodeAtHigh -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bytes_of : CceText, I64 -> CceText
bytes_of = |t, i| (if (i >= CceText.len(t)) { "" } else { CceText.concat(CceText.concat(" ", CceText.show_int(CceText.char_code_at(t, i))), bytes_of(t, (i + 1))) })

line_for : I64 -> CceText
line_for = |cp| CceText.concat(CceText.concat(CceText.show_int(cp), ":"), bytes_of(CceText.char_encode(CceChar.of_code(cp)), 0))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(line_for(127)))
	line!(CceText.printed(line_for(128)))
	line!(CceText.printed(line_for(2175)))
	line!(CceText.printed(line_for(100000)))
	Ok({})
}
