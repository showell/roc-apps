# ops@section-title-keywords
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@section-title-keywords.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     <42>

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# SectionTitleKeywords -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ShowableDict(a) : { to_text_impl : (a -> CceText) }

describe : I64 -> CceText
describe = |x| CceText.concat(CceText.concat("<", to_text(x)), ">")

showable_dict_Integer : ShowableDict(I64)
showable_dict_Integer = { to_text_impl: lam_0 }

to_text_Integer : I64 -> CceText
to_text_Integer = |x| CceText.show_int(x)

to_text : I64 -> CceText
to_text = |x| CceText.show_int(x)

lam_0 : I64 -> CceText
lam_0 = |x| CceText.show_int(x)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(describe(42)))
	Ok({})
}
