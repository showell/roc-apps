# ops@text-order-allowed
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@text-order-allowed.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     eq-same-content = 1
#     eq-diff-content = 0
#     neq-diff        = 1
#     cmp-a-b         = -1
#     cmp-a-a         = 0
#     cmp-d-b         = -1

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# TextOrderAllowed -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

b2i : Bool -> I64
b2i = |b| (if b { 1 } else { 0 })

mk : I64 -> Text
mk = |n| Text.char_to_text(n)

sign : I64 -> I64
sign = |n| (if (n < 0) { (0 - 1) } else { (if (n > 0) { 1 } else { 0 }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("eq-same-content = ", Text.show_int(b2i((mk(15) == mk(15)))))))
	line!(Text.printed(Text.concat("eq-diff-content = ", Text.show_int(b2i((mk(15) == mk(32)))))))
	line!(Text.printed(Text.concat("neq-diff        = ", Text.show_int(b2i((mk(15) != mk(32)))))))
	line!(Text.printed(Text.concat("cmp-a-b         = ", Text.show_int(sign(Text.compare("a", "b"))))))
	line!(Text.printed(Text.concat("cmp-a-a         = ", Text.show_int(sign(Text.compare("a", "a"))))))
	line!(Text.printed(Text.concat("cmp-d-b         = ", Text.show_int(sign(Text.compare("d", "b"))))))
	Ok({})
}
