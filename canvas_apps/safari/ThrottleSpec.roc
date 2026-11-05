# ThrottleSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Arc
import Grade
import Pose
import Throttle
import lib.Trig
import VehicleLimits
import World

## The lean the throttle holds off at, in radians.
tilt_hold : F64
tilt_hold = Throttle.tilt_hold.to_radians()

fixed_got : List(F64)
fixed_got = [
	tilt_hold,
	Throttle.brake_decay,
	(tilt_hold / Trig.deg),
]

fixed_want : List(F64)
fixed_want = [0.03490658503988659, 20.0, 2.0]

seg : World.Segment
seg = World.segment_at(0)

## Where a test rider is on segment 0 and how it moves.
RiderSpot : {
	across : F64,
	along : F64,
	speed : F64,
	tilt_radians : F64,
}

rider_at : RiderSpot -> Pose.RiderState
rider_at = |
	{
		across,
		along,
		speed: v,
		tilt_radians: tilt,
	},
| {
	segment: World.SegmentIndex.number(0),
	along: along,
	across: across,
	yaw: Angle.Turn.radians(0.0),
	v: v,
	tilt: Angle.Lean.radians(tilt),
	heading: Angle.Bearing.radians(0.0),
	gaze_yaw: Angle.Turn.radians(0.0),
	focus: 0.0,
}

## A test rider on the centre line.
CentredRider : {
	along : F64,
	speed : F64,
	tilt_radians : F64,
}

rider : CentredRider -> Pose.RiderState
rider = |
	{
		along,
		speed,
		tilt_radians,
	},
| rider_at({
	across: 0.0,
	along,
	speed,
	tilt_radians,
})

corner_got : List(F64)
corner_got = [
	Throttle.corner_brake(
		rider({
			along: 498.4,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			offered_accel: 0.01,
		},
	),
	Throttle.corner_brake(
		rider({
			along: 600.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			offered_accel: 0.01,
		},
	),
	Throttle.corner_brake(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			offered_accel: (0.0 - 5.0),
		},
	),
]

corner_want : List(F64)
corner_want = [
	0.0,
	0.0,
	(-5.0),
]

corner_min_got : List(Bool)
corner_min_got = [
	(
		Throttle.corner_brake(
			rider({
				along: 0.0,
				speed: 0.3,
				tilt_radians: 0.0,
			}),
			{
				road_segment: seg,
				exit_speed: 0.222,
				offered_accel: 0.01,
			},
		) <= 0.01
	),
	(
		Throttle.corner_brake(
			rider({
				along: 0.0,
				speed: 0.3,
				tilt_radians: 0.0,
			}),
			{
				road_segment: seg,
				exit_speed: 0.222,
				offered_accel: (0.0 - 5.0),
			},
		) <= (0.0 - 5.0)
	),
	(
		Throttle.corner_brake(
			rider({
				along: 0.0,
				speed: 2.0,
				tilt_radians: 0.0,
			}),
			{
				road_segment: seg,
				exit_speed: 0.222,
				offered_accel: 0.01,
			},
		) < Throttle.corner_brake(
			rider({
				along: 0.0,
				speed: 0.3,
				tilt_radians: 0.0,
			}),
			{
				road_segment: seg,
				exit_speed: 0.222,
				offered_accel: 0.01,
			},
		)
	),
]

corner_min_want : List(Bool)
corner_min_want = [True, True, True]

cat_seg : World.Segment
cat_seg = World.segment_at(1)

cat_got : List(F64)
cat_got = [
	Throttle.cat_gate(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			offered_accel: 0.01,
		},
	),
	Throttle.cat_gate(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			offered_accel: (0.0 - 5.0),
		},
	),
	Throttle.cat_gate(
		rider({
			along: 120.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: cat_seg,
			offered_accel: 0.01,
		},
	),
	Throttle.cat_gate(
		rider({
			along: 120.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: cat_seg,
			offered_accel: (0.0 - 5.0),
		},
	),
	Throttle.cat_gate(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: cat_seg,
			offered_accel: 0.01,
		},
	),
]

cat_want : List(F64)
cat_want = [
	0.01,
	(-5.0),
	0.0,
	(-5.0),
	0.01,
]

outcome : Arc.Shoulder -> Arc.ArcOutcome
outcome = |sh| {
	shoulder: sh,
	forward: 10.0,
	crossed: False,
	end_across: 0.0,
	frames: 40.0,
}

road_got : List(Bool)
road_got = [
	Throttle.has_stayed_on_road(outcome(ShoulderNone)),
	Throttle.has_stayed_on_road(outcome(ShoulderLeft)),
	Throttle.has_stayed_on_road(outcome(ShoulderRight)),
]

road_want : List(Bool)
road_want = [True, False, False]

soon : Arc.ArcOutcome
soon = {
	shoulder: ShoulderLeft,
	forward: 10.0,
	crossed: False,
	end_across: 0.0,
	frames: 2.0,
}

