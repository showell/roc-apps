# typeclass-instance-types
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-instance-types.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     11
#     True
#     12
#     False
#     2
#     True
#     free

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeclassInstanceTypes -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
FormatValueDict(a) : { format_value_impl : (a -> CceText) }

describe_value : FormatValueDict(a), a -> CceText
describe_value = |formatValue_dict, x| (formatValue_dict.format_value_impl)(x)

formatValue_dict_Integer : FormatValueDict(I64)
formatValue_dict_Integer = { format_value_impl: lam_0 }

format_value_Integer : I64 -> CceText
format_value_Integer = |x| CceText.show_int(x)

formatValue_dict_Boolean : FormatValueDict(Bool)
formatValue_dict_Boolean = { format_value_impl: lam_1 }

format_value_Boolean : Bool -> CceText
format_value_Boolean = |x| (if x { "True" } else { "False" })

formatValue_dict_List_of_Integer_end : FormatValueDict(List(I64))
formatValue_dict_List_of_Integer_end = { format_value_impl: lam_2 }

format_value_List_of_Integer_end : List(I64) -> CceText
format_value_List_of_Integer_end = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

keep_value_Integer : I64, a -> a
keep_value_Integer = |_x, y| y

keep_value : I64, a -> a
keep_value = |_x, y| y

lam_0 : I64 -> CceText
lam_0 = |x| CceText.show_int(x)

lam_1 : Bool -> CceText
lam_1 = |x| (if x { "True" } else { "False" })

lam_2 : List(I64) -> CceText
lam_2 = |xs| CceText.show_int(U64.to_i64_wrap(List.len(xs)))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(format_value_Integer(11)))
	line!(CceText.printed(format_value_Boolean(True)))
	line!(CceText.printed(describe_value(formatValue_dict_Integer, 12)))
	line!(CceText.printed(describe_value(formatValue_dict_Boolean, False)))
	line!(CceText.printed(format_value_List_of_Integer_end([1, 2])))
	line!(CceText.printed((if keep_value(9, True) { "True" } else { "False" })))
	line!(CceText.printed(keep_value(9, "free")))
	Ok({})
}
