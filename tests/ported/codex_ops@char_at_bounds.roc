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

import cdx.Text

# CharAtBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s : Text
s = "abcde"

walk : I64, I64, Text -> Text
walk = |i, n, acc| (if (i >= n) { acc } else { walk((i + 1), n, Text.concat(Text.concat(Text.concat(Text.concat(acc, " "), Text.show_int(i)), "="), Text.show_int(Text.char_code_at(s, i)))) })

walk_chars : I64, I64, Text -> Text
walk_chars = |i, n, acc| (if (i >= n) { acc } else { walk_chars((i + 1), n, Text.concat(acc, Text.char_to_text(Text.char_at(s, i)))) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("codes:", walk(0, Text.len(s), ""))))
	line!(Text.printed(Text.concat(Text.concat("chars=[", walk_chars(0, Text.len(s), "")), "]")))
	line!(Text.printed(Text.concat("last-legal=", Text.show_int(Text.char_code_at(s, (Text.len(s) - 1))))))
	line!(Text.printed(Text.concat("first=", Text.show_int(Text.char_code_at(s, 0)))))
	Ok({})
}
