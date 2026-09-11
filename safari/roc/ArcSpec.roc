# ArcSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import Bike
import Grade
import Maybe
import Pose
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [Arc.no_frames, Arc.straighten_margin, Arc.min_forward_progress]

fixed_want : List(F64)
fixed_want = [1000000000.0, 0.05, 25.0]

steps_got : List(I64)
steps_got = [Arc.turn_danger_steps]

steps_want : List(I64)
steps_want = [2000]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64, F64 -> Pose.RiderState
rider = |across, tilt, v| { segment: 0, along: 0.0, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

side : Arc.ArcOutcome -> I64
side = |o| (match o.shoulder {
	ShoulderLeft => (-1)
	ShoulderNone => 0
	ShoulderRight => 1
})

straight : Arc.ArcOutcome
straight = Arc.project_arc(rider(0.0, 0.0, Pose.v_base), seg)

straight_got : List(F64)
straight_got = [straight.forward, straight.end_across, straight.frames]

straight_want : List(F64)
straight_want = [25.0, 0.0, 1000000000.0]

wide : Arc.ArcOutcome
wide = Arc.project_arc(rider(3.0, 0.0, Pose.v_base), seg)

wide_got : List(F64)
wide_got = [wide.forward, wide.end_across, wide.frames]

wide_want : List(F64)
wide_want = [25.0, 3.0, 1000000000.0]

stopped : Arc.ArcOutcome
stopped = Arc.project_arc(rider(0.0, 0.0, 0.0), seg)

stopped_got : List(F64)
stopped_got = [stopped.forward, stopped.end_across, stopped.frames]

stopped_want : List(F64)
stopped_want = [0.0, 0.0, 1000000000.0]

none_got : List(I64)
none_got = [side(straight), side(wide), side(stopped)]

none_want : List(I64)
none_want = [0, 0, 0]

crossed_got : List(Bool)
crossed_got = [straight.crossed, wide.crossed, stopped.crossed]

crossed_want : List(Bool)
crossed_want = [False, False, False]

leaning : Arc.ArcOutcome
leaning = Arc.project_arc(rider(0.0, 0.2, Pose.v_base), seg)

other_way : Arc.ArcOutcome
other_way = Arc.project_arc(rider(0.0, (0.0 - 0.2), Pose.v_base), seg)

leaving_got : List(I64)
leaving_got = [side(leaning), side(other_way)]

leaving_want : List(I64)
leaving_want = [1, (-1)]

left_got : List(Bool)
left_got = [(leaning.frames < Arc.no_frames), (leaning.frames < I64.to_f64(Arc.turn_danger_steps)), (leaning.frames > 0.0), (leaning.forward <= Arc.min_forward_progress), (leaning.end_across > 0.0), (other_way.end_across < 0.0), (other_way.frames < Arc.no_frames)]

left_want : List(Bool)
left_want = [True, True, True, True, True, True, True]

mirror_got : List(F64)
mirror_got = [(leaning.frames - other_way.frames), (leaning.end_across + other_way.end_across)]

mirror_want : List(F64)
mirror_want = [0.0, 0.0]

mirror_fwd_got : List(F64)
mirror_fwd_got = [(leaning.forward - other_way.forward)]

mirror_fwd_want : List(F64)
mirror_fwd_want = [0.0]

step_got : List(F64)
step_got = ({
	a = Bike.simulate_rider_step(rider(0.0, 0.0, Pose.v_base), 0.0, 0.0)
	b = Bike.simulate_rider_step(rider(0.0, 0.0, Pose.v_base), 0.5, 0.25)
	[a.across, a.yaw, a.heading, a.tilt, a.v, b.tilt, b.v, b.yaw, b.heading, Bike.yaw_per_tilt]
})

step_want : List(F64)
step_want = [0.0, 0.0, 0.0, 0.0, 0.3, 0.5, 0.55, 0.05, 0.05, 0.1]

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
	line!(Grade.grade_reals("ar-fixed ", fixed_got, fixed_want, 0.0))
	line!(Grade.grade_ints("ar-steps ", steps_got, steps_want))
	line!(Grade.grade_reals("ar-straig", straight_got, straight_want, 0.0))
	line!(Grade.grade_reals("ar-wide  ", wide_got, wide_want, 0.0))
	line!(Grade.grade_reals("ar-stop  ", stopped_got, stopped_want, 0.0))
	line!(Grade.grade_ints("ar-none  ", none_got, none_want))
	line!(Grade.grade_bools("ar-cross ", crossed_got, crossed_want))
	line!(Grade.grade_ints("ar-side  ", leaving_got, leaving_want))
	line!(Grade.grade_bools("ar-left  ", left_got, left_want))
	line!(Grade.grade_reals("ar-mirror", mirror_got, mirror_want, 0.0))
	line!(Grade.grade_reals("ar-mfwd  ", mirror_fwd_got, mirror_fwd_want, F64.from_bits(4517329193108106637)))
	line!(Grade.grade_reals("ar-step  ", step_got, step_want, 0.0))
	Ok({})
}
