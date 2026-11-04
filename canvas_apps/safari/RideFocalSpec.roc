## These are RideFocal's checks: the lens at rest, for a lean, for a cat
## waiting ahead, for a look aside, and for a lean and a look together.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Bike
import lib.DeviceMath
import Gaze
import Grade
import Lens
import Pose
import RideFocal
import World

segs : List(World.Segment)
segs = [0, 1, 2].map(World.segment_at)

## The bike's greatest lean, in radians.
max_lean : F64
max_lean = Bike.max_lean.to_radians()

# A rider at the start of the first segment, upright and looking ahead.
upright : Pose.RiderState
upright = {
	segment: 0,
	along: 0.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	v: Pose.v_base,
	tilt: Angle.Lean.radians(0.0),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: 0.0,
}

# A rider 120 m along a segment: near enough to its cat, if it has one, to
# notice it.
near_cat_on : I64 -> Pose.RiderState
near_cat_on = |segment| { ..upright, segment, along: 120.0 }

has_cat_got : List(Bool)
has_cat_got = segs.take_first(2).map(has_cat)

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.cat {
		Waits(_) => True
		NoCat => False
	}

has_cat_want : List(Bool)
has_cat_want = [False, True]

idle_got : List(F64)
idle_got = [
	(RideFocal.ride_focal(segs, upright) - Lens.focal),
	RideFocal.cat_attention(segs, upright),
	Gaze.gaze_focus(0.0),
	(Lens.cam_focal({ lean_frac: 0.0, attention: 0.0 }) - Lens.focal),
]

idle_want : List(F64)
idle_want = [0.0, 0.0, 0.0, 0.0]

leaned : F64 -> F64
leaned = |tilt| RideFocal.ride_focal(segs, { ..upright, tilt: Angle.Lean.radians(tilt) })

lean_got : List(Bool)
lean_got = [(leaned((max_lean / 2.0)) < leaned(0.0)), (leaned(max_lean) < leaned((max_lean / 2.0))), (leaned((0.0 - max_lean)) < leaned(0.0)), (leaned(0.0) <= Lens.focal)]

lean_want : List(Bool)
lean_want = [True, True, True, True]

clamp_got : List(F64)
clamp_got = [(leaned(max_lean) - leaned((0.0 - max_lean))), (leaned((max_lean * 2.0)) - leaned(max_lean)), (leaned((max_lean * 10.0)) - leaned(max_lean))]

clamp_want : List(F64)
clamp_want = [0.0, 0.0, 0.0]

cat_got : List(Bool)
cat_got = [
	(RideFocal.cat_attention(segs, near_cat_on(1)) > 0.0),
	(RideFocal.cat_attention(segs, { ..upright, segment: 1 }) > 0.0),
	(RideFocal.cat_attention(segs, near_cat_on(0)) > 0.0),
	(RideFocal.ride_focal(segs, near_cat_on(1)) < RideFocal.ride_focal(segs, near_cat_on(0))),
]

cat_want : List(Bool)
cat_want = [True, False, False, True]

gaze_got : List(Bool)
gaze_got = [
	(RideFocal.ride_focal(segs, { ..upright, focus: 1.0 }) < RideFocal.ride_focal(segs, upright)),
	(RideFocal.ride_focal(segs, { ..upright, focus: 1.0 }) < RideFocal.ride_focal(segs, { ..upright, focus: 0.5 })),
	(Gaze.gaze_focus(1.0) > Gaze.gaze_focus(0.0)),
]

gaze_want : List(Bool)
gaze_want = [True, True, True]

both : F64
both = RideFocal.ride_focal(segs, { ..upright, tilt: Bike.max_lean, focus: 1.0 })

lean_only : F64
lean_only = RideFocal.ride_focal(segs, { ..upright, tilt: Bike.max_lean })

gaze_only : F64
gaze_only = RideFocal.ride_focal(segs, { ..upright, focus: 1.0 })

min_got : List(Bool)
min_got = [(both <= lean_only), (both <= gaze_only), (F64.to_bits(both) == F64.to_bits(DeviceMath.real_min(lean_only, gaze_only))), ((lean_only + gaze_only) > both)]

min_want : List(Bool)
min_want = [True, True, True, True]

is_one_got : List(F64)
is_one_got = [(both - DeviceMath.real_min(lean_only, gaze_only)), (Lens.cam_focal({ lean_frac: 1.0, attention: 0.0 }) - lean_only)]

is_one_want : List(F64)
is_one_want = [0.0, 0.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "rf-hascat",
			got: has_cat_got,
			want: has_cat_want,
		}),
		Grade.reals({
			name: "rf-idle  ",
			got: idle_got,
			want: idle_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "rf-lean  ",
			got: lean_got,
			want: lean_want,
		}),
		Grade.reals({
			name: "rf-clamp ",
			got: clamp_got,
			want: clamp_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "rf-cat   ",
			got: cat_got,
			want: cat_want,
		}),
		Grade.bools({
			name: "rf-gaze  ",
			got: gaze_got,
			want: gaze_want,
		}),
		Grade.bools({
			name: "rf-min   ",
			got: min_got,
			want: min_want,
		}),
		Grade.reals({
			name: "rf-isone ",
			got: is_one_got,
			want: is_one_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
