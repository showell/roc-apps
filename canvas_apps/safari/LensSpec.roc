## These are Lens's checks: the focal length at rest, for a lean, for the
## rider's attention, and the two together.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Lens
import Screen

base_got : List(F64)
base_got = [
	Screen.width,
	Lens.fov_deg,
	Lens.focal,
]

base_want : List(F64)
base_want = [960.0, 70.0, 685.5110432362151]

lean_in : List(F64)
lean_in = [0.0, 0.25, 0.5, 0.75, 1.0]

lean_want : List(F64)
lean_want = [
	685.5110432362151,
	657.6621571047439,
	574.1154987103301,
	434.8710680529739,
	239.92886513267527,
]

gaze_in : List(F64)
gaze_in = [0.0, 0.5, 1.0, 1.5]

gaze_want : List(F64)
gaze_want = [685.5110432362151, 551.8363898051531, 418.16173637409116, 284.4870829430293]

cam_in : List({ lean_frac : F64, attention : F64 })
cam_in = [
	{ lean_frac: 0.0, attention: 0.0 },
	{ lean_frac: 1.0, attention: 0.0 },
	{ lean_frac: 0.0, attention: 1.0 },
	{ lean_frac: 0.5, attention: 0.3 },
	{ lean_frac: 0.9, attention: 1.4 },
	{ lean_frac: 0.6, attention: 0.5 },
]

cam_want : List(F64)
cam_want = [
	685.5110432362151,
	239.92886513267527,
	418.16173637409116,
	574.1154987103301,
	311.2220136292417,
	525.1014591189407,
]

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
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
