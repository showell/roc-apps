## TruckJourney is the truck's travel along the route, as the rider chases it.
## The truck teases him: it starts well ahead and lets him close in over the
## whole route, unevenly, as if the driver saw him. The tease is
## `tease_position`, and plain physics carries it out: the truck speeds up while
## it is short of the tease, holds its speed otherwise, and slows for a turn when
## one is close.
import Acceleration
import Distance
import Fraction
import Route
import Speed
import VehicleLimits

## How far along the route the truck is, how fast it is going, and whether
## its last step slowed it. Nominal, not opaque: other modules read its fields.
TruckJourney := {
	route_position : Distance,
	speed : Speed,
	pace : TruckJourney.Pace,
}.{

	## Whether the truck's last step slowed it.
	Pace := [Slowing, NotSlowing].{
		is_eq : _
	}

	initial : TruckJourney
	initial = {
		route_position: tease_start_lead,
		speed: VehicleLimits.starting_speed,
		pace: NotSlowing,
	}

	## The truck one step on: where the rider is along the route, and the
	## route itself, decide its pace.
	truck_at_next_step : TruckJourney, { rider_distance : Distance, route : Route } -> TruckJourney
	truck_at_next_step = |truck, { rider_distance, route }| {
		tease = tease_position({ rider_distance, route_length: route.route_length() })
		match next_bend(route, truck.route_position) {
			BendAhead(bend) =>
				if bend.distance <= brake_distance {
					braking_truck_at_next_step(truck, bend)
				} else {
					chasing_truck_at_next_step(truck, tease)
				}
			NoBendAhead => chasing_truck_at_next_step(truck, tease)
		}
	}
}

## A bend ahead of the truck: how far off it is, and how fast it can be
## taken.
ComingBend : { distance : Distance, turn_speed : Speed }

## The next bend of the route past a point, or none: the route ends first.
NextBend : [BendAhead(ComingBend), NoBendAhead]

## How far ahead of the rider the tease puts the truck at the route's start.
tease_start_lead : Distance
tease_start_lead = Distance.metres(500.0)

## How far ahead of the rider the tease puts the truck at the route's end.
tease_finish_lead : Distance
tease_finish_lead = Distance.metres(100.0)

## The truck takes a bend at this fraction of the speed the bend allows, to
## leave a margin.
turn_caution : Fraction
turn_caution = Fraction.of(0.8)

## The truck starts to brake when a bend is this close.
brake_distance : Distance
brake_distance = Distance.metres(60.0)

## The truck outdoes the rider by 10%, in both its acceleration and its top
## speed.
chase_margin : F64
chase_margin = 1.1

## The rider's own cruise acceleration, outdone by `chase_margin`.
chase_acceleration : Acceleration
chase_acceleration = VehicleLimits.cruise_acceleration.times(chase_margin)

## The rider's own top speed, outdone by `chase_margin`.
chase_top_speed : Speed
chase_top_speed = VehicleLimits.top_speed.times(chase_margin)

## The next bend of `route` past `route_position`.
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
		Err(NotFound) => NoBendAhead
	}

## The tease: where the truck aims to be along the route when the rider is
## `rider_distance` along it, so that the rider closes in on it over the whole
## route. The lead it aims for shrinks from `tease_start_lead` to
## `tease_finish_lead` in step with the rider's progress. The truck only chases
## this mark, and never slows to keep to it, so the real gap closes unevenly: the
## truck can run past the mark on a straight, and it slows for the bends.
tease_position : { rider_distance : Distance, route_length : Distance } -> Distance
tease_position = |{ rider_distance, route_length }| {
	fraction_left = 1.0 - rider_distance.ratio_to(route_length)
	extra_lead = tease_start_lead.minus(tease_finish_lead).times(fraction_left)
	rider_distance.plus(tease_finish_lead).plus(extra_lead)
}

## The truck one step on, slowing for `bend`, so that it reaches the bend at a
## cautious speed.
braking_truck_at_next_step : TruckJourney, ComingBend -> TruckJourney
braking_truck_at_next_step = |truck, bend| {
	target_speed = bend.turn_speed.scaled_by(turn_caution)
	acceleration = VehicleLimits.braking_to(
		truck.speed,
		{ target: target_speed, within: bend.distance },
	)
	# The steady brake may land a little under its target; `VehicleLimits.braking_to`
	# says why. The truck alone keeps to the target here.
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

## The truck one step on with no bend close: it speeds up while it is short of
## `tease`, and otherwise holds its speed.
chasing_truck_at_next_step : TruckJourney, Distance -> TruckJourney
chasing_truck_at_next_step = |truck, tease| {
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
