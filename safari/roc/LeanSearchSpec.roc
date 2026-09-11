# LeanSearchSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import DeviceMath
import Grade
import LeanSearch
import Maybe
import Pose
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

target_got : List(F64)
target_got = [LeanSearch.lean_target(0.5), LeanSearch.lean_target((0.0 - 0.5)), LeanSearch.lean_target(2.0), LeanSearch.lean_target((0.0 - 2.0)), LeanSearch.lean_target(0.04), LeanSearch.lean_target((0.0 - 0.04)), LeanSearch.lean_target(0.0), LeanSearch.lean_target(0.039), LeanSearch.lean_target((0.0 - 0.039))]

target_want : List(F64)
target_want = [0.15, (-0.15), 0.6, (-0.6), 0.012, (-0.012), 0.04, 0.04, (-0.04)]

side_got : List(Bool)
side_got = [(LeanSearch.lean_target(2.0) > 0.0), (LeanSearch.lean_target(2.0) < 2.0), (LeanSearch.lean_target((0.0 - 2.0)) < 0.0), (LeanSearch.lean_target((0.0 - 2.0)) > (0.0 - 2.0)), (LeanSearch.lean_target(0.0) > 0.0)]

side_want : List(Bool)
side_want = [True, True, True, True, True]

tuning_got : List(F64)
tuning_got = [LeanSearch.asymptote_tuning, LeanSearch.center_lane_epsilon, LeanSearch.max_tilt_correction]

tuning_want : List(F64)
tuning_want = [0.3, 0.04, 0.017453292519943295]

iters_got : List(I64)
iters_got = [LeanSearch.lean_search_iters]

iters_want : List(I64)
iters_want = [12]

outcome : Arc.Shoulder, F64 -> Arc.ArcOutcome
outcome = |sh, end_across| { shoulder: sh, forward: 10.0, crossed: False, end_across: end_across, frames: 100.0 }

read_got : List(Bool)
read_got = [LeanSearch.want_more_right(outcome(ShoulderLeft, 99.0), 0.5), LeanSearch.want_more_right(outcome(ShoulderLeft, (0.0 - 99.0)), 0.5), LeanSearch.want_more_right(outcome(ShoulderRight, 99.0), 0.5), LeanSearch.want_more_right(outcome(ShoulderRight, (0.0 - 99.0)), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.4), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.6), 0.5), LeanSearch.want_more_right(outcome(ShoulderNone, 0.5), 0.5)]

read_want : List(Bool)
read_want = [True, True, False, False, True, False, False]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64 -> Pose.RiderState
rider = |across, tilt| { segment: 0, along: 0.0, across: across, yaw: 0.0, v: Pose.v_base, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

centred : F64
centred = LeanSearch.best_tilt_correction(rider(0.0, 0.0), seg)

offset : F64
offset = LeanSearch.best_tilt_correction(rider(1.0, 0.0), seg)

held : F64
held = LeanSearch.best_tilt_correction(rider(0.0, 0.5), seg)

bracket_got : List(Bool)
bracket_got = [(centred >= (0.0 - LeanSearch.max_tilt_correction)), (centred <= LeanSearch.max_tilt_correction), (offset >= (0.0 - LeanSearch.max_tilt_correction)), (offset <= LeanSearch.max_tilt_correction), (held >= (0.5 - LeanSearch.max_tilt_correction)), (held <= (0.5 + LeanSearch.max_tilt_correction))]

bracket_want : List(Bool)
bracket_want = [True, True, True, True, True, True]

centred_on_got : List(Bool)
centred_on_got = [(DeviceMath.real_abs((held - 0.5)) <= LeanSearch.max_tilt_correction), (DeviceMath.real_abs(centred) <= LeanSearch.max_tilt_correction), (held > centred)]

centred_on_want : List(Bool)
centred_on_want = [True, True, True]

stable_got : List(F64)
stable_got = [(LeanSearch.best_tilt_correction(rider(1.0, 0.0), seg) - offset), (LeanSearch.best_tilt_correction(rider(0.0, 0.5), seg) - held)]

stable_want : List(F64)
stable_want = [0.0, 0.0]

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

eq_maybe : Maybe.Maybe(a), Maybe.Maybe(a) -> Bool
eq_maybe = |ex, ey| (match ex {
	Just(exf0) => (match ey {
		Just(eyf0) => (exf0 == eyf0)
		_ => False
	})
	None => (match ey {
		None => True
		_ => False
	})
})

eq_scheme : Scenery.Scheme, Scenery.Scheme -> Bool
eq_scheme = |ex, ey| (match ex {
	AllGreen => (match ey {
		AllGreen => True
		_ => False
	})
	YellowGreen => (match ey {
		YellowGreen => True
		_ => False
	})
	RedGreen => (match ey {
		RedGreen => True
		_ => False
	})
})

eq_creature : Scenery.Creature, Scenery.Creature -> Bool
eq_creature = |ex, ey| (match ex {
	NoCreature => (match ey {
		NoCreature => True
		_ => False
	})
	Elephant => (match ey {
		Elephant => True
		_ => False
	})
	Giraffe => (match ey {
		Giraffe => True
		_ => False
	})
	Zebra => (match ey {
		Zebra => True
		_ => False
	})
	Rhino => (match ey {
		Rhino => True
		_ => False
	})
	DuckPond => (match ey {
		DuckPond => True
		_ => False
	})
})

eq_shoulder : Arc.Shoulder, Arc.Shoulder -> Bool
eq_shoulder = |ex, ey| (match ex {
	ShoulderLeft => (match ey {
		ShoulderLeft => True
		_ => False
	})
	ShoulderNone => (match ey {
		ShoulderNone => True
		_ => False
	})
	ShoulderRight => (match ey {
		ShoulderRight => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("ls-target", target_got, target_want, 0.0))
	line!(Grade.grade_bools("ls-side  ", side_got, side_want))
	line!(Grade.grade_reals("ls-tuning", tuning_got, tuning_want, 0.0))
	line!(Grade.grade_ints("ls-iters ", iters_got, iters_want))
	line!(Grade.grade_bools("ls-read  ", read_got, read_want))
	line!(Grade.grade_bools("ls-brackt", bracket_got, bracket_want))
	line!(Grade.grade_bools("ls-centre", centred_on_got, centred_on_want))
	line!(Grade.grade_reals("ls-stable", stable_got, stable_want, 0.0))
	Ok({})
}
