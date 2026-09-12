# Truck -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DeviceMath
import Maybe
import Pose
import VehicleLimits
import World

Truck :: [].{
	TruckState : { pos : F64, v : F64, braking : Bool }
	Turn : { dist : F64, v_turn : F64 }

	start_ahead : F64
	start_ahead = 500.0

	finish_lead : F64
	finish_lead = 100.0

	truck_turn_caution : F64
	truck_turn_caution = 0.8

	truck_brake_distance : F64
	truck_brake_distance = VehicleLimits.approach_intersection_dist

	truck_chase_accel : F64
	truck_chase_accel = (1.1 * VehicleLimits.a_accel)

	truck_max_v : F64
	truck_max_v = (1.1 * VehicleLimits.v_max)

	truck_initial : Truck.TruckState
	truck_initial = { pos: start_ahead, v: Pose.v_base, braking: False }

	next_turn_loop : List(World.Segment), F64, I64, F64 -> Maybe.Maybe(Truck.Turn)
	next_turn_loop = |segs, pos, i, cum0| (if (i >= U64.to_i64_wrap(List.len(segs))) { None } else { next_turn_step(segs, pos, i, (cum0 + (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).length)) })

	next_turn_step : List(World.Segment), F64, I64, F64 -> Maybe.Maybe(Truck.Turn)
	next_turn_step = |segs, pos, i, cum| ({
		s = (List.get(segs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (pos < cum) { (if s.terminates { None } else { Just({ dist: (cum - pos), v_turn: VehicleLimits.turn_speed(s.exit_angle) }) }) } else { next_turn_loop(segs, pos, (i + 1), cum) })
	})

	next_turn : List(World.Segment), F64 -> Maybe.Maybe(Truck.Turn)
	next_turn = |segs, pos| next_turn_loop(segs, pos, 0, 0.0)

	truck_schedule : F64, F64 -> F64
	truck_schedule = |rider_dist, l| ((rider_dist + finish_lead) + ((start_ahead - finish_lead) * (1.0 - (rider_dist / l))))

	truck_next : Truck.TruckState, F64, List(World.Segment), F64 -> Truck.TruckState
	truck_next = |truck, rider_dist, segs, l| ({
		scheduled = truck_schedule(rider_dist, l)
		(match next_turn(segs, truck.pos) {
			Just(turn) => (if (turn.dist <= truck_brake_distance) { truck_braking(truck, turn) } else { truck_free(truck, scheduled) })
			None => truck_free(truck, scheduled)
		})
	})

	truck_braking : Truck.TruckState, Truck.Turn -> Truck.TruckState
	truck_braking = |truck, turn| ({
		target = (turn.v_turn * truck_turn_caution)
		a = (if (turn.dist > F64.from_bits(4517329193108106637)) { (((target * target) - (truck.v * truck.v)) / (2.0 * turn.dist)) } else { 0.0 })
		v = DeviceMath.real_max(target, (truck.v + a))
		{ pos: (truck.pos + v), v: v, braking: (v < truck.v) }
	})

	truck_free : Truck.TruckState, F64 -> Truck.TruckState
	truck_free = |truck, scheduled| ({
		v = (if (truck.pos < scheduled) { DeviceMath.real_min(truck_max_v, (truck.v + truck_chase_accel)) } else { truck.v })
		{ pos: (truck.pos + v), v: v, braking: False }
	})
}
