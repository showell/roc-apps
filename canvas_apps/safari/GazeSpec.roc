# GazeSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Fraction
import Gaze
import Grade
import Pose
import lib.Trig
import VehicleLimits
import World

fixed_got : List(F64)
fixed_got = [
	Gaze.gaze_look_dist,
	Gaze.focus_decay,
	Gaze.pig_gaze_speed.to_metres_a_step(),
	Gaze.pig_gaze_settle_dist,
	(Gaze.gaze_release_angle.to_radians() / Trig.deg),
	(Gaze.gaze_swivel_rate.to_radians() / Trig.deg),
	(Gaze.gaze_return_rate.to_radians() / Trig.deg),
	(Gaze.gaze_return_snap.to_radians() / Trig.deg),
	(Gaze.eyes_on_road_yaw.to_radians() / Trig.deg),
	Gaze.gaze_return_ease,
]

fixed_want : List(F64)
fixed_want = [150.0, 0.0012, 0.2, 25.0, 35.0, 4.0, 0.2, 0.02, 6.0, 0.05]

smooth_got : List(F64)
smooth_got = [
	Gaze.gaze_focus(Fraction.of(0.5)).to_f64(),
]

smooth_want : List(F64)
smooth_want = [0.5]

plain : World.Segment
plain = World.route_segment(0)

distracting : World.Segment
distracting = World.route_segment(2)

rider : F64, F64 -> Pose.RiderState
rider = |along, yaw| {
	segment: World.SegmentIndex.number(2),
	along: along,
	across: 0.0,
	yaw: Angle.Turn.radians(yaw),
	speed: VehicleLimits.v_base,
	tilt: Angle.Lean.radians(0.0),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: Fraction.zero,
}

legs_got : List(Bool)
legs_got = [plain, distracting].map(is_distracting)

## Whether a segment's pigs draw the rider's eye.
is_distracting : World.Segment -> Bool
is_distracting = |seg|
	match seg.pig_attention {
		Distracting => True
		Unnoticed => False
	}

legs_want : List(Bool)
legs_want = [False, True]

looking_got : List(Bool)
looking_got = [
	Gaze.pig_ahead(rider(200.0, 0.0), plain).looking,
	Gaze.pig_ahead(rider(200.0, (10.0 * Trig.deg)), distracting).looking,
	Gaze.pig_ahead(rider(100.0, 0.0), distracting).looking,
	Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking,
	Gaze.pig_ahead(rider(200.0, 0.0), distracting).looking,
	Gaze.no_look.looking,
]

looking_want : List(Bool)
looking_want = [False, False, False, False, True, False]

dist_got : List(F64)
dist_got = [
	Gaze.pig_ahead(rider(200.0, 0.0), distracting).dist,
	Gaze.pig_ahead(rider(100.0, 0.0), distracting).dist,
	Gaze.no_look.dist,
]

dist_want : List(F64)
dist_want = [142.0, 0.0, 0.0]

want_got : List(Bool)
want_got = (
	{
		far = Gaze.desired_gaze(rider(200.0, 0.0), distracting).to_radians()
		near = Gaze.desired_gaze(rider(320.0, 0.0), distracting).to_radians()
		[
			(far > 0.0),
			(near > far),
			(
				F64.to_bits(
					Gaze.desired_gaze(
						rider(200.0, 0.0),
						plain,
					).to_radians(),
				) == F64.to_bits(0.0)
			),
		]
	}
)

want_want : List(Bool)
want_want = [True, True, True]

head : F64, F64 -> Pose.RiderState
head = |gaze_yaw, along| {
	segment: World.SegmentIndex.number(2),
	along: along,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: VehicleLimits.v_base,
	tilt: Angle.Lean.radians(0.0),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(gaze_yaw),
	focus: Fraction.zero,
}

## The gaze one step after `state`, wanting `want` radians.
gaze_after : Pose.RiderState, F64 -> F64
gaze_after = |state, want| Gaze.next_gaze_yaw(state, Angle.Turn.radians(want)).to_radians()

## The focus after the gaze moves to `gaze` radians.
focus_after : Pose.RiderState, F64 -> F64
focus_after = |state, gaze| Gaze.next_focus(state, Angle.Turn.radians(gaze)).to_f64()

swivel_rate : F64
swivel_rate = Gaze.gaze_swivel_rate.to_radians()

return_snap : F64
return_snap = Gaze.gaze_return_snap.to_radians()

