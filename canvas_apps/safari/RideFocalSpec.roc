# RideFocalSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Bike
import lib.DeviceMath
import Gaze
import Grade
import Lens
import Pose
import RideFocal
import World

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

rider : I64, F64, F64, F64 -> Pose.RiderState
rider = |segment, along, tilt, focus| { segment: segment, along: along, across: 0.0, yaw: 0.0, v: Pose.v_base, tilt: tilt, heading: 0.0, gaze_yaw: 0.0, focus: focus }

has_cat_got : List(Bool)
has_cat_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).has_cat]

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