brake_got : List(Bool)
brake_got = (
	{
		far = Throttle.shoulder_brake_at(
			rider({
				along: 0.0,
				speed: 1.0,
				tilt_radians: 0.0,
			}),
			{
				arc_outcome: outcome(ShoulderLeft),
				offered_accel: 0.01,
			},
		)
		near_off = Throttle.shoulder_brake_at(
			rider({
				along: 0.0,
				speed: 1.0,
				tilt_radians: 0.0,
			}),
			{
				arc_outcome: soon,
				offered_accel: 0.01,
			},
		)
		already = Throttle.shoulder_brake_at(
			rider({
				along: 0.0,
				speed: 1.0,
				tilt_radians: 0.0,
			}),
			{
				arc_outcome: outcome(ShoulderLeft),
				offered_accel: (0.0 - 9.0),
			},
		)
		[
			(far < 0.0),
			(far > near_off),
			(already < (0.0 - 8.999)),
		]
	}
)

brake_want : List(Bool)
brake_want = [True, True, True]

instant : Arc.ArcOutcome
instant = {
	shoulder: ShoulderLeft,
	forward: 0.0,
	crossed: False,
	end_across: 0.0,
	frames: 0.0,
}

zero_frames_got : List(Bool)
zero_frames_got = [
	(
		Throttle.shoulder_brake_at(
			rider({
				along: 0.0,
				speed: 1.0,
				tilt_radians: 0.0,
			}),
			{
				arc_outcome: instant,
				offered_accel: 0.01,
			},
		) < 0.0
	),
]

zero_frames_want : List(Bool)
zero_frames_want = [True]

clamp_got : List(F64)
clamp_got = [
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: 1.0,
			is_near_end: False,
		},
	),
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: 3.0,
			is_near_end: False,
		},
	),
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: (0.0 - 1.0),
			is_near_end: False,
		},
	),
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: 0.1,
			is_near_end: True,
		},
	),
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: 0.5,
			is_near_end: True,
		},
	),
	Throttle.clamp_v(
		rider({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.0,
		}),
		{
			road_segment: seg,
			exit_speed: 0.222,
			next_speed: 0.1,
			is_near_end: False,
		},
	),
]

clamp_want : List(F64)
clamp_want = [1.0, 2.5, 0.0, 0.222, 0.5, 0.1]

decide : CentredRider -> F64
decide = |centred_rider| Throttle.get_forward_accel_decel(rider(centred_rider), seg)

whole_got : List(F64)
whole_got = [
	decide({
		along: 0.0,
		speed: 0.3,
		tilt_radians: 0.0,
	}),
	decide({
		along: 0.0,
		speed: VehicleLimits.v_max,
		tilt_radians: 0.0,
	}),
	decide({
		along: 0.0,
		speed: 0.0,
		tilt_radians: 0.0,
	}),
]

whole_want : List(F64)
whole_want = [0.01, 0.0, 0.01]

wide : F64 -> F64
wide = |tilt| Throttle.get_forward_accel_decel(
	rider_at({
		across: 100.0,
		along: 0.0,
		speed: 0.3,
		tilt_radians: tilt,
	}),
	seg,
)

tilt_got : List(F64)
tilt_got = [
	wide((0.0 - 0.001)),
	wide((0.0 - tilt_hold)),
	wide(((0.0 - tilt_hold) - 0.5)),
]

tilt_want : List(F64)
tilt_want = [0.01, 0.0, 0.0]

compose_got : List(Bool)
compose_got = [
	(
		decide({
			along: 0.0,
			speed: 0.3,
			tilt_radians: (tilt_hold - 0.001),
		}) < 0.0
	),
	(
		decide({
			along: 0.0,
			speed: 0.3,
			tilt_radians: 0.001,
		}) > 0.0
	),
	(
		decide({
			along: 0.0,
			speed: 0.3,
			tilt_radians: (0.0 - (tilt_hold - 0.001)),
		}) < 0.0
	),
]

compose_want : List(Bool)
compose_want = [True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "th-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "th-corner",
			got: corner_got,
			want: corner_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "th-cmin  ",
			got: corner_min_got,
			want: corner_min_want,
		}),
		Grade.reals({
			name: "th-cat   ",
			got: cat_got,
			want: cat_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "th-road  ",
			got: road_got,
			want: road_want,
		}),
		Grade.bools({
			name: "th-brake ",
			got: brake_got,
			want: brake_want,
		}),
		Grade.bools({
			name: "th-zero  ",
			got: zero_frames_got,
			want: zero_frames_want,
		}),
		Grade.reals({
			name: "th-clamp ",
			got: clamp_got,
			want: clamp_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "th-whole ",
			got: whole_got,
			want: whole_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "th-tilt  ",
			got: tilt_got,
			want: tilt_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.bools({
			name: "th-comp  ",
			got: compose_got,
			want: compose_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
