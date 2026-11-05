## These are Lens's checks: the focal length at rest, for a lean, for the
## rider's attention, and the two together, and what attention itself does.
app [main!] {
	lib: "../lib/main.roc",
}

import Attention
import Fraction
import Grade
import Lens
import Screen
import lib.Trig

base_got : List(F64)
base_got = [
	Screen.width,
	Lens.field_of_view.to_radians() / Trig.deg,
	Lens.focal,
]

base_want : List(F64)
base_want = [960.0, 70.0, 685.5110432362151]

lean_in : List(Fraction)
lean_in = [0.0, 0.25, 0.5, 0.75, 1.0].map(Fraction.of)

lean_want : List(F64)
lean_want = [
	685.5110432362151,
	657.6621571047439,
	574.1154987103301,
	434.8710680529739,
	239.92886513267527,
]

gaze_in : List(Attention)
gaze_in = [0.0, 0.5, 1.0, 1.5].map(Attention.of)

gaze_want : List(F64)
gaze_want = [685.5110432362151, 551.8363898051531, 418.16173637409116, 284.4870829430293]

cam_in : List({ lean_frac : Fraction, attention : Attention })
cam_in = [
	(0.0, 0.0),
	(1.0, 0.0),
	(0.0, 1.0),
	(0.5, 0.3),
	(0.9, 1.4),
	(0.6, 0.5),
].map(|(lean, look)| { lean_frac: Fraction.of(lean), attention: Attention.of(look) })

cam_want : List(F64)
cam_want = [
	685.5110432362151,
	239.92886513267527,
	418.16173637409116,
	574.1154987103301,
	311.2220136292417,
	525.1014591189407,
]

attention_got : List(F64)
attention_got = [
	Attention.none.to_f64(),
	Attention.of(1.8).to_f64(),
	Attention.from_fraction(Fraction.of(0.5)).to_f64(),
	Attention.of(1.8).portion(Fraction.of(0.5)).to_f64(),
	Attention.of(0.3).max(Attention.of(1.4)).to_f64(),
	Attention.of(1.4).max(Attention.of(0.3)).to_f64(),
]

attention_want : List(F64)
attention_want = [0.0, 1.8, 0.5, 0.9, 1.4, 1.4]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.rel({
			name: "l-base ",
			got: base_got,
			want: base_want,
			tol: F64.from_bits(4472406533629990549),
		}),
		Grade.rel({
			name: "l-lean ",
			got: lean_in.map(Lens.focal_for_lean),
			want: lean_want,
			tol: F64.from_bits(4472406533629990549),
		}),
		Grade.rel({
			name: "l-gaze ",
			got: gaze_in.map(Lens.focal_for_gaze),
			want: gaze_want,
			tol: F64.from_bits(4472406533629990549),
		}),
		Grade.rel({
			name: "l-cam  ",
			got: cam_in.map(Lens.cam_focal),
			want: cam_want,
			tol: F64.from_bits(4472406533629990549),
		}),
		Grade.reals({
			name: "l-attn ",
			got: attention_got,
			want: attention_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
