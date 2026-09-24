# edit-distance-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/edit-distance-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     same=0
#     empty=3,3
#     kitten-sitting=3 saturday-sunday=3
#     sub=1 ins=1 del=1
#     sim-same=1000 sim-close=800
#     best=help (d=1)
#     within-2=4

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.EditDistance

# EditDistanceTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_identical : CceText
test_identical = CceText.concat("same=", CceText.show_int(EditDistance.edit_distance("hello", "hello")))

test_empty : CceText
test_empty = CceText.concat(CceText.concat(CceText.concat("empty=", CceText.show_int(EditDistance.edit_distance("", "abc"))), ","), CceText.show_int(EditDistance.edit_distance("abc", "")))

test_basic : CceText
test_basic = ({
	d1 : I64
	d1 = EditDistance.edit_distance("kitten", "sitting")
	d2 : I64
	d2 = EditDistance.edit_distance("saturday", "sunday")
	CceText.concat(CceText.concat(CceText.concat("kitten-sitting=", CceText.show_int(d1)), " saturday-sunday="), CceText.show_int(d2))
})

test_single : CceText
test_single = ({
	d1 : I64
	d1 = EditDistance.edit_distance("cat", "hat")
	d2 : I64
	d2 = EditDistance.edit_distance("cat", "cats")
	d3 : I64
	d3 = EditDistance.edit_distance("cat", "at")
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("sub=", CceText.show_int(d1)), " ins="), CceText.show_int(d2)), " del="), CceText.show_int(d3))
})

test_similarity : CceText
test_similarity = ({
	s1 : I64
	s1 = EditDistance.edit_similarity("hello", "hello")
	s2 : I64
	s2 = EditDistance.edit_similarity("hello", "hallo")
	CceText.concat(CceText.concat(CceText.concat("sim-same=", CceText.show_int(s1)), " sim-close="), CceText.show_int(s2))
})

test_best_match : CceText
test_best_match = ({
	candidates : List(CceText)
	candidates = ["help", "shell", "hello", "world", "helm"]
	best = EditDistance.edit_best_match("helo", candidates)
	CceText.concat("best=", EditDistance.format_edit_match(best))
})

test_within : CceText
test_within = ({
	candidates : List(CceText)
	candidates = ["help", "shell", "hello", "world", "helm"]
	matches : List(CceText)
	matches = EditDistance.edit_within("helo", candidates, 2)
	CceText.concat("within-2=", CceText.show_int(U64.to_i64_wrap(List.len(matches))))
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(test_identical))
	line!(CceText.printed(test_empty))
	line!(CceText.printed(test_basic))
	line!(CceText.printed(test_single))
	line!(CceText.printed(test_similarity))
	line!(CceText.printed(test_best_match))
	line!(CceText.printed(test_within))
	Ok({})
}
