# RiderSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import DeviceMath
import Grade
import LeanSearch
import Maybe
import Pose
import Rider
import Scenery
import Throttle
import Tuple
import VehicleLimits
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

seg : World.Segment
seg = World.segment_at(0)

rider : F64, F64, F64, F64 -> Pose.RiderState
rider = |along, across, v, tilt| { segment: 0, along: along, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

step_got : List(Bool)
step_got = ({
	d = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.0), seg)
	held = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.5), seg)
	[(DeviceMath.real_abs(d.tilt_step) <= LeanSearch.max_tilt_correction), (DeviceMath.real_abs(held.tilt_step) <= LeanSearch.max_tilt_correction), (d.accel <= (VehicleLimits.a_accel + F64.from_bits(4517329193108106637)))]
})

step_want : List(Bool)
step_want = [True, True, True]

leaned_got : List(Bool)
leaned_got = ({
	d = Rider.decide(rider(0.0, 0.0, Pose.v_base, 0.0), seg)
	same = Throttle.get_forward_accel_decel(Pose.with_tilt(rider(0.0, 0.0, Pose.v_base, 0.0), (0.0 + d.tilt_step)), seg)
	[(F64.to_bits(d.accel) == F64.to_bits(same))]
})

leaned_want : List(Bool)
leaned_want = [True]

at_seam : Pose.RiderState
at_seam = { segment: 0, along: 499.0, across: 0.5, yaw: 0.1, v: 1.25, tilt: 0.05, heading: 0.7, gaze_yaw: 0.3, focus: 0.4 }

crossed : Pose.RiderState
crossed = Rider.rider_state_for_next_segment(at_seam, segs)

carry_got : List(F64)
carry_got = [crossed.v, crossed.tilt, crossed.focus, crossed.gaze_yaw]

carry_want : List(F64)
carry_want = [1.25, 0.05, 0.4, 0.0]

turn_got : List(F64)
turn_got = [(crossed.heading - 0.7), (crossed.yaw - (0.1 - seg.exit_angle))]

turn_want : List(F64)
turn_want = [0.0, 0.0]

index_got : List(I64)
index_got = [crossed.segment, seg.exit_to]

index_want : List(I64)
index_want = [1, 1]

early_got : List(Bool)
early_got = ({
	far = Rider.rider_state_for_next_segment(rider(100.0, 0.0, Pose.v_base, 0.0), segs)
	[(DeviceMath.real_abs(far.across) >= (World.segment_at(1).width / 2.0))]
})

early_want : List(Bool)
early_want = [True]

resolve_got : List(I64)
resolve_got = [Rider.resolve_cross(rider(100.0, 0.0, Pose.v_base, 0.0), seg, segs).segment, Rider.resolve_cross(rider(499.0, 0.0, Pose.v_base, 0.0), seg, segs).segment]

resolve_want : List(I64)
resolve_want = [0, 1]

last_seg : World.Segment
last_seg = World.segment_at(18)

ended : F64, F64 -> Pose.RiderState
ended = |along, v| Rider.finish_clamp({ segment: 0, along: along, across: 0.0, yaw: 0.0, v: v, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }, last_seg)

finish_got : List(F64)
finish_got = [ended(300.0, 0.5).along, ended(300.0, 0.5).v, ended(310.0, 0.5).along, ended(310.0, 0.5).v, ended(290.0, 0.05).along, ended(290.0, 0.05).v, ended(290.0, 0.5).along, ended(290.0, 0.5).v, ended(100.0, 0.05).along, ended(100.0, 0.05).v]

finish_want : List(F64)
finish_want = [300.0, 0.0, 300.0, 0.0, 300.0, 0.0, 290.0, 0.5, 100.0, 0.05]

done_got : List(Bool)
done_got = ({
	at_end = { segment: 0, along: 300.0, across: 0.0, yaw: 0.0, v: 0.0, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }
	short = { segment: 0, along: 299.0, across: 0.0, yaw: 0.0, v: 0.0, tilt: 0.0, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }
	[Rider.is_finished(at_end, [World.segment_at(18)]), Rider.is_finished(short, [World.segment_at(18)]), last_seg.terminates, Rider.is_finished(rider(499.0, 0.0, Pose.v_base, 0.0), segs)]
})

done_want : List(Bool)
done_want = [True, False, True, False]

next : Pose.RiderState
next = Rider.get_next_rider_state(rider(0.0, 0.0, Pose.v_base, 0.0), segs)

frame_got : List(Bool)
frame_got = [(next.along > 0.0), (next.v > 0.0), (next.segment == 0), (DeviceMath.real_abs(next.across) < (seg.width / 2.0)), (next.v <= VehicleLimits.v_max)]

frame_want : List(Bool)
frame_want = [True, True, True, True, True]

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
	line!(Grade.grade_bools("rd-step  ", step_got, step_want))
	line!(Grade.grade_bools("rd-leaned", leaned_got, leaned_want))
	line!(Grade.grade_reals("rd-carry ", carry_got, carry_want, 0.0))
	line!(Grade.grade_reals("rd-turn  ", turn_got, turn_want, 0.0))
	line!(Grade.grade_ints("rd-index ", index_got, index_want))
	line!(Grade.grade_bools("rd-early ", early_got, early_want))
	line!(Grade.grade_ints("rd-resolv", resolve_got, resolve_want))
	line!(Grade.grade_reals("rd-finish", finish_got, finish_want, 0.0))
	line!(Grade.grade_bools("rd-done  ", done_got, done_want))
	line!(Grade.grade_bools("rd-frame ", frame_got, frame_want))
	Ok({})
}
