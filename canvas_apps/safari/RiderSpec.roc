# RiderSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import lib.DeviceMath
import Grade
import LeanSearch
import Pose
import Rider
import Scenery
import Speed
import Throttle
import VehicleLimits
import World

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

seg : World.Segment
seg = World.route_segment(0)

## Where a test rider is on segment 0 and how it moves.
RiderSpot : {
	along : F64,
	across : F64,
	speed : Speed,
	tilt_radians : F64,
}

rider : RiderSpot -> Pose.RiderState
rider = |
	{
		along,
		across,
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

step_got : List(Bool)
step_got = (
	{
		d = Rider.decide(
			rider({
				along: 0.0,
				across: 0.0,
				speed: Pose.v_base,
				tilt_radians: 0.0,
			}),
			seg,
		)
		held = Rider.decide(
			rider({
				along: 0.0,
				across: 0.0,
				speed: Pose.v_base,
				tilt_radians: 0.5,
			}),
			seg,
		)
		[
			(d.tilt_step.abs() <= LeanSearch.max_tilt_correction),
			(held.tilt_step.abs() <= LeanSearch.max_tilt_correction),
			(d.accel <= (VehicleLimits.a_accel + F64.from_bits(4517329193108106637))),
		]
	}
)

step_want : List(Bool)
step_want = [True, True, True]

leaned_got : List(Bool)
leaned_got = (
	{
		d = Rider.decide(
			rider({
				along: 0.0,
				across: 0.0,
				speed: Pose.v_base,
				tilt_radians: 0.0,
			}),
			seg,
		)
		same = Throttle.get_forward_accel_decel(
			Pose.with_tilt(
				rider({
					along: 0.0,
					across: 0.0,
					speed: Pose.v_base,
					tilt_radians: 0.0,
				}),
				Angle.upright.plus(d.tilt_step),
			),
			seg,
		)
		[(F64.to_bits(d.accel) == F64.to_bits(same))]
	}
)

leaned_want : List(Bool)
leaned_want = [True]

at_seam : Pose.RiderState
at_seam = {
	segment: World.SegmentIndex.number(0),
	along: 499.0,
	across: 0.5,
	yaw: Angle.Turn.radians(0.1),
	v: Speed.metres_a_step(1.25),
	tilt: Angle.Lean.radians(0.05),
	heading: Angle.Bearing.radians(0.7),
	gaze_yaw: Angle.Turn.radians(0.3),
	focus: 0.4,
}

crossed : Pose.RiderState
crossed = Rider.rider_state_for_next_segment(at_seam, segs)

carry_got : List(F64)
carry_got = [
	crossed.v.to_metres_a_step(),
	crossed.tilt.to_radians(),
	crossed.focus,
	crossed.gaze_yaw.to_radians(),
]

carry_want : List(F64)
carry_want = [1.25, 0.05, 0.4, 0.0]

turn_got : List(F64)
turn_got = [
	(crossed.heading.to_radians() - 0.7),
	(crossed.yaw.to_radians() - (0.1 - seg.exit_turn.to_radians())),
]

turn_want : List(F64)
turn_want = [0.0, 0.0]

index_got : List(I64)
index_got = [crossed.segment.to_i64(), next_of(seg)]

## The segment after one that continues.
next_of : World.Segment -> I64
next_of = |segment|
	match segment.ending {
		Continues({ next }) => next.to_i64()
		Terminates => crash "RiderSpec.next_of: segment 0 continues"
	}

index_want : List(I64)
index_want = [1, 1]

early_got : List(Bool)
early_got = (
	{
		far = Rider.rider_state_for_next_segment(
			rider({
				along: 100.0,
				across: 0.0,
				speed: Pose.v_base,
				tilt_radians: 0.0,
			}),
			segs,
		)
		[(DeviceMath.real_abs(far.across) >= (Scenery.lane_width / 2.0))]
	}
)

early_want : List(Bool)
early_want = [True]

resolve_got : List(I64)
resolve_got = [
	Rider.resolve_cross(
		rider({
			along: 100.0,
			across: 0.0,
			speed: Pose.v_base,
			tilt_radians: 0.0,
		}),
		segs,
	).segment.to_i64(),
	Rider.resolve_cross(
		rider({
			along: 499.0,
			across: 0.0,
			speed: Pose.v_base,
			tilt_radians: 0.0,
		}),
		segs,
	).segment.to_i64(),
]

resolve_want : List(I64)
resolve_want = [0, 1]

last_seg : World.Segment
last_seg = World.route_segment(18)

## Whether the route ends with a segment.
is_route_end : World.Segment -> Bool
is_route_end = |segment|
	match segment.ending {
		Continues(_) => False
		Terminates => True
	}

clamped_at_finish : F64, F64 -> Pose.RiderState
clamped_at_finish = |along, v| Rider.finish_clamp(
	{
		segment: World.SegmentIndex.number(0),
		along: along,
		across: 0.0,
		yaw: Angle.Turn.radians(0.0),
		v: Speed.metres_a_step(v),
		tilt: Angle.Lean.radians(0.0),
		heading: Angle.Bearing.radians(0.0),
		gaze_yaw: Angle.Turn.radians(0.0),
		focus: 0.0,
	},
	last_seg,
)

finish_got : List(F64)
finish_got = [
	clamped_at_finish(300.0, 0.5).along,
	clamped_at_finish(300.0, 0.5).v.to_metres_a_step(),
	clamped_at_finish(310.0, 0.5).along,
	clamped_at_finish(310.0, 0.5).v.to_metres_a_step(),
	clamped_at_finish(290.0, 0.05).along,
	clamped_at_finish(290.0, 0.05).v.to_metres_a_step(),
	clamped_at_finish(290.0, 0.5).along,
	clamped_at_finish(290.0, 0.5).v.to_metres_a_step(),
	clamped_at_finish(100.0, 0.05).along,
	clamped_at_finish(100.0, 0.05).v.to_metres_a_step(),
]

finish_want : List(F64)
finish_want = [300.0, 0.0, 300.0, 0.0, 300.0, 0.0, 290.0, 0.5, 100.0, 0.05]

done_got : List(Bool)
done_got = (
	{
		at_end = {
			segment: World.SegmentIndex.number(0),
			along: 300.0,
			across: 0.0,
			yaw: Angle.Turn.radians(0.0),
			v: Speed.at_rest,
			tilt: Angle.Lean.radians(0.0),
			heading: Angle.Bearing.radians(0.0),
			gaze_yaw: Angle.Turn.radians(0.0),
			focus: 0.0,
		}
		short = {
			segment: World.SegmentIndex.number(0),
			along: 299.0,
			across: 0.0,
			yaw: Angle.Turn.radians(0.0),
			v: Speed.at_rest,
			tilt: Angle.Lean.radians(0.0),
			heading: Angle.Bearing.radians(0.0),
			gaze_yaw: Angle.Turn.radians(0.0),
			focus: 0.0,
		}
		[
			Rider.is_finished(at_end, [World.route_segment(18)]),
			Rider.is_finished(short, [World.route_segment(18)]),
			is_route_end(last_seg),
			Rider.is_finished(
				rider({
					along: 499.0,
					across: 0.0,
					speed: Pose.v_base,
					tilt_radians: 0.0,
				}),
				segs,
			),
		]
	}
)

done_want : List(Bool)
done_want = [True, False, True, False]

next : Pose.RiderState
next = Rider.get_next_rider_state(
	rider({
		along: 0.0,
		across: 0.0,
		speed: Pose.v_base,
		tilt_radians: 0.0,
	}),
	segs,
)

frame_got : List(Bool)
frame_got = [
	(next.along > 0.0),
	(next.v > Speed.at_rest),
	(next.segment == World.SegmentIndex.first),
	(DeviceMath.real_abs(next.across) < (Scenery.lane_width / 2.0)),
	(next.v <= VehicleLimits.v_max),
]

frame_want : List(Bool)
frame_want = [True, True, True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "rd-step  ",
			got: step_got,
			want: step_want,
		}),
		Grade.bools({
			name: "rd-leaned",
			got: leaned_got,
			want: leaned_want,
		}),
		Grade.reals({
			name: "rd-carry ",
			got: carry_got,
			want: carry_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "rd-turn  ",
			got: turn_got,
			want: turn_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "rd-index ",
			got: index_got,
			want: index_want,
		}),
		Grade.bools({
			name: "rd-early ",
			got: early_got,
			want: early_want,
		}),
		Grade.ints({
			name: "rd-resolv",
			got: resolve_got,
			want: resolve_want,
		}),
		Grade.reals({
			name: "rd-finish",
			got: finish_got,
			want: finish_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "rd-done  ",
			got: done_got,
			want: done_want,
		}),
		Grade.bools({
			name: "rd-frame ",
			got: frame_got,
			want: frame_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
