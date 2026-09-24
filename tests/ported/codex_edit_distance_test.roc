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

import cdx.EditDistance
import cdx.Text

# EditDistanceTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

test_identical : Text
test_identical = Text.concat("same=", Text.show_int(EditDistance.edit_distance("hello", "hello")))

test_empty : Text
test_empty = Text.concat(Text.concat(Text.concat("empty=", Text.show_int(EditDistance.edit_distance("", "abc"))), ","), Text.show_int(EditDistance.edit_distance("abc", "")))

test_basic : Text
test_basic = ({
	d1 = EditDistance.edit_distance("kitten", "sitting")
	d2 = EditDistance.edit_distance("saturday", "sunday")
	Text.concat(Text.concat(Text.concat("kitten-sitting=", Text.show_int(d1)), " saturday-sunday="), Text.show_int(d2))
})

test_single : Text
test_single = ({
	d1 = EditDistance.edit_distance("cat", "hat")
	d2 = EditDistance.edit_distance("cat", "cats")
	d3 = EditDistance.edit_distance("cat", "at")
	Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("sub=", Text.show_int(d1)), " ins="), Text.show_int(d2)), " del="), Text.show_int(d3))
})

test_similarity : Text
test_similarity = ({
	s1 = EditDistance.edit_similarity("hello", "hello")
	s2 = EditDistance.edit_similarity("hello", "hallo")
	Text.concat(Text.concat(Text.concat("sim-same=", Text.show_int(s1)), " sim-close="), Text.show_int(s2))
})

test_best_match : Text
test_best_match = ({
	candidates = ["help", "shell", "hello", "world", "helm"]
	best = EditDistance.edit_best_match("helo", candidates)
	Text.concat("best=", EditDistance.format_edit_match(best))
})

test_within : Text
test_within = ({
	candidates = ["help", "shell", "hello", "world", "helm"]
	matches = EditDistance.edit_within("helo", candidates, 2)
	Text.concat("within-2=", Text.show_int(U64.to_i64_wrap(List.len(matches))))
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(test_identical))
	line!(Text.printed(test_empty))
	line!(Text.printed(test_basic))
	line!(Text.printed(test_single))
	line!(Text.printed(test_similarity))
	line!(Text.printed(test_best_match))
	line!(Text.printed(test_within))
	Ok({})
}
