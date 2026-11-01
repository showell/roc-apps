# TruckSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Truck
import VehicleLimits
import World

fixed_got : List(F64)
fixed_got = [Truck.start_ahead, Truck.finish_lead, Truck.truck_turn_caution, Truck.truck_brake_distance, Truck.truck_max_v]

fixed_want : List(F64)
fixed_want = [500.0, 100.0, 0.8, 60.0, 2.75]

ratio_got : List(F64)
ratio_got = [Truck.truck_chase_accel, Truck.truck_max_v, (Truck.truck_chase_accel / VehicleLimits.a_accel), (Truck.truck_max_v / VehicleLimits.v_max)]

ratio_want : List(F64)
ratio_want = [0.011, 2.75, 1.1, 1.1]

initial_got : List(F64)
initial_got = [Truck.truck_initial.pos, Truck.truck_initial.v]

initial_want : List(F64)
initial_want = [500.0, 0.3]

initial_flag_got : List(Bool)
initial_flag_got = [Truck.truck_initial.braking]

initial_flag_want : List(Bool)
initial_flag_want = [False]

sched_got : List(F64)
sched_got = [Truck.truck_schedule(0.0, 1000.0), Truck.truck_schedule(250.0, 1000.0), Truck.truck_schedule(500.0, 1000.0), Truck.truck_schedule(1000.0, 1000.0), (Truck.truck_schedule(1000.0, 1000.0) - 1000.0), (Truck.truck_schedule(0.0, 1000.0) - 0.0)]

sched_want : List(F64)
sched_want = [500.0, 650.0, 800.0, 1100.0, 100.0, 500.0]

one_seg : List(World.Segment)
one_seg = [World.segment_at(0)]

turn_dist : List(World.Segment), F64 -> F64
turn_dist = |segs, pos| (match Truck.next_turn(segs, pos) {
	TurnAhead(t) => t.dist
	NoTurnAhead => (0.0 - 1.0)
})

turn_v : List(World.Segment), F64 -> F64
turn_v = |segs, pos| (match Truck.next_turn(segs, pos) {
	TurnAhead(t) => t.v_turn
	NoTurnAhead => (0.0 - 1.0)
})

turn_got : List(F64)
turn_got = [turn_dist(one_seg, 0.0), turn_dist(one_seg, 450.0), turn_dist(one_seg, 499.0), turn_v(one_seg, 0.0), turn_v(one_seg, 450.0), VehicleLimits.turn_speed((List.get(one_seg, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).exit_angle)]

turn_want : List(F64)
turn_want = [500.0, 50.0, 1.0, 0.222, 0.222, 0.222]

none_got : List(F64)
none_got = [turn_dist(one_seg, 500.0), turn_dist(one_seg, 900.0), turn_dist([World.segment_at(18)], 0.0), turn_dist([], 0.0)]

none_want : List(F64)
none_want = [(-1.0), (-1.0), (-1.0), (-1.0)]

two_seg : List(World.Segment)
two_seg = [World.segment_at(0), World.segment_at(1)]

chain_got : List(F64)
chain_got = [turn_dist(two_seg, 0.0), turn_dist(two_seg, 500.0), turn_dist(two_seg, 800.0), turn_dist(two_seg, 820.0)]

chain_want : List(F64)
chain_want = [500.0, 320.0, 20.0, (-1.0)]

free : Truck.TruckState
free = Truck.truck_next({ pos: 100.0, v: 0.3, braking: False }, 0.0, one_seg, 1000.0)

free_got : List(F64)
free_got = [free.v, free.pos, (free.v - 0.3)]

free_want : List(F64)
free_want = [0.311, 100.311, 0.011]

ahead : Truck.TruckState
ahead = Truck.truck_next({ pos: 600.0, v: 0.5, braking: False }, 0.0, one_seg, 1000.0)

behind : Truck.TruckState
behind = Truck.truck_next({ pos: 400.0, v: 0.5, braking: False }, 0.0, one_seg, 1000.0)

ahead_got : List(F64)
ahead_got = [ahead.v, ahead.pos, (behind.v - ahead.v)]

ahead_want : List(F64)
ahead_want = [0.5, 600.5, 0.011]

capped : Truck.TruckState
capped = Truck.truck_next({ pos: 100.0, v: Truck.truck_max_v, braking: False }, 0.0, one_seg, 1000.0)

capped_got : List(F64)
capped_got = [capped.v]

capped_want : List(F64)
capped_want = [2.75]

free_flag_got : List(Bool)
free_flag_got = [free.braking, ahead.braking, capped.braking]

free_flag_want : List(Bool)
free_flag_want = [False, False, False]

braking : Truck.TruckState
braking = Truck.truck_next({ pos: 450.0, v: 0.3, braking: False }, 0.0, one_seg, 1000.0)

brake_got : List(F64)
brake_got = [braking.v, (braking.pos - 450.0)]

brake_want : List(F64)
brake_want = [0.2994154176, 0.2994154176]

brake_flag_got : List(Bool)
brake_flag_got = [braking.braking, (braking.v < 0.3), (braking.v > 0.1776)]

brake_flag_want : List(Bool)
brake_flag_want = [True, True, True]

settled : Truck.TruckState
settled = Truck.truck_next({ pos: 450.0, v: 0.1776, braking: True }, 0.0, one_seg, 1000.0)

settled_got : List(Bool)
settled_got = [settled.braking, (F64.to_bits(settled.v) == F64.to_bits(0.1776))]

settled_want : List(Bool)
settled_want = [False, True]

boundary_got : List(Bool)
boundary_got = [(Truck.truck_next({ pos: 440.0, v: 0.3, braking: False }, 0.0, one_seg, 1000.0).v < 0.3), (Truck.truck_next({ pos: 439.0, v: 0.3, braking: False }, 0.0, one_seg, 1000.0).v < 0.3)]

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
