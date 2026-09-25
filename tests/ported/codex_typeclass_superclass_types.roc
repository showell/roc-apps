# typeclass-superclass-types
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/typeclass-superclass-types.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True
#     False
#     True
#     False

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TypeclassSuperclassTypes -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
SameValueDict(a) : { same_value_impl : (a, a -> Bool) }
RankedValueDict(a) : { super_SameValue : SameValueDict, rank_value_impl : (a -> I64) }

integer_super : I64, I64 -> Bool
integer_super = |x, y| ({
	d = rankedValue_dict_Integer
	s = d.super_SameValue
	(s.same_value_impl)(x, y)
})

boolean_super : Bool, Bool -> Bool
boolean_super = |x, y| ({
	d = rankedValue_dict_Boolean
	s = d.super_SameValue
	(s.same_value_impl)(x, y)
})

sameValue_dict_Integer : SameValueDict(I64)
sameValue_dict_Integer = { same_value_impl: lam_0 }

same_value_Integer : I64, I64 -> Bool
same_value_Integer = |x, y| (x == y)

sameValue_dict_Boolean : SameValueDict(Bool)
sameValue_dict_Boolean = { same_value_impl: lam_1 }

same_value_Boolean : Bool, Bool -> Bool
same_value_Boolean = |x, y| (x == y)

rankedValue_dict_Integer : RankedValueDict(I64)
rankedValue_dict_Integer = { super_SameValue: sameValue_dict_Integer, rank_value_impl: lam_2 }

rank_value_Integer : I64 -> I64
rank_value_Integer = |x| x

rankedValue_dict_Boolean : RankedValueDict(Bool)
rankedValue_dict_Boolean = { super_SameValue: sameValue_dict_Boolean, rank_value_impl: lam_3 }

rank_value_Boolean : Bool -> I64
rank_value_Boolean = |x| (if x { 1 } else { 0 })

lam_0 : I64, I64 -> Bool
lam_0 = |x, y| (x == y)

lam_1 : Bool, Bool -> Bool
lam_1 = |x, y| (x == y)

lam_2 : I64 -> I64
lam_2 = |x| x

lam_3 : Bool -> I64
lam_3 = |x| (if x { 1 } else { 0 })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if integer_super(7, 7) { "True" } else { "False" })))
	line!(CceText.printed((if integer_super(7, 8) { "True" } else { "False" })))
	line!(CceText.printed((if boolean_super(True, True) { "True" } else { "False" })))
	line!(CceText.printed((if boolean_super(True, False) { "True" } else { "False" })))
	Ok({})
}
