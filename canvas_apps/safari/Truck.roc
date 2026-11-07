## The truck the rider chases. It teases him: it starts well ahead and lets him
## close in over the whole route, unevenly, as if the driver saw him. The tease
## is `tease_position`, and plain physics carries it out: the truck speeds up
## while it is short of the tease, holds its speed otherwise, and slows for a
## turn when one is close.
import Acceleration
import Distance
import Fraction
import Route
import Speed
import VehicleLimits
import World

## How far along the route the truck is, how fast it is going, and whether
## its last step slowed it.
Truck := {
	route_position : Distance,
	speed : Speed,
	pace : [Slowing, NotSlowing],
}.{

	initial : Truck
	initial = {
		route_position: tease_start_lead,
		speed: VehicleLimits.starting_speed,
		pace: NotSlowing,
	}

	## The truck one step on: where the rider is along the route, and the
	## route itself, decide its pace.
	at_next_step : Truck, { rider_distance : Distance, route : Route } -> Truck
	at_next_step = |truck, { rider_distance, route }| {
		tease = tease_position({ rider_distance, route_length: route.route_length() })
		match next_bend(route, truck.route_position) {
			BendAhead(bend) =>
				if bend.distance <= brake_distance {
					braking_state_at_next_step(truck, bend)
				} else {
					chasing_state_at_next_step(truck, tease)
				}
			NoBendAhead => chasing_state_at_next_step(truck, tease)
		}
	}
}

## A turn ahead of the truck: how far off it is, and how fast it can be
## taken.
ComingBend : { distance : Distance, turn_speed : Speed }

## The next turn of the route past a point, or none: the route ends first.
NextBend : [BendAhead(ComingBend), NoBendAhead]

## How far ahead of the rider the tease puts the truck at the route's start.
tease_start_lead : Distance
tease_start_lead = Distance.metres(500.0)

## How far ahead of the rider the tease puts the truck at the route's end.
tease_finish_lead : Distance
tease_finish_lead = Distance.metres(100.0)

## The truck takes a turn at this fraction of the speed the turn allows.
turn_caution : Fraction
turn_caution = Fraction.of(0.8)

## The truck starts to brake when a turn is this close.
brake_distance : Distance
brake_distance = Distance.metres(60.0)

## 10% over the rider's own cruise acceleration.
chase_acceleration : Acceleration
chase_acceleration = VehicleLimits.cruise_acceleration.times(1.1)

## 10% over the rider's own top speed.
chase_top_speed : Speed
chase_top_speed = VehicleLimits.top_speed.times(1.1)

## The next turn of `route` past `route_position`.
next_bend : Route, Distance -> NextBend
next_bend = |route, route_position|
	match route.segments_with_ends().find_first(|stretch| route_position < stretch.end) {
		Ok({ segment, end }) =>
			match segment.ending {
				Bends({ turn, .. }) =>
					BendAhead({
						distance: end.minus(route_position),
						turn_speed: VehicleLimits.turn_speed(turn),
					})
				RouteEnds => NoBendAhead
			}
		Err(_) => NoBendAhead
	}

## The tease: where the truck aims to be along the route when the rider is
## `rider_distance` along it, so that the rider closes in on it over the whole
## route. The lead it aims for shrinks from `tease_start_lead` to
## `tease_finish_lead` in step with the rider's progress. The truck only chases
## this mark, and never slows to keep to it, so the real gap closes unevenly: the
## truck can run past the mark on a straight, and it brakes for every turn.
tease_position : { rider_distance : Distance, route_length : Distance } -> Distance
tease_position = |{ rider_distance, route_length }| {
	fraction_left = 1.0 - rider_distance.portion(route_length)
	extra_lead = tease_start_lead.minus(tease_finish_lead).times(fraction_left)
	rider_distance.plus(tease_finish_lead).plus(extra_lead)
}

## The truck one step on, slowing for `turn`, so that it reaches the turn at a
## cautious speed.
braking_state_at_next_step : Truck, ComingBend -> Truck
braking_state_at_next_step = |truck, turn| {
	target_speed = turn.turn_speed.times(turn_caution.to_f64())
	acceleration = VehicleLimits.braking_to(
		truck.speed,
		{ target: target_speed, within: turn.distance },
	)
	speed = target_speed.max(truck.speed.accelerated_by(acceleration))
	{
		route_position: truck.route_position.plus(speed.step_length()),
		speed,
		pace: if speed < truck.speed {
			Slowing
		} else {
			NotSlowing
		},
	}
}

## The truck one step on with no turn close: it speeds up while it is short of
## `tease`, and otherwise holds its speed.
chasing_state_at_next_step : Truck, Distance -> Truck
chasing_state_at_next_step = |truck, tease| {
	speed =
		if truck.route_position < tease {
			chase_top_speed.min(truck.speed.accelerated_by(chase_acceleration))
		} else {
			truck.speed
		}
	{
		route_position: truck.route_position.plus(speed.step_length()),
		speed,
		pace: NotSlowing,
	}
}

