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

test_identical : List(U8)
test_identical = List.concat([19, 15, 26, 13, 77], Text.show_int(EditDistance.edit_distance([20, 13, 23, 23, 16], [20, 13, 23, 23, 16])))

test_empty : List(U8)
test_empty = List.concat(List.concat(List.concat([13, 26, 31, 14, 30, 77], Text.show_int(EditDistance.edit_distance([], [15, 32, 24]))), [66]), Text.show_int(EditDistance.edit_distance([15, 32, 24], [])))

test_basic : List(U8)
test_basic = ({
	d1 = EditDistance.edit_distance([34, 17, 14, 14, 13, 18], [19, 17, 14, 14, 17, 18, 29])
	d2 = EditDistance.edit_distance([19, 15, 14, 25, 21, 22, 15, 30], [19, 25, 18, 22, 15, 30])
	List.concat(List.concat(List.concat([34, 17, 14, 14, 13, 18, 73, 19, 17, 14, 14, 17, 18, 29, 77], Text.show_int(d1)), [2, 19, 15, 14, 25, 21, 22, 15, 30, 73, 19, 25, 18, 22, 15, 30, 77]), Text.show_int(d2))
})

test_single : List(U8)
test_single = ({
	d1 = EditDistance.edit_distance([24, 15, 14], [20, 15, 14])
	d2 = EditDistance.edit_distance([24, 15, 14], [24, 15, 14, 19])
	d3 = EditDistance.edit_distance([24, 15, 14], [15, 14])
	List.concat(List.concat(List.concat(List.concat(List.concat([19, 25, 32, 77], Text.show_int(d1)), [2, 17, 18, 19, 77]), Text.show_int(d2)), [2, 22, 13, 23, 77]), Text.show_int(d3))
})

test_similarity : List(U8)
test_similarity = ({
	s1 = EditDistance.edit_similarity([20, 13, 23, 23, 16], [20, 13, 23, 23, 16])
	s2 = EditDistance.edit_similarity([20, 13, 23, 23, 16], [20, 15, 23, 23, 16])
	List.concat(List.concat(List.concat([19, 17, 26, 73, 19, 15, 26, 13, 77], Text.show_int(s1)), [2, 19, 17, 26, 73, 24, 23, 16, 19, 13, 77]), Text.show_int(s2))
})

test_best_match : List(U8)
test_best_match = ({
	candidates = [[20, 13, 23, 31], [19, 20, 13, 23, 23], [20, 13, 23, 23, 16], [27, 16, 21, 23, 22], [20, 13, 23, 26]]
	best = EditDistance.edit_best_match([20, 13, 23, 16], candidates)
	List.concat([32, 13, 19, 14, 77], EditDistance.format_edit_match(best))
})

test_within : List(U8)
test_within = ({
	candidates = [[20, 13, 23, 31], [19, 20, 13, 23, 23], [20, 13, 23, 23, 16], [27, 16, 21, 23, 22], [20, 13, 23, 26]]
	matches = EditDistance.edit_within([20, 13, 23, 16], candidates, 2)
	List.concat([27, 17, 14, 20, 17, 18, 73, 5, 77], Text.show_int(U64.to_i64_wrap(List.len(matches))))
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
