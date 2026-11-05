## The truck the rider chases. It starts well ahead and keeps to a schedule
## that brings it closer as the rider nears the route's end: it speeds up
## when it is behind the schedule, and slows for a turn when one is close.
import Acceleration
import Distance
import Speed
import VehicleLimits
import World

Truck :: [].{

	## How far along the route the truck is, how fast it is going, and whether
	## its brake lights are on.
	TruckState : {
		route_position : Distance,
		speed : Speed,
		brake_lights : [On, Off],
	}

	## Which of the truck's lights are on.
	Lights : { headlights : [On, Off], brake_lights : [On, Off] }

	## A turn ahead of the truck: how far off it is, and how fast it can be
	## taken.
	ComingTurn : { distance : Distance, turn_speed : Speed }

	## The next turn of the route past a point, or none: the route ends first.
	NextTurn : [TurnAhead(Truck.ComingTurn), NoTurnAhead]

	## How far ahead of the rider the truck starts.
	start_lead : Distance
	start_lead = Distance.metres(500.0)

	## How far ahead of the rider the truck's schedule ends.
	finish_lead : Distance
	finish_lead = Distance.metres(100.0)

	## The truck takes a turn at this fraction of the speed the turn allows.
	turn_caution : F64
	turn_caution = 0.8

	## The truck starts to brake when a turn is this close.
	brake_distance : Distance
	brake_distance = VehicleLimits.approach_intersection_dist

	chase_acceleration : Acceleration
	chase_acceleration = VehicleLimits.a_accel.times(1.1)

	top_speed : Speed
	top_speed = VehicleLimits.v_max.times(1.1)

	initial_truck : Truck.TruckState
	initial_truck = {
		route_position: start_lead,
		speed: VehicleLimits.v_base,
		brake_lights: Off,
	}

	## The next turn of `world` past `route_position`.
	next_turn : List(World.Segment), Distance -> Truck.NextTurn
	next_turn = |world, route_position|
		next_turn_on(
			world,
			{
				route_position,
				segment_start: Distance.zero,
			},
		)

	## Where the truck should be along the route, when the rider is
	## `rider_distance` along it.
	scheduled_position : { rider_distance : Distance, route_length : Distance } -> Distance
	scheduled_position = |{ rider_distance, route_length }| {
		fraction_left = 1.0 - rider_distance.ratio_to(route_length)
		rider_distance.plus(finish_lead).plus(start_lead.minus(finish_lead).times(fraction_left))
	}

	## The truck a frame on: where the rider is along the route, the world's
	## segments, and the route's whole length decide its pace.
	advance : Truck.TruckState,
	{
		rider_distance : Distance,
		world : List(World.Segment),
		route_length : Distance,
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

## The next turn past `route_position` along `segments`, the first of which
## starts at `segment_start`. The route's last segment ends in no turn.
next_turn_on : List(World.Segment),
{
	route_position : Distance,
	segment_start : Distance,
} -> Truck.NextTurn
next_turn_on = |segments, { route_position, segment_start }|
	match segments {
		[] => NoTurnAhead
		[segment, .. as later_segments] => {
			segment_end = segment_start.plus(segment.length)
			if route_position < segment_end {
				match segment.ending {
					Continues(_) =>
						TurnAhead({
							distance: segment_end.minus(route_position),
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
	target_speed = turn.turn_speed.times(Truck.turn_caution)
	acceleration =
		if turn.distance > VehicleLimits.least_braking_distance {
			truck.speed.acceleration_to({ target: target_speed, within: turn.distance })
		} else {
			Acceleration.steady
		}
	speed = target_speed.max(truck.speed.accelerated_by(acceleration))
	{
		route_position: truck.route_position.plus(speed.step_length()),
		speed,
		brake_lights: if (speed < truck.speed) On else Off,
	}
}

## The truck a frame on with no turn close: it speeds up while it is short of
## `schedule`, and otherwise holds its speed.
advance_on_schedule : Truck.TruckState, Distance -> Truck.TruckState
advance_on_schedule = |truck, schedule| {
	speed =
		if truck.route_position < schedule {
			Truck.top_speed.min(truck.speed.accelerated_by(Truck.chase_acceleration))
		} else {
			truck.speed
		}
	{
		route_position: truck.route_position.plus(speed.step_length()),
		speed,
		brake_lights: Off,
	}
}
