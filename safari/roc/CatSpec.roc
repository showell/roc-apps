# CatSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cat
import Grade
import Trig
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

the_cat : Cat.Cat
the_cat = Cat.cat_make(2.0, 1.0, 100.0)

make_got : List(F64)
make_got = [the_cat.along, the_cat.start_across, the_cat.mid_across, the_cat.height]

make_want : List(F64)
make_want = [102.0, 4.5, 0.816, 1.7]

make_wide_got : List(F64)
make_wide_got = [the_cat.end_across, (the_cat.mid_across - the_cat.end_across)]

make_wide_want : List(F64)
make_wide_want = [(-3.49), 4.306]

dims_got : List(F64)
dims_got = [Cat.cat_height, Cat.cat_along, Cat.cat_road_gap, Cat.cat_beyond_tree, Cat.cat_head_x, Cat.land_hind_reach, Cat.grass_toehold]

dims_want : List(F64)
dims_want = [1.7, 105.0, 1.5, 2.0, (-0.48), 1.19, 0.3]

window_got : List(F64)
window_got = [Cat.enters_road_steps, Cat.frozen_steps, Cat.escapes_steps, Cat.cross_frames, Cat.road_buffer]

window_want : List(F64)
window_want = [10.0, 24.0, 4.0, 38.0, 3.0]

danger_got : List(Bool)
danger_got = [Cat.cat_in_danger(41.0, 1.0), Cat.cat_in_danger(42.0, 1.0), Cat.cat_in_danger(3.0, 1.0), Cat.cat_in_danger(2.0, 1.0), Cat.cat_in_danger(41.0, 0.0), Cat.cat_in_danger(22.0, 1.0)]

danger_want : List(Bool)
danger_want = [True, False, False, False, False, True]

t_got : List(F64)
t_got = [Cat.cross_t(41.0, 1.0), Cat.cross_t(22.0, 1.0), Cat.cross_t(3.0, 1.0), Cat.cross_t(2.0, 1.0), Cat.cross_t(100.0, 1.0), Cat.cross_t(41.0, 0.0), Cat.clamp01((0.0 - 0.5)), Cat.clamp01(0.25), Cat.clamp01(1.5), Cat.lerp(2.0, 6.0, 0.25), Cat.lerp(2.0, 6.0, 0.0), Cat.lerp(2.0, 6.0, 1.0)]

t_want : List(F64)
t_want = [0.0, 0.5, 1.0, 1.0, 0.0, 0.0, 0.0, 0.25, 1.0, 3.0, 2.0, 6.0]

focus_got : List(F64)
focus_got = [Cat.cat_smoothstep(0.0), Cat.cat_smoothstep(0.5), Cat.cat_smoothstep(1.0), Cat.cat_focus(41.0, 1.0), Cat.cat_focus(22.0, 1.0), Cat.cat_focus(3.0, 1.0), Cat.cat_focus((0.0 - 38.5), 1.0), Cat.cat_focus((0.0 - 80.0), 1.0), Cat.cat_focus(22.0, 0.0), Cat.focus_peak, Cat.focus_ramp_down]

focus_want : List(F64)
focus_want = [0.0, 0.5, 1.0, 0.0, 0.9, 1.8, 0.9, 0.0, 0.0, 1.8, 83.0]

cycles_got : List(F64)
cycles_got = [Cat.gait(0.0, 10.0), (Cat.gait(1.0, 10.0) / Trig.two_pi), (Cat.gait(0.5, 10.0) / Trig.two_pi), (Cat.gait(1.0, 20.0) / Trig.two_pi), (Cat.gait(1.0, 3.0) / Trig.two_pi), (Cat.gait(1.0, 0.0) / Trig.two_pi), Cat.stride_steps]

cycles_want : List(F64)
cycles_want = [0.0, 2.0, 1.0, 4.0, 1.0, 1.0, 5.0]

