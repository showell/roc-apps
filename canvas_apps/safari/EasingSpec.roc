## These are the checks of Easing and of the fractions it takes and gives:
## which ratios are fractions, clamping below, inside and above the range, what
## a fraction can do and how fractions compare, lerp at both ends and between,
## and smoothstep's shape.
app [main!] {
	lib: "../lib/main.roc",
}

import Easing
import Fraction
import Grade

not_a_number : F64
not_a_number = F64.from_bits(9221120237041090560)

infinity : F64
infinity = F64.from_bits(9218868437227405312)

negative_zero : F64
negative_zero = F64.from_bits(9223372036854775808)

is_fraction : F64 -> Bool
is_fraction = |ratio|
	match Fraction.from_ratio(ratio) {
		Ok(_) => True
		Err(OutOfRange) => False
	}

ratios : List((F64, Bool))
ratios = [
	(0.0, True),
	(negative_zero, True),
	(0.5, True),
	(1.0, True),
	(-0.000001, False),
	(1.000001, False),
	(not_a_number, False),
	(infinity, False),
]

clamp_got : List(F64)
clamp_got = [
	-0.5,
	-0.000001,
	0.0,
	0.25,
	1.0,
	1.000001,
	1.5,
].map(|ratio| Fraction.clamp(ratio).to_f64())

clamp_want : List(F64)
clamp_want = [0.0, 0.0, 0.0, 0.25, 1.0, 1.0, 1.0]

## A sign the sums downstream of a clamp can see, so it stays.
sign_got : List(Bool)
sign_got = [Fraction.clamp(negative_zero).to_f64().to_bits() == negative_zero.to_bits()]

sign_want : List(Bool)
sign_want = [True]

fraction_got : List(F64)
fraction_got = [
	Fraction.zero.to_f64(),
	Fraction.whole.to_f64(),
	Fraction.of(0.5).times(Fraction.of(0.25)).to_f64(),
	Fraction.of(0.25).complement().to_f64(),
	Fraction.zero.complement().to_f64(),
	Fraction.whole.complement().to_f64(),
	Fraction.of(0.25).max(Fraction.of(0.5)).to_f64(),
	Fraction.of(0.5).max(Fraction.of(0.25)).to_f64(),
]

fraction_want : List(F64)
fraction_want = [0.0, 1.0, 0.125, 0.75, 1.0, 0.0, 0.5, 0.5]

lesser : Fraction
lesser = Fraction.of(0.25)

greater : Fraction
greater = Fraction.of(0.5)

order_got : List(Bool)
order_got = [
	lesser < greater,
	greater < greater,
	greater < lesser,
	lesser <= greater,
	greater <= greater,
	greater <= lesser,
	lesser >= greater,
	greater >= greater,
	greater >= lesser,
	greater == greater,
	lesser == greater,
]

order_want : List(Bool)
order_want = [
	True,
	False,
	False,
	True,
	True,
	False,
	False,
	True,
	True,
	True,
	False,
]

lerp_got : List(F64)
lerp_got = [0.25, 0.0, 1.0, 0.75].map(
	|ratio| Easing.lerp({
		from: 2.0,
		to: 6.0,
		fraction: Fraction.of(ratio),
	}),
)

lerp_want : List(F64)
lerp_want = [3.0, 2.0, 6.0, 5.0]

smooth_got : List(F64)
smooth_got = [0.0, 0.25, 0.5, 0.75, 1.0].map(
	|ratio| Easing.smoothstep(Fraction.of(ratio)).to_f64(),
)

smooth_want : List(F64)
smooth_want = [0.0, 0.15625, 0.5, 0.84375, 1.0]

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "fr-ratio ",
			got: ratios.map(|(ratio, _)| is_fraction(ratio)),
			want: ratios.map(|(_, answer)| answer),
		}),
		Grade.reals({
			name: "fr-clamp ",
			got: clamp_got,
			want: clamp_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "fr-sign  ",
			got: sign_got,
			want: sign_want,
		}),
		Grade.reals({
			name: "fr-sums  ",
			got: fraction_got,
			want: fraction_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "fr-order ",
			got: order_got,
			want: order_want,
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
