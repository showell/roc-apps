## These are Truck's checks: its constants, its schedule, the turns it finds,
## and how it moves when free and when braking.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Truck
import VehicleLimits
import World

fixed_got : List(F64)
fixed_got = [
	Truck.start_lead,
	Truck.finish_lead,
	Truck.turn_caution,
	Truck.brake_distance,
	Truck.top_speed,
]

fixed_want : List(F64)
fixed_want = [500.0, 100.0, 0.8, 60.0, 2.75]

ratio_got : List(F64)
ratio_got = [
	Truck.chase_acceleration,
	Truck.top_speed,
	(Truck.chase_acceleration / VehicleLimits.a_accel),
	(Truck.top_speed / VehicleLimits.v_max),
]

ratio_want : List(F64)
ratio_want = [0.011, 2.75, 1.1, 1.1]

initial_got : List(F64)
initial_got = [Truck.initial_truck.route_position, Truck.initial_truck.speed]

initial_want : List(F64)
initial_want = [500.0, 0.3]

initial_flag_got : List(Bool)
initial_flag_got = [Truck.initial_truck.is_braking]

initial_flag_want : List(Bool)
initial_flag_want = [False]

sched_got : List(F64)
sched_got = [
	Truck.scheduled_position({ rider_distance: 0.0, route_length: 1000.0 }),
	Truck.scheduled_position({ rider_distance: 250.0, route_length: 1000.0 }),
	Truck.scheduled_position({ rider_distance: 500.0, route_length: 1000.0 }),
	Truck.scheduled_position({ rider_distance: 1000.0, route_length: 1000.0 }),
	(Truck.scheduled_position({ rider_distance: 1000.0, route_length: 1000.0 }) - 1000.0),
	(Truck.scheduled_position({ rider_distance: 0.0, route_length: 1000.0 }) - 0.0),
]

sched_want : List(F64)
sched_want = [500.0, 650.0, 800.0, 1100.0, 100.0, 500.0]

one_seg : List(World.Segment)
one_seg = [World.segment_at(0)]

turn_dist : List(World.Segment), F64 -> F64
turn_dist = |segs, route_position| (
	match Truck.next_turn(segs, route_position) {
		TurnAhead(t) => t.distance
		NoTurnAhead => (0.0 - 1.0)
	}
)

turn_v : List(World.Segment), F64 -> F64
turn_v = |segs, route_position| (
	match Truck.next_turn(segs, route_position) {
		TurnAhead(t) => t.turn_speed
		NoTurnAhead => (0.0 - 1.0)
	}
)

turn_got : List(F64)
turn_got = [
	turn_dist(one_seg, 0.0),
	turn_dist(one_seg, 450.0),
	turn_dist(one_seg, 499.0),
	turn_v(one_seg, 0.0),
	turn_v(one_seg, 450.0),
	VehicleLimits.turn_speed(
		(
			List.get(
				one_seg,
				I64.to_u64_wrap(0),
			) ?? crash ("list-at out of range")
		).exit_angle,
	),
]

turn_want : List(F64)
turn_want = [500.0, 50.0, 1.0, 0.222, 0.222, 0.222]

none_got : List(F64)
none_got = [
	turn_dist(one_seg, 500.0),
	turn_dist(one_seg, 900.0),
	turn_dist([World.segment_at(18)], 0.0),
	turn_dist([], 0.0),
]

none_want : List(F64)
none_want = [
	(-1.0),
	(-1.0),
	(-1.0),
	(-1.0),
]

two_seg : List(World.Segment)
two_seg = [World.segment_at(0), World.segment_at(1)]

chain_got : List(F64)
chain_got = [
	turn_dist(two_seg, 0.0),
	turn_dist(two_seg, 500.0),
	turn_dist(two_seg, 800.0),
	turn_dist(two_seg, 820.0),
]

chain_want : List(F64)
chain_want = [
	500.0,
	320.0,
	20.0,
	(-1.0),
]

