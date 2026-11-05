## These are Cat's checks: where a cat crosses, its sizes and timings, when it
## is in danger, its progress and the rider's focus, its stride, its poses,
## and where it is as it walks out, freezes and leaps.
app [main!] {
	lib: "../lib/main.roc",
}

import Animation
import Beats
import Cat
import Easing
import Fraction
import Distance
import Grade
import Speed

the_cat : Cat.Crossing
the_cat = Cat.crossing({
	lane_half_width: 2.0,
	tree_offset: 1.0,
	tree_along: 100.0,
})

## A rider `gap` metres short of the cat, at `speed` metres a step.
coming : F64, F64 -> Animation.Approach
coming = |gap, speed| { gap: Distance.metres(gap), speed: Speed.metres_a_step(speed) }

make_got : List(F64)
make_got = [
	the_cat.along,
	the_cat.start_across,
	the_cat.mid_across,
	the_cat.height.to_metres(),
]

make_want : List(F64)
make_want = [102.0, 4.5, 0.816, 1.7]

make_wide_got : List(F64)
make_wide_got = [the_cat.end_across, (the_cat.mid_across - the_cat.end_across)]

make_wide_want : List(F64)
make_wide_want = [(-3.49), 4.306]

dims_got : List(F64)
dims_got = [
	Cat.cat_height.to_metres(),
	Cat.cat_along,
	Cat.cat_road_gap,
	Cat.cat_beyond_tree,
	Cat.cat_head_x,
	Cat.land_hind_reach,
	Cat.grass_toehold,
]

dims_want : List(F64)
dims_want = [
	1.7,
	105.0,
	1.5,
	2.0,
	(-0.48),
	1.19,
	0.3,
]

window_got : List(F64)
window_got = [
	Cat.enters_road_beats.to_f64(),
	Cat.frozen_beats.to_f64(),
	Cat.escapes_beats.to_f64(),
	Cat.crossing_beats.to_f64(),
	Cat.road_buffer.to_metres(),
]

window_want : List(F64)
window_want = [10.0, 24.0, 4.0, 38.0, 3.0]

danger_got : List(Bool)
danger_got = [
	coming(41.0, 1.0),
	coming(42.0, 1.0),
	coming(3.0, 1.0),
	coming(2.0, 1.0),
	coming(41.0, 0.0),
	coming(22.0, 1.0),
].map(Cat.is_in_danger)

danger_want : List(Bool)
danger_want = [True, False, False, False, False, True]

## How far through its crossing a cat is.
progress_of : Animation.Approach -> F64
progress_of = |approach|
	match Cat.crossing_stage(approach) {
		Waiting => 0.0
		Playing(progress) => progress.to_f64()
		Past(_) => 1.0
	}

t_got : List(F64)
t_got = [
	coming(41.0, 1.0),
	coming(22.0, 1.0),
	coming(3.0, 1.0),
	coming(2.0, 1.0),
	coming(100.0, 1.0),
	coming(41.0, 0.0),
].map(progress_of)

t_want : List(F64)
t_want = [0.0, 0.5, 1.0, 1.0, 0.0, 0.0]

focus_got : List(F64)
focus_got = List.join([
	[
		coming(41.0, 1.0),
		coming(22.0, 1.0),
		coming(3.0, 1.0),
		coming((0.0 - 38.5), 1.0),
		coming((0.0 - 80.0), 1.0),
		coming(22.0, 0.0),
	].map(|approach| Cat.focus(approach).to_f64()),
	[Cat.focus_peak.to_f64(), Cat.focus_ramp_down.to_f64()],
])

## How many strides of a walk `length` beats long are done `progress` through it.
turns : F64, F64 -> F64
turns = |progress, length| progress * Cat.strides_in(Beats.of(length))

focus_want : List(F64)
focus_want = [0.0, 0.9, 1.8, 0.9, 0.0, 0.0, 1.8, 83.0]

cycles_got : List(F64)
cycles_got = [
	turns(0.0, 10.0),
	turns(1.0, 10.0),
	turns(0.5, 10.0),
	turns(1.0, 20.0),
	turns(1.0, 3.0),
	turns(1.0, 0.0),
	Cat.stride_beats.to_f64(),
]

cycles_want : List(F64)
cycles_want = [0.0, 2.0, 1.0, 4.0, 1.0, 1.0, 5.0]

## The cat at `beat` of its crossing.
crossing_at : F64 -> Animation.Instant(Cat.Pose)
crossing_at = |beat| Cat.crossing_timeline(the_cat).at_beat(Beats.of(beat))

pose_got : List(I64)
pose_got = List.concat(
	[Rest, Stride, Frozen, Coil, Flight, Land, Collapse],
	[
		34.01,
		34.79,
		34.81,
		36.79,
		36.81,
		37.79,
		37.81,
		38.0,
	].map(|beat| crossing_at(beat).pose),
).map(Cat.pose_index)

