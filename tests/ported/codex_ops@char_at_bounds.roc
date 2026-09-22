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

s : List(U8)
s = [15, 32, 24, 22, 13]

walk : I64, I64, List(U8) -> List(U8)
walk = |i, n, acc| (if (i >= n) { acc } else { walk((i + 1), n, List.concat(List.concat(List.concat(List.concat(acc, [2]), Text.show_int(i)), [77]), Text.show_int(Text.char_code_at(s, i)))) })

walk_chars : I64, I64, List(U8) -> List(U8)
walk_chars = |i, n, acc| (if (i >= n) { acc } else { walk_chars((i + 1), n, List.concat(acc, Text.char_to_text(Text.char_at(s, i)))) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([24, 16, 22, 13, 19, 69], walk(0, Text.len(s), []))))
	line!(Text.printed(List.concat(List.concat([24, 20, 15, 21, 19, 77, 88], walk_chars(0, Text.len(s), [])), [89])))
	line!(Text.printed(List.concat([23, 15, 19, 14, 73, 23, 13, 29, 15, 23, 77], Text.show_int(Text.char_code_at(s, (Text.len(s) - 1))))))
	line!(Text.printed(List.concat([28, 17, 21, 19, 14, 77], Text.show_int(Text.char_code_at(s, 0)))))
	Ok({})
}
