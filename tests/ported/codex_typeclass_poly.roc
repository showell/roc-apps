# typeclass-poly
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-poly.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     5
#     True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeClassPoly -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
EquatableDict(a) : { equals_impl : (a, a -> Bool) }
SortableDict(a) : { super_Equatable : EquatableDict(a), sort_key_impl : (a -> I64) }

test_convert : CceText
test_convert = CceText.show_int(convert(1, 42))

test_sort_key : CceText
test_sort_key = CceText.show_int(sort_key(5))

test_super : CceText
test_super = ({
	d = sortable_dict_Integer
	eq = d.super_Equatable
	(if (eq.equals_impl)(7, 7) { "True" } else { "False" })
})

equatable_dict_Integer : EquatableDict(I64)
equatable_dict_Integer = { equals_impl: lam_0 }

equals_Integer : I64, I64 -> Bool
equals_Integer = |x, y| (x == y)

equals : I64, I64 -> Bool
equals = |x, y| (x == y)

convert_Integer : I64, a -> a
convert_Integer = |_x, y| y

convert : I64, a -> a
convert = |_x, y| y

sortable_dict_Integer : SortableDict(I64)
sortable_dict_Integer = { super_Equatable: equatable_dict_Integer, sort_key_impl: lam_2 }

sort_key_Integer : I64 -> I64
sort_key_Integer = |x| x

sort_key : I64 -> I64
sort_key = |x| x

lam_0 : I64, I64 -> Bool
lam_0 = |x, y| (x == y)

lam_2 : I64 -> I64
lam_2 = |x| x

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_convert))
	line!(CceText.printed(test_sort_key))
	line!(CceText.printed(test_super))
	Ok({})
}
