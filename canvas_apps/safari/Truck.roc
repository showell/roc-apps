## The truck the rider chases. It starts well ahead and keeps to a schedule
## that brings it closer as the rider nears the route's end: it speeds up
## when it is behind the schedule, and slows for a turn when one is close.
## Speeds are in metres a frame.
import lib.DeviceMath
import Pose
import VehicleLimits
import World

Truck :: [].{

	## Where the truck is along the route, how fast it is going, and whether
	## it is braking.
	TruckState : {
		route_position : F64,
		speed : F64,
		is_braking : Bool,
	}

	## A turn ahead of the truck: how far off it is, and how fast it can be
	## taken.
	ComingTurn : { distance : F64, turn_speed : F64 }

	## The next turn of the route past a point, or none: the route ends first.
	NextTurn : [TurnAhead(Truck.ComingTurn), NoTurnAhead]

	## How far ahead of the rider the truck starts.
	start_lead : F64
	start_lead = 500.0

	## How far ahead of the rider the truck's schedule ends.
	finish_lead : F64
	finish_lead = 100.0

	## The truck takes a turn at this fraction of the speed the turn allows.
	turn_caution : F64
	turn_caution = 0.8

	## The truck starts to brake when a turn is this close.
	brake_distance : F64
	brake_distance = VehicleLimits.approach_intersection_dist

	chase_acceleration : F64
	chase_acceleration = 1.1 * VehicleLimits.a_accel

	top_speed : F64
	top_speed = 1.1 * VehicleLimits.v_max

	initial_truck : Truck.TruckState
	initial_truck = {
		route_position: start_lead,
		speed: Pose.v_base,
		is_braking: False,
	}

	## The next turn of `world` past `route_position`.
	next_turn : List(World.Segment), F64 -> Truck.NextTurn
	next_turn = |world, route_position|
		next_turn_on(
			world,
			{
				route_position,
				segment_start: 0.0,
			},
		)

	## Where the truck should be along the route, when the rider is
	## `rider_distance` along it.
	scheduled_position : { rider_distance : F64, route_length : F64 } -> F64
	scheduled_position = |{ rider_distance, route_length }| {
		fraction_left = 1.0 - rider_distance / route_length
		rider_distance + finish_lead + (start_lead - finish_lead) * fraction_left
	}

	## The truck a frame on: where the rider is along the route, the world's
	## segments, and the route's whole length decide its pace.
	advance : Truck.TruckState,
	{
		rider_distance : F64,
		world : List(World.Segment),
		route_length : F64,
	} -> Truck.TruckState
	advance = |
		truck,
		{
			rider_distance,
			world,
			route_length,
		},
	| {
		schedule = scheduled_position({ rider_distance, route_length })
		match next_turn(world, truck.route_position) {
			TurnAhead(turn) =>
				if turn.distance <= brake_distance {
					advance_braking(truck, turn)
				} else {
					advance_on_schedule(truck, schedule)
				}
			NoTurnAhead => advance_on_schedule(truck, schedule)
		}
	}
}

## The braking for a turn is worked out over the distance left to it, so a
## turn closer than this counts as reached, and no division is by zero.
least_braking_distance : F64
least_braking_distance = 0.000001

## The next turn past `route_position` along `segments`, the first of which
## starts at `segment_start`. The route's last segment ends in no turn.
next_turn_on : List(World.Segment),
{
	route_position : F64,
	segment_start : F64,
} -> Truck.NextTurn
next_turn_on = |segments, { route_position, segment_start }|
	match segments {
		[] => NoTurnAhead
		[segment, .. as later_segments] => {
			segment_end = segment_start + segment.length
			if route_position < segment_end {
				match segment.ending {
					Continues(_) =>
						TurnAhead({
							distance: segment_end - route_position,
							turn_speed: VehicleLimits.turn_speed(segment.exit_turn.abs()),
						})
					Terminates => NoTurnAhead
				}
			} else {
				next_turn_on(later_segments, { route_position, segment_start: segment_end })
			}
		}
	}

## The truck a frame on, slowing for `turn`, so that it reaches the turn at a
## cautious speed.
advance_braking : Truck.TruckState, Truck.ComingTurn -> Truck.TruckState
advance_braking = |truck, turn| {
	target_speed = turn.turn_speed * Truck.turn_caution
	acceleration =
		if turn.distance > least_braking_distance {
			(target_speed * target_speed - truck.speed * truck.speed) / (2.0 * turn.distance)
		} else {
			0.0
		}
	speed = DeviceMath.real_max(target_speed, truck.speed + acceleration)
	{
		route_position: truck.route_position + speed,
		speed,
		is_braking: speed < truck.speed,
	}
}

## The truck a frame on with no turn close: it speeds up while it is short of
## `schedule`, and otherwise holds its speed.
advance_on_schedule : Truck.TruckState, F64 -> Truck.TruckState
advance_on_schedule = |truck, schedule| {
	speed =
		if truck.route_position < schedule {
			DeviceMath.real_min(Truck.top_speed, truck.speed + Truck.chase_acceleration)
		} else {
			truck.speed
		}
	{
		route_position: truck.route_position + speed,
		speed,
		is_braking: False,
	}
}