pose_got : List(I64)
pose_got = [Cat.pose_rest, Cat.pose_stride, Cat.pose_frozen, Cat.pose_coil, Cat.pose_flight, Cat.pose_land, Cat.pose_collapse, Cat.leap_pose_for(0.0), Cat.leap_pose_for(0.19), Cat.leap_pose_for(0.2), Cat.leap_pose_for(0.69), Cat.leap_pose_for(0.7), Cat.leap_pose_for(0.94), Cat.leap_pose_for(0.95), Cat.leap_pose_for(1.0)]

pose_want : List(I64)
pose_want = [0, 1, 2, 3, 4, 5, 6, 3, 3, 4, 4, 5, 5, 6, 6]

phase_of : F64 -> Cat.CatState
phase_of = |gap| Cat.cat_state(the_cat, gap, 1.0)

which_got : List(I64)
which_got = [phase_of(41.0).pose_idx, phase_of(31.5).pose_idx, phase_of(30.0).pose_idx, phase_of(7.0).pose_idx, phase_of(6.5).pose_idx, phase_of(6.0).pose_idx, phase_of(4.0).pose_idx, phase_of(3.0).pose_idx]

which_want : List(I64)
which_want = [0, 0, 2, 2, 3, 4, 5, 6]

walking : F64 -> Cat.CatState
walking = |step| Cat.cat_entering(the_cat, step)

entering_got : List(F64)
entering_got = [walking(0.0).across, walking(1.25).across, walking(3.75).across, walking(6.25).across, walking(8.75).across, walking(0.0).lift, walking(8.75).lift]

entering_want : List(F64)
entering_want = [4.5, 4.0395, 3.1185, 2.1975, 1.2765, 0.0, 0.0]

stride_got : List(I64)
stride_got = [walking(0.0).pose_idx, walking(1.25).pose_idx, walking(3.75).pose_idx, walking(6.25).pose_idx, walking(8.75).pose_idx]

stride_want : List(I64)
stride_want = [0, 1, 0, 1, 0]

frozen_got : List(F64)
frozen_got = [phase_of(30.0).across, phase_of(7.0).across, phase_of(30.0).lift]

frozen_want : List(F64)
frozen_want = [0.816, 0.816, 0.0]

leap_got : List(F64)
leap_got = [phase_of(6.5).across, phase_of(6.5).lift, phase_of(6.0).across, phase_of(6.0).lift, Cat.pow075(0.0), Cat.pow075(1.0), Cat.pow075(0.0625), Cat.leap_height]

leap_want : List(F64)
leap_want = [0.816, 0.0, 0.816, 0.0, 0.0, 1.0, 0.125, 0.18]

flight_got : List(F64)
flight_got = [phase_of(5.875).across, phase_of(5.875).lift, phase_of(4.0).across]

flight_want : List(F64)
flight_want = [0.27775, 0.0421875, (-3.49)]

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("ct-make  ", make_got, make_want, 0.0))
	line!(Grade.grade_reals("ct-dims  ", dims_got, dims_want, 0.0))
	line!(Grade.grade_reals("ct-window", window_got, window_want, 0.0))
	line!(Grade.grade_bools("ct-danger", danger_got, danger_want))
	line!(Grade.grade_reals("ct-clock ", t_got, t_want, 0.0))
	line!(Grade.grade_reals("ct-focus ", focus_got, focus_want, 0.0))
	line!(Grade.grade_reals("ct-gait  ", cycles_got, cycles_want, 0.0))
	line!(Grade.grade_ints("ct-pose  ", pose_got, pose_want))
	line!(Grade.grade_ints("ct-which ", which_got, which_want))
	line!(Grade.grade_reals("ct-enter ", entering_got, entering_want, 0.0))
	line!(Grade.grade_ints("ct-stride", stride_got, stride_want))
	line!(Grade.grade_reals("ct-frozen", frozen_got, frozen_want, 0.0))
	line!(Grade.grade_reals("ct-leap  ", leap_got, leap_want, 0.0))
	line!(Grade.grade_reals("ct-wide  ", make_wide_got, make_wide_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_reals("ct-flight", flight_got, flight_want, F64.from_bits(4427486594234968593)))
	Ok({})
}
