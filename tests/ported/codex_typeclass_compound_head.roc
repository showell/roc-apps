# typeclass-compound-head
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-compound-head.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     plain-integer  : int 7
#     compound-int   : ints 3
#     compound-text  : texts 2

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeClassCompoundHead -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
ShowableDict(a) : { to_text_impl : (a -> CceText) }

showable_dict_Integer : ShowableDict(I64)
showable_dict_Integer = { to_text_impl: lam_0 }

to_text_Integer : I64 -> CceText
to_text_Integer = |n| CceText.concat("int ", CceText.show_int(n))

showable_dict_List_of_Integer_end : ShowableDict(List(I64))
showable_dict_List_of_Integer_end = { to_text_impl: lam_1 }

to_text_List_of_Integer_end : List(I64) -> CceText
to_text_List_of_Integer_end = |xs| CceText.concat("ints ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

showable_dict_List_of_Text_end : ShowableDict(List(CceText))
showable_dict_List_of_Text_end = { to_text_impl: lam_2 }

to_text_List_of_Text_end : List(CceText) -> CceText
to_text_List_of_Text_end = |xs| CceText.concat("texts ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

lam_0 : I64 -> CceText
lam_0 = |n| CceText.concat("int ", CceText.show_int(n))

lam_1 : List(I64) -> CceText
lam_1 = |xs| CceText.concat("ints ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

lam_2 : List(CceText) -> CceText
lam_2 = |xs| CceText.concat("texts ", CceText.show_int(U64.to_i64_wrap(List.len(xs))))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("plain-integer  : ", to_text_Integer(7))))
	line!(CceText.printed(CceText.concat("compound-int   : ", to_text_List_of_Integer_end([1, 2, 3]))))
	line!(CceText.printed(CceText.concat("compound-text  : ", to_text_List_of_Text_end(["a", "b"]))))
	Ok({})
}