swivel_got : List(F64)
swivel_got = [
	(gaze_after(head(0.0, 200.0), 1.0) - swivel_rate),
	(gaze_after(head(0.0, 200.0), (0.0 - 1.0)) + swivel_rate),
	(gaze_after(head(0.0, 200.0), (swivel_rate / 2.0)) - (swivel_rate / 2.0)),
]

swivel_want : List(F64)
swivel_want = [0.0, 0.0, 0.0]

return_got : List(Bool)
return_got = (
	{
		big = gaze_after(head((30.0 * Trig.deg), 200.0), 0.0)
		small = gaze_after(head((2.0 * Trig.deg), 200.0), 0.0)
		[
			(big < (30.0 * Trig.deg)),
			(big > 0.0),
			(small < (2.0 * Trig.deg)),
			(small > 0.0),
			(((30.0 * Trig.deg) - big) > ((2.0 * Trig.deg) - small)),
		]
	}
)

return_want : List(Bool)
return_want = [True, True, True, True, True]

snap_got : List(F64)
snap_got = [
	gaze_after(head(return_snap, 200.0), 0.0),
	gaze_after(head((0.0 - return_snap), 200.0), 0.0),
	gaze_after(head(0.0, 200.0), 0.0),
]

snap_want : List(F64)
snap_want = [0.0, 0.0, 0.0]

rider_with_focus : F64, F64 -> Pose.RiderState
rider_with_focus = |focus, gaze_yaw| {
	segment: World.SegmentIndex.number(2),
	along: 200.0,
	across: 0.0,
	yaw: Angle.Turn.radians(0.0),
	speed: VehicleLimits.v_base,
	tilt: Angle.Lean.radians(0.0),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(gaze_yaw),
	focus: Fraction.of(focus),
}

focus_got : List(Bool)
focus_got = (
	{
		rising = focus_after(rider_with_focus(0.0, (20.0 * Trig.deg)), (20.0 * Trig.deg))
		held = focus_after(rider_with_focus(0.9, (1.0 * Trig.deg)), (1.0 * Trig.deg))
		easing = focus_after(rider_with_focus(0.9, 0.0), 0.0)
		[
			(rising > 0.0),
			(held >= 0.9),
			(easing < 0.9),
			(easing > 0.0),
		]
	}
)

focus_want : List(Bool)
focus_want = [True, True, True, True]

focus_ends_got : List(F64)
focus_ends_got = [
	focus_after(rider_with_focus(0.0, 0.0), 0.0),
	focus_after(rider_with_focus(0.0, (90.0 * Trig.deg)), (90.0 * Trig.deg)),
]

focus_ends_want : List(F64)
focus_ends_want = [0.0, 1.0]

gawk_got : List(Bool)
gawk_got = [
	Gaze.gawk_engaged(rider(200.0, 0.0), plain),
	Gaze.gawk_engaged(rider(100.0, 0.0), distracting),
	Gaze.gawk_engaged(rider(200.0, 0.0), distracting),
	Gaze.gawk_engaged(rider(341.0, 0.0), distracting),
]

gawk_want : List(Bool)
gawk_want = [False, False, True, True]

outlast_got : List(Bool)
outlast_got = (
	{
		looks = Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking
		[(looks == False), Gaze.gawk_engaged(rider(341.0, 0.0), distracting)]
	}
)

outlast_want : List(Bool)
outlast_want = [True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gz-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "gz-smooth",
			got: smooth_got,
			want: smooth_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gz-legs  ",
			got: legs_got,
			want: legs_want,
		}),
		Grade.bools({
			name: "gz-look  ",
			got: looking_got,
			want: looking_want,
		}),
		Grade.reals({
			name: "gz-dist  ",
			got: dist_got,
			want: dist_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gz-want  ",
			got: want_got,
			want: want_want,
		}),
		Grade.reals({
			name: "gz-swivel",
			got: swivel_got,
			want: swivel_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gz-return",
			got: return_got,
			want: return_want,
		}),
		Grade.reals({
			name: "gz-snap  ",
			got: snap_got,
			want: snap_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gz-focus ",
			got: focus_got,
			want: focus_want,
		}),
		Grade.reals({
			name: "gz-fends ",
			got: focus_ends_got,
			want: focus_ends_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "gz-gawk  ",
			got: gawk_got,
			want: gawk_want,
		}),
		Grade.bools({
			name: "gz-outlst",
			got: outlast_got,
			want: outlast_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
