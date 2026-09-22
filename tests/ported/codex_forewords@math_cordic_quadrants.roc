# forewords@math-cordic-quadrants
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@math-cordic-quadrants.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Below 1735 the rotation always converged, so these are controls
#     and the quadrant fold must not move any of them:
#       sin 0 = 0  true 0
#       sin 500 = 480  true 479
#       sin 1000 = 841  true 841
#       sin 1500 = 997  true 997
#       cos 0 = 997  true 1000, and 997 is the gain constant, not the fold
#     
#     Second quadrant, where the saturation began:
#       sin 2000 = 908  true 909
#       sin 2500 = 598  true 599
#       sin 3141 = 0  true 0
#       cos 1571 = -2  true 0
#       cos 2000 = -415  true -416
#       cos 3141 = -997  true -1000
#     
#     Third and fourth quadrants, where sin must go negative and the
#     saturated version answered a positive 986 throughout:
#       sin 3500 = -351  true -351
#       sin 4712 = -997  true -1000
#       sin 5500 = -704  true -706
#       cos 4712 = 0  true 0
#       cos 6000 = 960  true 960
#     
#     Angles outside one turn, which cordic-normalize folds first:
#       sin 7854 = 997  true 1000, being 6283 + 1571
#       sin -1571 = -997  true -1000
#     
#     Counted rather than eyeballed, over the whole turn:
#       sin^2 + cos^2 within 1.5 pct of 1, angles 0..6000: 13 of 13
#       sin non-negative over 0..3000:                     11 of 11
#       sin non-positive over pi..pi+3000:                 11 of 11

app [main!] { cdx: "./codex/main.roc" }

import cdx.Cordic
import cdx.Text

# MathCordicQuadrants -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s : I64, I64, List(U8) -> List(U8)
s = |a, got, want| List.concat(List.concat(List.concat(List.concat(List.concat([2, 2, 19, 17, 18, 2], Text.show_int(a)), [2, 77, 2]), Text.show_int(got)), [2, 2, 14, 21, 25, 13, 2]), want)

c : I64, I64, List(U8) -> List(U8)
c = |a, got, want| List.concat(List.concat(List.concat(List.concat(List.concat([2, 2, 24, 16, 19, 2], Text.show_int(a)), [2, 77, 2]), Text.show_int(got)), [2, 2, 14, 21, 25, 13, 2]), want)

pythag : I64, I64, I64 -> I64
pythag = |i, n, acc| (if (i > n) { acc } else { ({
	a = (i * 500)
	sn = Cordic.cordic_sin(a)
	cs = Cordic.cordic_cos(a)
	m = ((sn * sn) + (cs * cs))
	pythag((i + 1), n, (if (m > 985000) { (if (m < 1015000) { (acc + 1) } else { acc }) } else { acc }))
}) })

upper : I64, I64, I64 -> I64
upper = |i, n, acc| (if (i > n) { acc } else { upper((i + 1), n, (if (Cordic.cordic_sin((i * 300)) >= 0) { (acc + 1) } else { acc })) })