## Where the tease puts the truck, with the rider this far along a route
## 1000 m long.
tease_at : F64 -> F64
tease_at = |rider_distance|
	tease_position({
		rider_distance: Distance.metres(rider_distance),
		route_length: Distance.metres(1000.0),
	}).to_metres()

expect tease_at(0.0) == 500.0
expect tease_at(250.0) == 650.0
expect tease_at(500.0) == 800.0
expect tease_at(1000.0) == 1100.0

## How far the next bend is past `route_position` on the real route.
bend_distance_at : F64 -> Try(F64, [NoBendAhead])
bend_distance_at = |route_position|
	match next_bend(World.route, Distance.metres(route_position)) {
		BendAhead(bend) => Ok(bend.distance.to_metres())
		NoBendAhead => Err(NoBendAhead)
	}

## How fast the next bend past `route_position` on the real route can be taken.
bend_turn_speed_at : F64 -> Try(F64, [NoBendAhead])
bend_turn_speed_at = |route_position|
	match next_bend(World.route, Distance.metres(route_position)) {
		BendAhead(bend) => Ok(bend.turn_speed.to_metres_a_step())
		NoBendAhead => Err(NoBendAhead)
	}

expect bend_distance_at(0.0) == Ok(500.0)
expect bend_distance_at(450.0) == Ok(50.0)
expect bend_distance_at(499.0) == Ok(1.0)
expect bend_turn_speed_at(0.0) == Ok(0.222)
expect bend_turn_speed_at(450.0) == Ok(0.222)

# The route's last segment, from 7220 m to its end at 7520 m, ends in no turn.
expect bend_distance_at(7219.0) == Ok(1.0)
expect
	[7220.0, 7519.0, 7600.0].all(
		|route_position| bend_distance_at(route_position) == Err(NoBendAhead),
	)

expect bend_distance_at(500.0) == Ok(320.0)
expect bend_distance_at(800.0) == Ok(20.0)
expect bend_distance_at(820.0) == Ok(400.0)

## A rider at the start of the real route, where the tease is 500 m ahead.
rider_at_route_start : { rider_distance : Distance, route : Route }
rider_at_route_start = { rider_distance: Distance.zero, route: World.route }

chasing_truck : Truck
chasing_truck = Truck.at_next_step(
	{
		route_position: Distance.metres(100.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_at_route_start,
)

expect
	[
		(chasing_truck.speed.to_metres_a_step(), 0.311),
		(chasing_truck.route_position.to_metres(), 100.311),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

truck_past_tease : Truck
truck_past_tease = Truck.at_next_step(
	{
		route_position: Distance.metres(600.0),
		speed: Speed.metres_a_step(0.5),
		pace: NotSlowing,
	},
	rider_at_route_start,
)

truck_short_of_tease : Truck
truck_short_of_tease = Truck.at_next_step(
	{
		route_position: Distance.metres(400.0),
		speed: Speed.metres_a_step(0.5),
		pace: NotSlowing,
	},
	rider_at_route_start,
)

expect
	[
		(truck_past_tease.speed.to_metres_a_step(), 0.5),
		(truck_past_tease.route_position.to_metres(), 600.5),
		(truck_short_of_tease.speed.to_metres_a_step(), 0.511),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

truck_at_top_speed : Truck
truck_at_top_speed = Truck.at_next_step(
	{
		route_position: Distance.metres(100.0),
		speed: chase_top_speed,
		pace: NotSlowing,
	},
	rider_at_route_start,
)

expect truck_at_top_speed.speed.to_metres_a_step() == chase_top_speed.to_metres_a_step()
expect chasing_truck.pace == NotSlowing
expect truck_past_tease.pace == NotSlowing
expect truck_at_top_speed.pace == NotSlowing

braking_truck : Truck
braking_truck = Truck.at_next_step(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_at_route_start,
)

expect
	[
		(braking_truck.speed.to_metres_a_step(), 0.2994154176),
		(braking_truck.route_position.to_metres() - 450.0, 0.2994154176),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect braking_truck.pace == Slowing

settled_truck : Truck
settled_truck = Truck.at_next_step(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.1776),
		pace: Slowing,
	},
	rider_at_route_start,
)

expect settled_truck.pace == NotSlowing
expect F64.to_bits(settled_truck.speed.to_metres_a_step()) == F64.to_bits(0.1776)
expect Truck.at_next_step(
	{
		route_position: Distance.metres(440.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_at_route_start,
).speed < Speed.metres_a_step(0.3)
expect !(
	Truck.at_next_step(
		{
			route_position: Distance.metres(439.0),
			speed: Speed.metres_a_step(0.3),
			pace: NotSlowing,
		},
		rider_at_route_start,
	).speed < Speed.metres_a_step(0.3)
)
