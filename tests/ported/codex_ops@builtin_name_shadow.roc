# ops@builtin-name-shadow
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@builtin-name-shadow.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     shadowed constant want 64: 64
#     shadowed product  want 192: 192

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# BuiltinNameShadow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

vec_sub : I64
vec_sub = 64

vec_mul : I64
vec_mul = 3

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("shadowed constant want 64: ", Text.show_int(vec_sub))))
	line!(Text.printed(Text.concat("shadowed product  want 192: ", Text.show_int((vec_sub * vec_mul)))))
	Ok({})
}
