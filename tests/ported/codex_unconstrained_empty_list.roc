# unconstrained-empty-list
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unconstrained-empty-list.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     0
#     0
#     0
#     0
#     0
#     42
#     text

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnconstrainedEmptyList -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

make_empty : I64 -> List(a)
make_empty = |_n| []

typed_empty : a -> List(a)
typed_empty = |_witness| []

identity_value : a -> a
identity_value = |value| value

empty_text : List(CceText)
empty_text = make_empty(2)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(make_empty(0))))))
	line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(make_empty(1))))))
	line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(typed_empty(42))))))
	line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(typed_empty("text"))))))
	line!(CceText.printed(CceText.show_int(U64.to_i64_wrap(List.len(empty_text)))))
	line!(CceText.printed(CceText.show_int(identity_value(42))))
	line!(CceText.printed(identity_value("text")))
	Ok({})
}
