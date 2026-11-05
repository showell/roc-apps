# RideInstantSpec -- originally emitted from Codex by rocemit; the Roc is the
# program now and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Clock
import Fraction
import Distance
import Grade
import RideInstant
import Rider
import Speed
import Truck
import World
import ShapeRead
import lib.Shapes

segs : List(World.Segment)
segs = seg_list(0)

# An accumulator loop is linear, where appending a recursive call is quadratic.
seg_list : U32 -> List(World.Segment)
seg_list = |i| seg_list_onto(i, [])

seg_list_onto : U32, List(World.Segment) -> List(World.Segment)
seg_list_onto = |i, acc| (
	if i >= World.route.len().to_u32_wrap() {
		acc
	} else {
		seg_list_onto((i + 1), List.append(acc, World.route_segment(i)))
	}
)

start_got : List(F64)
start_got = [
	RideInstant.initial.clock.to_f64(),
	RideInstant.initial.rider.along,
	RideInstant.initial.rider.across,
	RideInstant.initial.rider.speed.to_metres_a_step(),
	RideInstant.initial.truck.route_position.to_metres(),
	RideInstant.initial.truck.speed.to_metres_a_step(),
]

start_want : List(F64)
start_want = [0.0, 0.0, 0.0, 0.3, 500.0, 0.3]

start_index_got : List(I64)
start_index_got = [RideInstant.initial.rider.segment.to_i64()]

start_index_want : List(I64)
start_index_want = [0]

start_flag_got : List(Bool)
start_flag_got = [
	RideInstant.initial.truck.brake_lights == On,
	Rider.is_finished(RideInstant.initial.rider, segs),
]

start_flag_want : List(Bool)
start_flag_want = [False, False]

after_one_step : RideInstant
after_one_step = RideInstant.next(segs, RideInstant.initial)

after_two_steps : RideInstant
after_two_steps = RideInstant.next(segs, after_one_step)

step_got : List(F64)
step_got = [
	after_one_step.clock.to_f64(),
	after_two_steps.clock.to_f64(),
	(after_two_steps.clock.to_f64() - after_one_step.clock.to_f64()),
]

step_want : List(F64)
step_want = [1.0, 2.0, 1.0]

moved_got : List(Bool)
moved_got = [
	(after_one_step.rider.along > RideInstant.initial.rider.along),
	(after_one_step.truck.route_position > RideInstant.initial.truck.route_position),
	(after_two_steps.rider.along > after_one_step.rider.along),
]

moved_want : List(Bool)
moved_want = [True, True, True]

order_got : List(Bool)
order_got = (
	{
		old_dist = World.distance_along_route(
			segs,
			{ index: RideInstant.initial.rider.segment, along: RideInstant.initial.rider.along },
		)
		new_dist = World.distance_along_route(
			segs,
			{ index: after_one_step.rider.segment, along: after_one_step.rider.along },
		)
		against_new = Truck.advance(
			RideInstant.initial.truck,
			{
				rider_distance: new_dist,
				world: segs,
				route_length: World.route_length(segs),
			},
		)
		against_old = Truck.advance(
			RideInstant.initial.truck,
			{
				rider_distance: old_dist,
				world: segs,
				route_length: World.route_length(segs),
			},
		)
		new_position = against_new.route_position
		old_position = against_old.route_position
		[
			(after_one_step.truck.route_position == new_position),
			(new_dist > old_dist),
			(new_position != old_position),
		]
	}
)

order_want : List(Bool)
order_want = [True, True, True]

done : RideInstant
done = {
	rider: {
		segment: World.SegmentIndex.number(18),
		along: 400.0,
		across: 0.0,
		yaw: Angle.Turn.radians(0.0),
		speed: Speed.at_rest,
		tilt: Angle.Lean.radians(0.0),
		heading: Angle.Bearing.radians(0.0),
		gaze_yaw: Angle.Turn.radians(0.0),
		focus: Fraction.of(0.9),
	},
	truck: {
		route_position: Distance.metres(9000.0),
		speed: Speed.metres_a_step(2.0),
		brake_lights: On,
	},
	clock: Clock.at_step(12345),
}

restart_got : List(F64)
restart_got = (
	{
		instant = RideInstant.next(segs, done)
		[
			instant.clock.to_f64(),
			instant.rider.along,
			instant.rider.speed.to_metres_a_step(),
			instant.truck.route_position.to_metres(),
			instant.rider.focus.to_f64(),
		]
	}
)

restart_want : List(F64)
restart_want = [0.0, 0.0, 0.3, 500.0, 0.0]

restart_flag_got : List(Bool)
restart_flag_got = [
	Rider.is_finished(done.rider, segs),
	RideInstant.next(segs, done).truck.brake_lights == On,
]

restart_flag_want : List(Bool)
restart_flag_want = [True, False]

not_done_got : List(Bool)
not_done_got = [
	(after_one_step.clock != Clock.start),
	(Rider.is_finished(after_one_step.rider, segs) == False),
]

not_done_want : List(Bool)
not_done_want = [True, True]

frame : List(Shapes.Shape)
frame = RideInstant.frame(segs, RideInstant.initial)

frame_got : List(Bool)
frame_got = [
	(frame.len().to_i64_wrap() > 0),
	(RideInstant.frame(segs, after_one_step).len().to_i64_wrap() > 0),
	(ShapeRead.pts_of(frame.first() ?? crash "RideInstantSpec: a frame draws").len() >= 6),
]

frame_want : List(Bool)
frame_want = [True, True, True]

sun_got : List(Bool)
# The ride starts facing away from the sun.
sun_got = [RideInstant.sun(segs, RideInstant.initial) == OutOfView]

sun_want : List(Bool)
sun_want = [True]

## A clock with the sun behind the mountains.
after_sunset : Clock
after_sunset = Clock.at_step(5700)

## The truck's lights at `clock`, with its brake lights left as given.
lights_at : { clock : Clock, brake_lights : [On, Off] } -> Truck.Lights
lights_at = |{ clock, brake_lights }|
	RideInstant.truck_lights({
		..RideInstant.initial,
		truck: { ..RideInstant.initial.truck, brake_lights },
		clock,
	})

lights_got : List(Bool)
lights_got = [
	lights_at({ clock: Clock.start, brake_lights: Off }) == { headlights: Off, brake_lights: Off },
	lights_at({ clock: Clock.start, brake_lights: On }) == { headlights: Off, brake_lights: On },
	lights_at({ clock: after_sunset, brake_lights: Off }) == { headlights: On, brake_lights: Off },
	lights_at({ clock: after_sunset, brake_lights: On }) == { headlights: On, brake_lights: On },
]

lights_want : List(Bool)
lights_want = [True, True, True, True]

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
		Grade.bools({
			name: "sf-lights",
			got: lights_got,
			want: lights_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
