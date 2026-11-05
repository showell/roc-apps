## These are Cat's checks: where a cat crosses, its sizes and timings, when it
## is in danger, its progress and the rider's focus, its stride, its poses,
## and where it is as it walks out, freezes and leaps.
app [main!] {
	lib: "../lib/main.roc",
}

import Cat
import Grade
import Speed
import lib.Trig

the_cat : Cat.Crossing
the_cat = Cat.crossing({
	lane_half_width: 2.0,
	tree_offset: 1.0,
	tree_along: 100.0,
})

## A rider `gap` metres short of the cat, at `speed` metres a step.
coming : F64, F64 -> Cat.Approach
coming = |gap, speed| { gap, speed: Speed.metres_a_step(speed) }

make_got : List(F64)
make_got = [
	the_cat.along,
	the_cat.start_across,
	the_cat.mid_across,
	the_cat.height,
]

make_want : List(F64)
make_want = [102.0, 4.5, 0.816, 1.7]

make_wide_got : List(F64)
make_wide_got = [the_cat.end_across, (the_cat.mid_across - the_cat.end_across)]

make_wide_want : List(F64)
make_wide_want = [(-3.49), 4.306]

dims_got : List(F64)
dims_got = [
	Cat.cat_height,
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
	Cat.enters_road_steps,
	Cat.frozen_steps,
	Cat.escapes_steps,
	Cat.cross_frames,
	Cat.road_buffer,
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

t_got : List(F64)
t_got = [
	coming(41.0, 1.0),
	coming(22.0, 1.0),
	coming(3.0, 1.0),
	coming(2.0, 1.0),
	coming(100.0, 1.0),
	coming(41.0, 0.0),
].map(Cat.crossing_progress)

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
	].map(Cat.focus),
	[Cat.focus_peak, Cat.focus_ramp_down],
])

## The stride angle `progress` through a walk of `steps`, in whole turns.
turns : F64, F64 -> F64
turns = |progress, steps| (Cat.stride_angle({ progress, steps }) / Trig.two_pi)

focus_want : List(F64)
focus_want = [0.0, 0.9, 1.8, 0.9, 0.0, 0.0, 1.8, 83.0]

cycles_got : List(F64)
cycles_got = [
	Cat.stride_angle({ progress: 0.0, steps: 10.0 }),
	turns(1.0, 10.0),
	turns(0.5, 10.0),
	turns(1.0, 20.0),
	turns(1.0, 3.0),
	turns(1.0, 0.0),
	Cat.stride_steps,
]

cycles_want : List(F64)
cycles_want = [0.0, 2.0, 1.0, 4.0, 1.0, 1.0, 5.0]

pose_got : List(I64)
pose_got = List.concat(
	[Rest, Stride, Frozen, Coil, Flight, Land, Collapse],
	[0.0, 0.19, 0.2, 0.69, 0.7, 0.94, 0.95, 1.0].map(Cat.leap_pose),
).map(Cat.pose_index)

pose_want : List(I64)
pose_want = [0, 1, 2, 3, 4, 5, 6, 3, 3, 4, 4, 5, 5, 6, 6]

phase_of : F64 -> Cat.CatState
phase_of = |gap| Cat.state(the_cat, coming(gap, 1.0))

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

walking : F64 -> Cat.CatState
walking = |step| Cat.entering(the_cat, step)

entering_got : List(F64)
entering_got = [
	walking(0.0).across,
	walking(1.25).across,
	walking(3.75).across,
	walking(6.25).across,
	walking(8.75).across,
	walking(0.0).lift,
	walking(8.75).lift,
]

entering_want : List(F64)
entering_want = [4.5, 4.0395, 3.1185, 2.1975, 1.2765, 0.0, 0.0]

stride_got : List(I64)
stride_got = [0.0, 1.25, 3.75, 6.25, 8.75].map(|step| Cat.pose_index(walking(step).pose))

stride_want : List(I64)
stride_want = [0, 1, 0, 1, 0]

frozen_got : List(F64)
frozen_got = [
	phase_of(30.0).across,
	phase_of(7.0).across,
	phase_of(30.0).lift,
]

frozen_want : List(F64)
frozen_want = [0.816, 0.816, 0.0]

leap_got : List(F64)
leap_got = [
	phase_of(6.5).across,
	phase_of(6.5).lift,
	phase_of(6.0).across,
	phase_of(6.0).lift,
	Cat.three_quarter_power(0.0),
	Cat.three_quarter_power(1.0),
	Cat.three_quarter_power(0.0625),
	Cat.leap_height,
]

leap_want : List(F64)
leap_want = [0.816, 0.0, 0.816, 0.0, 0.0, 1.0, 0.125, 0.18]

flight_got : List(F64)
flight_got = [
	phase_of(5.875).across,
	phase_of(5.875).lift,
	phase_of(4.0).across,
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
