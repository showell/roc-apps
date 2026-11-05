## These are Beats' checks: how beats add, scale, divide and share, how they compare,
## and how a speed turns them into metres and back, at a beat a step.
app [main!] {
	lib: "../lib/main.roc",
}

import Beats
import Distance
import Fraction
import Grade
import Speed

sums_got : List(F64)
sums_got = [
	Beats.zero.to_f64(),
	Beats.of(1.5).plus(Beats.of(2.25)).to_f64(),
	Beats.of(1.5).minus(Beats.of(2.25)).to_f64(),
	Beats.of(38.0).times(0.5).to_f64(),
	Beats.of(38.0).portion(Fraction.of(0.25)).to_f64(),
]

sums_want : List(F64)
sums_want = [0.0, 3.75, -0.75, 19.0, 9.5]

## A ratio can be under 1, 1 itself, or past it.
ratios_got : List(F64)
ratios_got = [
	Beats.of(2.0).ratio_to(Beats.of(8.0)),
	Beats.of(8.0).ratio_to(Beats.of(8.0)),
	Beats.of(12.0).ratio_to(Beats.of(8.0)),
]

ratios_want : List(F64)
ratios_want = [0.25, 1.0, 1.5]

order_got : List(Bool)
order_got = [
	Beats.of(2.0) < Beats.of(2.5),
	Beats.of(2.5) < Beats.of(2.5),
	Beats.of(2.5) <= Beats.of(2.5),
	Beats.of(3.0) <= Beats.of(2.5),
	Beats.of(2.5) == Beats.of(2.5),
	Beats.of(2.5) == Beats.of(3.0),
]

order_want : List(Bool)
order_want = [
	True,
	False,
	True,
	False,
	True,
	False,
]

speed_got : List(F64)
speed_got = [
	Speed.metres_a_step(2.0).distance_in(Beats.of(38.0)).to_metres(),
	Speed.at_rest.distance_in(Beats.of(38.0)).to_metres(),
	Speed.metres_a_step(2.0).beats_to_cover(Distance.metres(5.0)).to_f64(),
	Speed.metres_a_step(0.5).beats_to_cover(Distance.metres(5.0)).to_f64(),
	Speed.metres_a_step(0.5).step_length().to_metres(),
]

speed_want : List(F64)
speed_want = [
	76.0,
	0.0,
	2.5,
	10.0,
	0.5,
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "bt-sums  ",
			got: sums_got,
			want: sums_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "bt-ratios",
			got: ratios_got,
			want: ratios_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "bt-order ",
			got: order_got,
			want: order_want,
		}),
		Grade.reals({
			name: "bt-speed ",
			got: speed_got,
			want: speed_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
