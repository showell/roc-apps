# typeclass-instance-nested
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-instance-nested.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     2
#     2
#     1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeclassInstanceNested -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
MeasureListDict(a) : { measure_list_impl : (List(a) -> CceText) }

measure_from_dict : List(I64) -> CceText
measure_from_dict = |xs| ({
	d = measureList_dict_Integer
	(d.measure_list_impl)(xs)
})

generic_length : List(a) -> CceText
generic_length = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

measureList_dict_Integer : MeasureListDict(I64)
measureList_dict_Integer = { measure_list_impl: lam_0 }

measure_list_Integer : List(I64) -> CceText
measure_list_Integer = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

measure_list : List(I64) -> CceText
measure_list = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

lam_0 : List(I64) -> CceText
lam_0 = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(measure_list([1, 2])))
	line!(CceText.printed(measure_from_dict([3, 4])))
	line!(CceText.printed(generic_length([True])))
	Ok({})
}
