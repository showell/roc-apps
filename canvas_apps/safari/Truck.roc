# Truck -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import lib.DeviceMath
import Pose
import VehicleLimits
import World

Truck :: [].{
	TruckState : {
		pos : F64,
		v : F64,
		braking : Bool,
	}
	Turn : { dist : F64, v_turn : F64 }

	## The next turn of the route past a point, or none: the route ends first.
	NextTurn : [TurnAhead(Truck.Turn), NoTurnAhead]

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
	truck_initial = {
		pos: start_ahead,
		v: Pose.v_base,
		braking: False,
	}

	## The next turn at or after segment `segment_index`, which starts
	## `segment_start` along the route.
	next_turn_from : List(World.Segment),
	{
		truck_position : F64,
		segment_index : I64,
		segment_start : F64,
	} -> Truck.NextTurn
	next_turn_from = |
		segs,
		{
			truck_position: pos,
			segment_index: i,
			segment_start: cum0,
		},
	| (
		if i >= segs.len().to_i64_wrap() {
			NoTurnAhead
		} else {
			next_turn_step(
				segs,
				{
					truck_position: pos,
					segment_index: i,
					segment_end: (
						cum0 + (
							List.get(
								segs,
								I64.to_u64_wrap(i),
							) ?? crash ("list-at out of range")
						).length
					),
				},
			)
		}
	)

	## The turn at the end of segment `segment_index`, which ends
	## `segment_end` along the route, if the truck is short of it; else the
	## next turn after it.
	next_turn_step : List(World.Segment),
	{
		truck_position : F64,
		segment_index : I64,
		segment_end : F64,
	} -> Truck.NextTurn
	next_turn_step = |
		segs,
		{
			truck_position: pos,
			segment_index: i,
			segment_end: cum,
		},
	| (
		{
			s = (List.get(segs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
			(
				if pos < cum {
					match s.ending {
						Continues(_) => TurnAhead({
							dist: (cum - pos),
							v_turn: VehicleLimits.turn_speed(s.exit_angle),
						})
						Terminates => NoTurnAhead
					}
				} else {
					next_turn_from(
						segs,
						{
							truck_position: pos,
							segment_index: i + 1,
							segment_start: cum,
						},
					)
				}
			)
		}
	)

	next_turn : List(World.Segment), F64 -> Truck.NextTurn
	next_turn = |segs, pos| next_turn_from(
		segs,
		{
			truck_position: pos,
			segment_index: 0,
			segment_start: 0.0,
		},
	)

	truck_schedule : F64, F64 -> F64
	truck_schedule = |
		rider_dist,
		l,
	| ((rider_dist + finish_lead) + ((start_ahead - finish_lead) * (1.0 - (rider_dist / l))))

	## The truck a frame on: where the rider is along the route, the
	## world's segments, and the route's whole length decide its pace.
	truck_next : Truck.TruckState,
	{
		rider_distance : F64,
		world : List(World.Segment),
		route_length : F64,
	} -> Truck.TruckState
	truck_next = |
		truck,
		{
			rider_distance: rider_dist,
			world: segs,
			route_length: l,
		},
	| (
		{
			scheduled = truck_schedule(rider_dist, l)
			(
				match next_turn(segs, truck.pos) {
					TurnAhead(turn) => (
						if turn.dist <= truck_brake_distance {
							truck_braking(truck, turn)
						} else {
							truck_free(truck, scheduled)
						}
					)
					NoTurnAhead => truck_free(truck, scheduled)
				}
			)
		}
	)

	truck_braking : Truck.TruckState, Truck.Turn -> Truck.TruckState
	truck_braking = |truck, turn| (
		{
			target = (turn.v_turn * truck_turn_caution)
			a = (
				if turn.dist > F64.from_bits(4517329193108106637) {
					(((target * target) - (truck.v * truck.v)) / (2.0 * turn.dist))
				} else {
					0.0
				}
			)
			v = DeviceMath.real_max(target, (truck.v + a))
			{
				pos: (truck.pos + v),
				v: v,
				braking: (v < truck.v),
			}
		}
	)

	truck_free : Truck.TruckState, F64 -> Truck.TruckState
	truck_free = |truck, scheduled| (
		{
			v = (
				if truck.pos < scheduled {
					DeviceMath.real_min(truck_max_v, (truck.v + truck_chase_accel))
				} else {
					truck.v
				}
			)
			{
				pos: (truck.pos + v),
				v: v,
				braking: False,
			}
		}
	)
}
