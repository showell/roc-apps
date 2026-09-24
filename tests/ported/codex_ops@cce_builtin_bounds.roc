# ops@cce-builtin-bounds
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@cce-builtin-bounds.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     builtin-letter 12,15,70,97: FTFT
#     builtin-ws 0,1,2,3: FTTF

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceChar
import cdx.CceText

# CceBuiltinBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cbb_letter : I64 -> CceText
cbb_letter = |n| (if CceChar.is_letter(CceChar.of_code(n)) { "T" } else { "F" })

cbb_ws : I64 -> CceText
cbb_ws = |n| (if CceChar.is_whitespace(CceChar.of_code(n)) { "T" } else { "F" })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat("builtin-letter 12,15,70,97: ", cbb_letter(12)), cbb_letter(15)), cbb_letter(70)), cbb_letter(97))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat("builtin-ws 0,1,2,3: ", cbb_ws(0)), cbb_ws(1)), cbb_ws(2)), cbb_ws(3))))
	Ok({})
}
