## These are Easing's checks: clamping below, inside and above the range,
## lerp at both ends and between, and smoothstep's shape.
app [main!] {
	lib: "../lib/main.roc",
}

import Easing
import Grade

clamp_got : List(F64)
clamp_got = [
	-0.5,
	0.0,
	0.25,
	1.0,
	1.5,
].map(Easing.clamp01)

clamp_want : List(F64)
clamp_want = [0.0, 0.0, 0.25, 1.0, 1.0]

lerp_got : List(F64)
lerp_got = [0.25, 0.0, 1.0, 1.5].map(
	|fraction| Easing.lerp({
		from: 2.0,
		to: 6.0,
		fraction,
	}),
)

lerp_want : List(F64)
lerp_want = [3.0, 2.0, 6.0, 8.0]

smooth_got : List(F64)
smooth_got = [0.0, 0.25, 0.5, 0.75, 1.0].map(Easing.smoothstep)

smooth_want : List(F64)
smooth_want = [0.0, 0.15625, 0.5, 0.84375, 1.0]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "ea-clamp ",
			got: clamp_got,
			want: clamp_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ea-lerp  ",
			got: lerp_got,
			want: lerp_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ea-smooth",
			got: smooth_got,
			want: smooth_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