lower : I64, I64, I64 -> I64
lower = |i, n, acc| (if (i > n) { acc } else { lower((i + 1), n, (if (Cordic.cordic_sin((3142 + (i * 300))) <= 0) { (acc + 1) } else { acc })) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed([58, 13, 23, 16, 27, 2, 4, 10, 6, 8, 2, 14, 20, 13, 2, 21, 16, 14, 15, 14, 17, 16, 18, 2, 15, 23, 27, 15, 30, 19, 2, 24, 16, 18, 33, 13, 21, 29, 13, 22, 66, 2, 19, 16, 2, 14, 20, 13, 19, 13, 2, 15, 21, 13, 2, 24, 16, 18, 14, 21, 16, 23, 19]))
	line!(Text.printed([15, 18, 22, 2, 14, 20, 13, 2, 37, 25, 15, 22, 21, 15, 18, 14, 2, 28, 16, 23, 22, 2, 26, 25, 19, 14, 2, 18, 16, 14, 2, 26, 16, 33, 13, 2, 15, 18, 30, 2, 16, 28, 2, 14, 20, 13, 26, 69]))
	line!(Text.printed(s(0, Cordic.cordic_sin(0), [3])))
	line!(Text.printed(s(500, Cordic.cordic_sin(500), [7, 10, 12])))
	line!(Text.printed(s(1000, Cordic.cordic_sin(1000), [11, 7, 4])))
	line!(Text.printed(s(1500, Cordic.cordic_sin(1500), [12, 12, 10])))
	line!(Text.printed(c(0, Cordic.cordic_cos(0), [4, 3, 3, 3, 66, 2, 15, 18, 22, 2, 12, 12, 10, 2, 17, 19, 2, 14, 20, 13, 2, 29, 15, 17, 18, 2, 24, 16, 18, 19, 14, 15, 18, 14, 66, 2, 18, 16, 14, 2, 14, 20, 13, 2, 28, 16, 23, 22])))
	line!(Text.printed([]))
	line!(Text.printed([45, 13, 24, 16, 18, 22, 2, 37, 25, 15, 22, 21, 15, 18, 14, 66, 2, 27, 20, 13, 21, 13, 2, 14, 20, 13, 2, 19, 15, 14, 25, 21, 15, 14, 17, 16, 18, 2, 32, 13, 29, 15, 18, 69]))
	line!(Text.printed(s(2000, Cordic.cordic_sin(2000), [12, 3, 12])))
	line!(Text.printed(s(2500, Cordic.cordic_sin(2500), [8, 12, 12])))
	line!(Text.printed(s(3141, Cordic.cordic_sin(3141), [3])))
	line!(Text.printed(c(1571, Cordic.cordic_cos(1571), [3])))
	line!(Text.printed(c(2000, Cordic.cordic_cos(2000), [73, 7, 4, 9])))
	line!(Text.printed(c(3141, Cordic.cordic_cos(3141), [73, 4, 3, 3, 3])))
	line!(Text.printed([]))
	line!(Text.printed([40, 20, 17, 21, 22, 2, 15, 18, 22, 2, 28, 16, 25, 21, 14, 20, 2, 37, 25, 15, 22, 21, 15, 18, 14, 19, 66, 2, 27, 20, 13, 21, 13, 2, 19, 17, 18, 2, 26, 25, 19, 14, 2, 29, 16, 2, 18, 13, 29, 15, 14, 17, 33, 13, 2, 15, 18, 22, 2, 14, 20, 13]))
	line!(Text.printed([19, 15, 14, 25, 21, 15, 14, 13, 22, 2, 33, 13, 21, 19, 17, 16, 18, 2, 15, 18, 19, 27, 13, 21, 13, 22, 2, 15, 2, 31, 16, 19, 17, 14, 17, 33, 13, 2, 12, 11, 9, 2, 14, 20, 21, 16, 25, 29, 20, 16, 25, 14, 69]))
	line!(Text.printed(s(3500, Cordic.cordic_sin(3500), [73, 6, 8, 4])))
	line!(Text.printed(s(4712, Cordic.cordic_sin(4712), [73, 4, 3, 3, 3])))
	line!(Text.printed(s(5500, Cordic.cordic_sin(5500), [73, 10, 3, 9])))
	line!(Text.printed(c(4712, Cordic.cordic_cos(4712), [3])))
	line!(Text.printed(c(6000, Cordic.cordic_cos(6000), [12, 9, 3])))
	line!(Text.printed([]))
	line!(Text.printed([41, 18, 29, 23, 13, 19, 2, 16, 25, 14, 19, 17, 22, 13, 2, 16, 18, 13, 2, 14, 25, 21, 18, 66, 2, 27, 20, 17, 24, 20, 2, 24, 16, 21, 22, 17, 24, 73, 18, 16, 21, 26, 15, 23, 17, 38, 13, 2, 28, 16, 23, 22, 19, 2, 28, 17, 21, 19, 14, 69]))
	line!(Text.printed(s(7854, Cordic.cordic_sin(7854), [4, 3, 3, 3, 66, 2, 32, 13, 17, 18, 29, 2, 9, 5, 11, 6, 2, 76, 2, 4, 8, 10, 4])))
	line!(Text.printed(s((0 - 1571), Cordic.cordic_sin((0 - 1571)), [73, 4, 3, 3, 3])))
	line!(Text.printed([]))
	line!(Text.printed([50, 16, 25, 18, 14, 13, 22, 2, 21, 15, 14, 20, 13, 21, 2, 14, 20, 15, 18, 2, 13, 30, 13, 32, 15, 23, 23, 13, 22, 66, 2, 16, 33, 13, 21, 2, 14, 20, 13, 2, 27, 20, 16, 23, 13, 2, 14, 25, 21, 18, 69]))
	line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 18, 94, 5, 2, 76, 2, 24, 16, 19, 94, 5, 2, 27, 17, 14, 20, 17, 18, 2, 4, 65, 8, 2, 31, 24, 14, 2, 16, 28, 2, 4, 66, 2, 15, 18, 29, 23, 13, 19, 2, 3, 65, 65, 9, 3, 3, 3, 69, 2], Text.show_int(pythag(0, 12, 0))), [2, 16, 28, 2, 4, 6])))
	line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 18, 2, 18, 16, 18, 73, 18, 13, 29, 15, 14, 17, 33, 13, 2, 16, 33, 13, 21, 2, 3, 65, 65, 6, 3, 3, 3, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(upper(0, 10, 0))), [2, 16, 28, 2, 4, 4])))
	line!(Text.printed(List.concat(List.concat([2, 2, 19, 17, 18, 2, 18, 16, 18, 73, 31, 16, 19, 17, 14, 17, 33, 13, 2, 16, 33, 13, 21, 2, 31, 17, 65, 65, 31, 17, 76, 6, 3, 3, 3, 69, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2], Text.show_int(lower(0, 10, 0))), [2, 16, 28, 2, 4, 4])))
	Ok({})
}
