# ThrottleSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import Grade
import Maybe
import Pose
import Scenery
import Throttle
import Trig
import Tuple
import VehicleLimits
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [Throttle.tilt_hold, Throttle.brake_decay, (Throttle.tilt_hold / Trig.deg)]

fixed_want : List(F64)
fixed_want = [0.03490658503988659, 20.0, 2.0]

seg : World.Segment
seg = World.segment_at(0)

rider_at : F64, F64, F64, F64 -> Pose.RiderState
rider_at = |across, along, v, tilt| { segment: 0, along: along, across: across, yaw: 0.0, v: v, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: 0.0 }

rider : F64, F64, F64 -> Pose.RiderState
rider = |along, v, tilt| rider_at(0.0, along, v, tilt)

corner_got : List(F64)
corner_got = [Throttle.corner_brake(rider(498.4, 0.3, 0.0), seg, 0.222, 0.01), Throttle.corner_brake(rider(600.0, 0.3, 0.0), seg, 0.222, 0.01), Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 5.0))]

corner_want : List(F64)
corner_want = [0.0, 0.0, (-5.0)]

corner_min_got : List(Bool)
corner_min_got = [(Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, 0.01) <= 0.01), (Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 5.0)) <= (0.0 - 5.0)), (Throttle.corner_brake(rider(0.0, 2.0, 0.0), seg, 0.222, 0.01) < Throttle.corner_brake(rider(0.0, 0.3, 0.0), seg, 0.222, 0.01))]

corner_min_want : List(Bool)
corner_min_want = [True, True, True]

cat_seg : World.Segment
cat_seg = World.segment_at(1)

cat_got : List(F64)
cat_got = [Throttle.cat_gate(rider(0.0, 0.3, 0.0), seg, 0.01), Throttle.cat_gate(rider(0.0, 0.3, 0.0), seg, (0.0 - 5.0)), Throttle.cat_gate(rider(120.0, 0.3, 0.0), cat_seg, 0.01), Throttle.cat_gate(rider(120.0, 0.3, 0.0), cat_seg, (0.0 - 5.0)), Throttle.cat_gate(rider(0.0, 0.3, 0.0), cat_seg, 0.01)]

cat_want : List(F64)
cat_want = [0.01, (-5.0), 0.0, (-5.0), 0.01]

outcome : Arc.Shoulder -> Arc.ArcOutcome
outcome = |sh| { shoulder: sh, forward: 10.0, crossed: False, end_across: 0.0, frames: 40.0 }

road_got : List(Bool)
road_got = [Throttle.stayed_on_road(outcome(ShoulderNone)), Throttle.stayed_on_road(outcome(ShoulderLeft)), Throttle.stayed_on_road(outcome(ShoulderRight))]

road_want : List(Bool)
road_want = [True, False, False]

soon : Arc.ArcOutcome
soon = { shoulder: ShoulderLeft, forward: 10.0, crossed: False, end_across: 0.0, frames: 2.0 }

brake_got : List(Bool)
brake_got = ({
	far = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), outcome(ShoulderLeft), 0.01)
	near_off = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), soon, 0.01)
	already = Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), outcome(ShoulderLeft), (0.0 - 9.0))
	[(far < 0.0), (far > near_off), (already < (0.0 - 8.999))]
})

brake_want : List(Bool)
brake_want = [True, True, True]

instant : Arc.ArcOutcome
instant = { shoulder: ShoulderLeft, forward: 0.0, crossed: False, end_across: 0.0, frames: 0.0 }

zero_frames_got : List(Bool)
zero_frames_got = [(Throttle.shoulder_brake_at(rider(0.0, 1.0, 0.0), instant, 0.01) < 0.0)]

zero_frames_want : List(Bool)
zero_frames_want = [True]

clamp_got : List(F64)
clamp_got = [Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 1.0, False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 3.0, False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, (0.0 - 1.0), False), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.1, True), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.5, True), Throttle.clamp_v(rider(0.0, 0.3, 0.0), seg, 0.222, 0.1, False)]

clamp_want : List(F64)
clamp_want = [1.0, 2.5, 0.0, 0.222, 0.5, 0.1]

decide : F64, F64, F64 -> F64
decide = |along, v, tilt| Throttle.get_forward_accel_decel(rider(along, v, tilt), seg)

whole_got : List(F64)
whole_got = [decide(0.0, 0.3, 0.0), decide(0.0, VehicleLimits.v_max, 0.0), decide(0.0, 0.0, 0.0)]

whole_want : List(F64)
whole_want = [0.01, 0.0, 0.01]

wide : F64 -> F64
wide = |tilt| Throttle.get_forward_accel_decel(rider_at(100.0, 0.0, 0.3, tilt), seg)

tilt_got : List(F64)
tilt_got = [wide((0.0 - 0.001)), wide((0.0 - Throttle.tilt_hold)), wide(((0.0 - Throttle.tilt_hold) - 0.5))]

tilt_want : List(F64)
tilt_want = [0.01, 0.0, 0.0]

compose_got : List(Bool)
compose_got = [(decide(0.0, 0.3, (Throttle.tilt_hold - 0.001)) < 0.0), (decide(0.0, 0.3, 0.001) > 0.0), (decide(0.0, 0.3, (0.0 - (Throttle.tilt_hold - 0.001))) < 0.0)]

compose_want : List(Bool)
compose_want = [True, True, True]

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
	line!(Grade.grade_reals("th-fixed ", fixed_got, fixed_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_reals("th-corner", corner_got, corner_want, 0.0))
	line!(Grade.grade_bools("th-cmin  ", corner_min_got, corner_min_want))
	line!(Grade.grade_reals("th-cat   ", cat_got, cat_want, 0.0))
	line!(Grade.grade_bools("th-road  ", road_got, road_want))
	line!(Grade.grade_bools("th-brake ", brake_got, brake_want))
	line!(Grade.grade_bools("th-zero  ", zero_frames_got, zero_frames_want))
	line!(Grade.grade_reals("th-clamp ", clamp_got, clamp_want, 0.0))
	line!(Grade.grade_reals("th-whole ", whole_got, whole_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_reals("th-tilt  ", tilt_got, tilt_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_bools("th-comp  ", compose_got, compose_want))
	Ok({})
}
