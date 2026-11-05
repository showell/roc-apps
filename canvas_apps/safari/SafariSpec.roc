# SafariSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Grade
import Paint
import Rider
import Safari
import Truck
import World

segs : List(World.Segment)
segs = seg_list(0)

# An accumulator loop is linear, where appending a recursive call is quadratic.
seg_list : I64 -> List(World.Segment)
seg_list = |i| seg_list_onto(i, [])

seg_list_onto : I64, List(World.Segment) -> List(World.Segment)
seg_list_onto = |i, acc| (
	if i >= World.route.len().to_i64_wrap() {
		acc
	} else {
		seg_list_onto((i + 1), List.append(acc, World.segment_at(i)))
	}
)

start_got : List(F64)
start_got = [
	Safari.ride_initial.clock,
	Safari.ride_initial.rider.along,
	Safari.ride_initial.rider.across,
	Safari.ride_initial.rider.v,
	Safari.ride_initial.truck.pos,
	Safari.ride_initial.truck.v,
]

start_want : List(F64)
start_want = [0.0, 0.0, 0.0, 0.3, 500.0, 0.3]

start_index_got : List(I64)
start_index_got = [Safari.ride_initial.rider.segment]

start_index_want : List(I64)
start_index_want = [0]

start_flag_got : List(Bool)
start_flag_got = [
	Safari.ride_initial.truck.braking,
	Rider.is_finished(Safari.ride_initial.rider, segs),
]

start_flag_want : List(Bool)
start_flag_want = [False, False]

after_one_step : Safari.Ride
after_one_step = Safari.ride_next(segs, Safari.ride_initial)

after_two_steps : Safari.Ride
after_two_steps = Safari.ride_next(segs, after_one_step)

step_got : List(F64)
step_got = [
	after_one_step.clock,
	after_two_steps.clock,
	(after_two_steps.clock - after_one_step.clock),
]

step_want : List(F64)
step_want = [1.0, 2.0, 1.0]

moved_got : List(Bool)
moved_got = [
	(after_one_step.rider.along > Safari.ride_initial.rider.along),
	(after_one_step.truck.pos > Safari.ride_initial.truck.pos),
	(after_two_steps.rider.along > after_one_step.rider.along),
]

moved_want : List(Bool)
moved_want = [True, True, True]

order_got : List(Bool)
order_got = (
	{
		old_dist = World.route_distance(
			segs,
			{ index: Safari.ride_initial.rider.segment, along: Safari.ride_initial.rider.along },
		)
		new_dist = World.route_distance(
			segs,
			{ index: after_one_step.rider.segment, along: after_one_step.rider.along },
		)
		against_new = Truck.truck_next(
			Safari.ride_initial.truck,
			{
				rider_distance: new_dist,
				world: segs,
				route_length: World.course_length(segs),
			},
		)
		against_old = Truck.truck_next(
			Safari.ride_initial.truck,
			{
				rider_distance: old_dist,
				world: segs,
				route_length: World.course_length(segs),
			},
		)
		[
			(F64.to_bits(after_one_step.truck.pos) == F64.to_bits(against_new.pos)),
			(new_dist > old_dist),
			((F64.to_bits(against_new.pos) == F64.to_bits(against_old.pos)) == False),
		]
	}
)

order_want : List(Bool)
order_want = [True, True, True]

done : Safari.Ride
done = {
	rider: {
		segment: 18,
		along: 400.0,
		across: 0.0,
		yaw: Angle.Turn.radians(0.0),
		v: 0.0,
		tilt: Angle.Lean.radians(0.0),
		heading: Angle.Bearing.radians(0.0),
		gaze_yaw: Angle.Turn.radians(0.0),
		focus: 0.9,
	},
	truck: {
		pos: 9000.0,
		v: 2.0,
		braking: True,
	},
	clock: 12345.0,
}

restart_got : List(F64)
restart_got = (
	{
		r = Safari.ride_next(segs, done)
		[
			r.clock,
			r.rider.along,
			r.rider.v,
			r.truck.pos,
			r.rider.focus,
		]
	}
)

restart_want : List(F64)
restart_want = [0.0, 0.0, 0.3, 500.0, 0.0]

restart_flag_got : List(Bool)
restart_flag_got = [Rider.is_finished(done.rider, segs), Safari.ride_next(segs, done).truck.braking]

restart_flag_want : List(Bool)
restart_flag_want = [True, False]

not_done_got : List(Bool)
not_done_got = [
	(after_one_step.clock > 0.0),
	(Rider.is_finished(after_one_step.rider, segs) == False),
]

not_done_want : List(Bool)
not_done_want = [True, True]

frame : List(Paint.DrawCmd)
frame = Safari.ride_frame(segs, Safari.ride_initial)

frame_got : List(Bool)
frame_got = [
	(frame.len().to_i64_wrap() > 0),
	(Safari.ride_frame(segs, after_one_step).len().to_i64_wrap() > 0),
	((List.get(frame, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).tag >= 0),
	((List.get(frame, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).tag <= 6),
]

frame_want : List(Bool)
frame_want = [True, True, True, True]

sun_got : List(Bool)
# The ride starts facing away from the sun.
sun_got = [Safari.ride_sun(segs, Safari.ride_initial) == OutOfView]

sun_want : List(Bool)
sun_want = [True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "sf-start ",
			got: start_got,
			want: start_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "sf-sindex",
			got: start_index_got,
			want: start_index_want,
		}),
		Grade.bools({
			name: "sf-sflag ",
			got: start_flag_got,
			want: start_flag_want,
		}),
		Grade.reals({
			name: "sf-step  ",
			got: step_got,
			want: step_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "sf-moved ",
			got: moved_got,
			want: moved_want,
		}),
		Grade.bools({
			name: "sf-order ",
			got: order_got,
			want: order_want,
		}),
		Grade.reals({
			name: "sf-restrt",
			got: restart_got,
			want: restart_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "sf-rflag ",
			got: restart_flag_got,
			want: restart_flag_want,
		}),
		Grade.bools({
			name: "sf-notdon",
			got: not_done_got,
			want: not_done_want,
		}),
		Grade.bools({
			name: "sf-frame ",
			got: frame_got,
			want: frame_want,
		}),
		Grade.bools({
			name: "sf-sun   ",
			got: sun_got,
			want: sun_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
