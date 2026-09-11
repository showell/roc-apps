# RideFocalSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Bike
import DeviceMath
import Gaze
import Grade
import Lens
import Maybe
import Pose
import RideFocal
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

rider : I64, F64, F64, F64 -> Pose.RiderState
rider = |segment, along, tilt, focus| { segment: segment, along: along, across: 0.0, yaw: 0.0, v: Pose.v_base, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: focus }

has_cat_got : List(Bool)
has_cat_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).has_cat]

has_cat_want : List(Bool)
has_cat_want = [False, True]

idle_got : List(F64)
idle_got = [(RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 0.0)) - Lens.focal), RideFocal.cat_attention(segs, rider(0, 0.0, 0.0, 0.0)), Gaze.gaze_focus(0.0), (Lens.cam_focal(0.0, 0.0) - Lens.focal)]

idle_want : List(F64)
idle_want = [0.0, 0.0, 0.0, 0.0]

leaned : F64 -> F64
leaned = |tilt| RideFocal.ride_focal(segs, rider(0, 0.0, tilt, 0.0))

lean_got : List(Bool)
lean_got = [(leaned((Bike.max_lean / 2.0)) < leaned(0.0)), (leaned(Bike.max_lean) < leaned((Bike.max_lean / 2.0))), (leaned((0.0 - Bike.max_lean)) < leaned(0.0)), (leaned(0.0) <= Lens.focal)]

lean_want : List(Bool)
lean_want = [True, True, True, True]

clamp_got : List(F64)
clamp_got = [(leaned(Bike.max_lean) - leaned((0.0 - Bike.max_lean))), (leaned((Bike.max_lean * 2.0)) - leaned(Bike.max_lean)), (leaned((Bike.max_lean * 10.0)) - leaned(Bike.max_lean))]

clamp_want : List(F64)
clamp_want = [0.0, 0.0, 0.0]

cat_got : List(Bool)
cat_got = [(RideFocal.cat_attention(segs, rider(1, 120.0, 0.0, 0.0)) > 0.0), (RideFocal.cat_attention(segs, rider(1, 0.0, 0.0, 0.0)) > 0.0), (RideFocal.cat_attention(segs, rider(0, 120.0, 0.0, 0.0)) > 0.0), (RideFocal.ride_focal(segs, rider(1, 120.0, 0.0, 0.0)) < RideFocal.ride_focal(segs, rider(0, 120.0, 0.0, 0.0)))]

cat_want : List(Bool)
cat_want = [True, False, False, True]

gaze_got : List(Bool)
gaze_got = [(RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 1.0)) < RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 0.0))), (RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 1.0)) < RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 0.5))), (Gaze.gaze_focus(1.0) > Gaze.gaze_focus(0.0))]

gaze_want : List(Bool)
gaze_want = [True, True, True]

both : F64
both = RideFocal.ride_focal(segs, rider(0, 0.0, Bike.max_lean, 1.0))

lean_only : F64
lean_only = RideFocal.ride_focal(segs, rider(0, 0.0, Bike.max_lean, 0.0))

gaze_only : F64
gaze_only = RideFocal.ride_focal(segs, rider(0, 0.0, 0.0, 1.0))

min_got : List(Bool)
min_got = [(both <= lean_only), (both <= gaze_only), (F64.to_bits(both) == F64.to_bits(DeviceMath.real_min(lean_only, gaze_only))), ((lean_only + gaze_only) > both)]

min_want : List(Bool)
min_want = [True, True, True, True]

is_one_got : List(F64)
is_one_got = [(both - DeviceMath.real_min(lean_only, gaze_only)), (Lens.cam_focal(1.0, 0.0) - lean_only)]

is_one_want : List(F64)
is_one_want = [0.0, 0.0]

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_bools("rf-hascat", has_cat_got, has_cat_want))
	line!(Grade.grade_reals("rf-idle  ", idle_got, idle_want, 0.0))
	line!(Grade.grade_bools("rf-lean  ", lean_got, lean_want))
	line!(Grade.grade_reals("rf-clamp ", clamp_got, clamp_want, 0.0))
	line!(Grade.grade_bools("rf-cat   ", cat_got, cat_want))
	line!(Grade.grade_bools("rf-gaze  ", gaze_got, gaze_want))
	line!(Grade.grade_bools("rf-min   ", min_got, min_want))
	line!(Grade.grade_reals("rf-isone ", is_one_got, is_one_want, 0.0))
	Ok({})
}