free : Truck.TruckState
free = Truck.advance(
	{
		route_position: 100.0,
		speed: 0.3,
		is_braking: False,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

free_got : List(F64)
free_got = [
	free.speed,
	free.route_position,
	(free.speed - 0.3),
]

free_want : List(F64)
free_want = [0.311, 100.311, 0.011]

ahead : Truck.TruckState
ahead = Truck.advance(
	{
		route_position: 600.0,
		speed: 0.5,
		is_braking: False,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

behind : Truck.TruckState
behind = Truck.advance(
	{
		route_position: 400.0,
		speed: 0.5,
		is_braking: False,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

ahead_got : List(F64)
ahead_got = [
	ahead.speed,
	ahead.route_position,
	(behind.speed - ahead.speed),
]

ahead_want : List(F64)
ahead_want = [0.5, 600.5, 0.011]

capped : Truck.TruckState
capped = Truck.advance(
	{
		route_position: 100.0,
		speed: Truck.top_speed,
		is_braking: False,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

capped_got : List(F64)
capped_got = [capped.speed]

capped_want : List(F64)
capped_want = [2.75]

free_flag_got : List(Bool)
free_flag_got = [
	free.is_braking,
	ahead.is_braking,
	capped.is_braking,
]

free_flag_want : List(Bool)
free_flag_want = [False, False, False]

braking : Truck.TruckState
braking = Truck.advance(
	{
		route_position: 450.0,
		speed: 0.3,
		is_braking: False,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

brake_got : List(F64)
brake_got = [braking.speed, (braking.route_position - 450.0)]

brake_want : List(F64)
brake_want = [0.2994154176, 0.2994154176]

brake_flag_got : List(Bool)
brake_flag_got = [
	braking.is_braking,
	(braking.speed < 0.3),
	(braking.speed > 0.1776),
]

brake_flag_want : List(Bool)
brake_flag_want = [True, True, True]

settled : Truck.TruckState
settled = Truck.advance(
	{
		route_position: 450.0,
		speed: 0.1776,
		is_braking: True,
	},
	{
		rider_distance: 0.0,
		world: one_seg,
		route_length: 1000.0,
	},
)

settled_got : List(Bool)
settled_got = [settled.is_braking, (F64.to_bits(settled.speed) == F64.to_bits(0.1776))]

settled_want : List(Bool)
settled_want = [False, True]

boundary_got : List(Bool)
boundary_got = [
	(
		Truck.advance(
			{
				route_position: 440.0,
				speed: 0.3,
				is_braking: False,
			},
			{
				rider_distance: 0.0,
				world: one_seg,
				route_length: 1000.0,
			},
		).speed < 0.3
	),
	(
		Truck.advance(
			{
				route_position: 439.0,
				speed: 0.3,
				is_braking: False,
			},
			{
				rider_distance: 0.0,
				world: one_seg,
				route_length: 1000.0,
			},
		).speed < 0.3
	),
]

boundary_want : List(Bool)
boundary_want = [True, False]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tk-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tk-ratio ",
			got: ratio_got,
			want: ratio_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "tk-init  ",
			got: initial_got,
			want: initial_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tk-iflag ",
			got: initial_flag_got,
			want: initial_flag_want,
		}),
		Grade.reals({
			name: "tk-sched ",
			got: sched_got,
			want: sched_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tk-turn  ",
			got: turn_got,
			want: turn_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tk-none  ",
			got: none_got,
			want: none_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tk-chain ",
			got: chain_got,
			want: chain_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tk-free  ",
			got: free_got,
			want: free_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "tk-ahead ",
			got: ahead_got,
			want: ahead_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "tk-cap   ",
			got: capped_got,
			want: capped_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tk-fflag ",
			got: free_flag_got,
			want: free_flag_want,
		}),
		Grade.reals({
			name: "tk-brake ",
			got: brake_got,
			want: brake_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.bools({
			name: "tk-bflag ",
			got: brake_flag_got,
			want: brake_flag_want,
		}),
		Grade.bools({
			name: "tk-settle",
			got: settled_got,
			want: settled_want,
		}),
		Grade.bools({
			name: "tk-bound ",
			got: boundary_got,
			want: boundary_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
