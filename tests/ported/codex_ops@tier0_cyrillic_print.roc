# ops@tier0-cyrillic-print
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@tier0-cyrillic-print.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     cyrillic-113-127: аоеинтсрвлкмдпу
#     accented-97-104:  éèêëáàâä
#     ascii-3-12:       0123456789

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# TierZeroCyrillicPrint -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

show_run : I64, I64, Text -> Text
show_run = |i, stop, acc| (if (i > stop) { acc } else { show_run((i + 1), stop, Text.concat(acc, Text.char_to_text(i))) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("cyrillic-113-127: ", show_run(113, 127, ""))))
	line!(Text.printed(Text.concat("accented-97-104:  ", show_run(97, 104, ""))))
	line!(Text.printed(Text.concat("ascii-3-12:       ", show_run(3, 12, ""))))
	Ok({})
}