pose_want : List(I64)
pose_want = [0, 1, 2, 3, 4, 5, 6, 3, 3, 4, 4, 5, 5, 6, 6]

## The float after `beat`.
just_past : F64 -> F64
just_past = |beat| F64.from_bits(beat.to_bits() + 1)

## Where a cut `into_escape` beats into the escape falls.
cut_after_escape : Beats -> F64
cut_after_escape = |into_escape| Cat.escape_at.plus(into_escape).to_f64()

## Each leap pose lasts through its cut's own float, and no further.
cut_got : List(I64)
cut_got = [
	cut_after_escape(Cat.coil_ends_beats),
	just_past(cut_after_escape(Cat.coil_ends_beats)),
	cut_after_escape(Cat.flight_ends_beats),
	just_past(cut_after_escape(Cat.flight_ends_beats)),
	cut_after_escape(Cat.land_ends_beats),
	just_past(cut_after_escape(Cat.land_ends_beats)),
].map(|beat| Cat.pose_index(crossing_at(beat).pose))

cut_want : List(I64)
cut_want = [
	3,
	4,
	4,
	5,
	5,
	6,
]

phase_of : F64 -> Animation.Instant(Cat.Pose)
phase_of = |gap| Cat.instant_at(the_cat, coming(gap, 1.0))

which_got : List(I64)
which_got = [
	41.0,
	31.5,
	30.0,
	7.0,
	6.5,
	6.0,
	4.0,
	3.0,
].map(|gap| Cat.pose_index(phase_of(gap).pose))

which_want : List(I64)
which_want = [0, 0, 2, 2, 3, 4, 5, 6]

entering_got : List(F64)
entering_got = [
	crossing_at(0.0).spot.across,
	crossing_at(1.25).spot.across,
	crossing_at(3.75).spot.across,
	crossing_at(6.25).spot.across,
	crossing_at(8.75).spot.across,
	crossing_at(0.0).spot.lift,
	crossing_at(8.75).spot.lift,
]

entering_want : List(F64)
entering_want = [4.5, 4.0395, 3.1185, 2.1975, 1.2765, 0.0, 0.0]

stride_got : List(I64)
stride_got = [0.0, 1.25, 3.75, 6.25, 8.75].map(|beat| Cat.pose_index(crossing_at(beat).pose))

stride_want : List(I64)
stride_want = [0, 1, 0, 1, 0]

frozen_got : List(F64)
frozen_got = [
	phase_of(30.0).spot.across,
	phase_of(7.0).spot.across,
	phase_of(30.0).spot.lift,
]

frozen_want : List(F64)
frozen_want = [0.816, 0.816, 0.0]

leap_got : List(F64)
leap_got = [
	phase_of(6.5).spot.across,
	phase_of(6.5).spot.lift,
	phase_of(6.0).spot.across,
	phase_of(6.0).spot.lift,
	Easing.three_quarter_power(Fraction.zero).to_f64(),
	Easing.three_quarter_power(Fraction.whole).to_f64(),
	Easing.three_quarter_power(Fraction.of(0.0625)).to_f64(),
	Cat.leap_height,
]

leap_want : List(F64)
leap_want = [0.816, 0.0, 0.816, 0.0, 0.0, 1.0, 0.125, 0.18]

flight_got : List(F64)
flight_got = [
	phase_of(5.875).spot.across,
	phase_of(5.875).spot.lift,
	phase_of(4.0).spot.across,
]

flight_want : List(F64)
flight_want = [
	0.27775,
	0.0421875,
	(-3.49),
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "ct-make  ",
			got: make_got,
			want: make_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-dims  ",
			got: dims_got,
			want: dims_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-window",
			got: window_got,
			want: window_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "ct-danger",
			got: danger_got,
			want: danger_want,
		}),
		Grade.reals({
			name: "ct-clock ",
			got: t_got,
			want: t_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-focus ",
			got: focus_got,
			want: focus_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-gait  ",
			got: cycles_got,
			want: cycles_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "ct-pose  ",
			got: pose_got,
			want: pose_want,
		}),
		Grade.ints({
			name: "ct-cuts  ",
			got: cut_got,
			want: cut_want,
		}),
		Grade.ints({
			name: "ct-which ",
			got: which_got,
			want: which_want,
		}),
		Grade.reals({
			name: "ct-enter ",
			got: entering_got,
			want: entering_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "ct-stride",
			got: stride_got,
			want: stride_want,
		}),
		Grade.reals({
			name: "ct-frozen",
			got: frozen_got,
			want: frozen_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-leap  ",
			got: leap_got,
			want: leap_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "ct-wide  ",
			got: make_wide_got,
			want: make_wide_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "ct-flight",
			got: flight_got,
			want: flight_want,
			tol: F64.from_bits(4427486594234968593),
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
