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

s : I64, I64, Text -> Text
s = |a, got, want| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("  sin ", Text.show_int(a)), " = "), Text.show_int(got)), "  true "), want)

c : I64, I64, Text -> Text
c = |a, got, want| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("  cos ", Text.show_int(a)), " = "), Text.show_int(got)), "  true "), want)

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
	line!(Text.printed("Below 1735 the rotation always converged, so these are controls"))
	line!(Text.printed("and the quadrant fold must not move any of them:"))
	line!(Text.printed(s(0, Cordic.cordic_sin(0), "0")))
	line!(Text.printed(s(500, Cordic.cordic_sin(500), "479")))
	line!(Text.printed(s(1000, Cordic.cordic_sin(1000), "841")))
	line!(Text.printed(s(1500, Cordic.cordic_sin(1500), "997")))
	line!(Text.printed(c(0, Cordic.cordic_cos(0), "1000, and 997 is the gain constant, not the fold")))
	line!(Text.printed(""))
	line!(Text.printed("Second quadrant, where the saturation began:"))
	line!(Text.printed(s(2000, Cordic.cordic_sin(2000), "909")))
	line!(Text.printed(s(2500, Cordic.cordic_sin(2500), "599")))
	line!(Text.printed(s(3141, Cordic.cordic_sin(3141), "0")))
	line!(Text.printed(c(1571, Cordic.cordic_cos(1571), "0")))
	line!(Text.printed(c(2000, Cordic.cordic_cos(2000), "-416")))
	line!(Text.printed(c(3141, Cordic.cordic_cos(3141), "-1000")))
	line!(Text.printed(""))
	line!(Text.printed("Third and fourth quadrants, where sin must go negative and the"))
	line!(Text.printed("saturated version answered a positive 986 throughout:"))
	line!(Text.printed(s(3500, Cordic.cordic_sin(3500), "-351")))
	line!(Text.printed(s(4712, Cordic.cordic_sin(4712), "-1000")))
	line!(Text.printed(s(5500, Cordic.cordic_sin(5500), "-706")))
	line!(Text.printed(c(4712, Cordic.cordic_cos(4712), "0")))
	line!(Text.printed(c(6000, Cordic.cordic_cos(6000), "960")))
	line!(Text.printed(""))
	line!(Text.printed("Angles outside one turn, which cordic-normalize folds first:"))
	line!(Text.printed(s(7854, Cordic.cordic_sin(7854), "1000, being 6283 + 1571")))
	line!(Text.printed(s((0 - 1571), Cordic.cordic_sin((0 - 1571)), "-1000")))
	line!(Text.printed(""))
	line!(Text.printed("Counted rather than eyeballed, over the whole turn:"))
	line!(Text.printed(Text.concat(Text.concat("  sin^2 + cos^2 within 1.5 pct of 1, angles 0..6000: ", Text.show_int(pythag(0, 12, 0))), " of 13")))
	line!(Text.printed(Text.concat(Text.concat("  sin non-negative over 0..3000:                     ", Text.show_int(upper(0, 10, 0))), " of 11")))
	line!(Text.printed(Text.concat(Text.concat("  sin non-positive over pi..pi+3000:                 ", Text.show_int(lower(0, 10, 0))), " of 11")))
	Ok({})
}
