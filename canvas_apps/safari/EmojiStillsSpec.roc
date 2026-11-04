## These are EmojiStills's checks: for each animal's code point, and for two
## that are none, how many polygons, points and gradients its still has, and
## its first colour; then the bull's gradient.
app [main!] {
	lib: "../lib/main.roc",
}

import EmojiStills
import Grade
import Stills

# A still's polygons, its points and its gradients, counted, and its first
# polygon's colour; all four 0 for no still.
facts : List(Stills.StillPoly) -> List(I64)
facts = |polys|
	match polys {
		[] => [0, 0, 0, 0]
		[first, ..] => [
			polys.len().to_i64_wrap(),
			polys.fold(0, |points, poly| points + poly.pts.len().to_i64_wrap()),
			polys.fold(0, |gradients, poly| gradients + poly.grad.len().to_i64_wrap()),
			first.color,
		]
	}

# The duck, elephant, giraffe, zebra, rhino, bull, cow and pig, then the
# squid, which has no still, and 0.
codepoints : List(I64)
codepoints = [129414, 128024, 129426, 129427, 129423, 128002, 128004, 128022, 129425, 0]

table_got : List(I64)
table_got = codepoints.join_map(|codepoint| facts(EmojiStills.emoji_polys_for(codepoint)))

table_want : List(I64)
table_want = [6, 189, 0, 4493595, 6, 257, 0, 6513507, 24, 850, 0, 16745005, 22, 713, 0, 10197915, 6, 237, 0, 13882323, 43, 2309, 40, 4989733, 16, 469, 0, 10197915, 6, 243, 0, 16735833, 0, 0, 0, 0, 0, 0, 0, 0]

bull_grad : Stills.StillGrad
bull_grad =
	match EmojiStills.bull_polys {
		[{ grad: [gradient, ..], .. }, ..] => gradient
		_ => crash "EmojiStillsSpec: the bull's first polygon has a gradient"
	}

bg_int_got : List(I64)
bg_int_got = [bull_grad.kind]

bg_int_want : List(I64)
bg_int_want = [1]

bg_real_got : List(F64)
bg_real_got = [bull_grad.off0, bull_grad.off1]

bg_real_want : List(F64)
bg_real_want = [0.0, 1.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "es-table",
			got: table_got,
			want: table_want,
		}),
		Grade.ints({
			name: "es-bgi  ",
			got: bg_int_got,
			want: bg_int_want,
		}),
		Grade.reals({
			name: "es-bgr  ",
			got: bg_real_got,
			want: bg_real_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
