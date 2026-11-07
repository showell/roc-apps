## The truck the rider chases. It starts well ahead and keeps to a schedule
## that brings it closer as the rider nears the route's end: it speeds up
## when it is behind the schedule, and slows for a turn when one is close.
import Acceleration
import Distance
import Fraction
import Route
import Segment
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
		route_position: start_lead,
		speed: VehicleLimits.base_speed,
		pace: NotSlowing,
	}

	## The truck one step on: where the rider is along the route, the route
	## itself, and the route's whole length decide its pace.
	at_next_step : Truck,
	{
		rider_distance : Distance,
		route : Route,
		route_length : Distance,
	} -> Truck
	at_next_step = |truck, { rider_distance, route, route_length }| {
		schedule = scheduled_position({ rider_distance, route_length })
		match next_bend(route, truck.route_position) {
			BendAhead(bend) =>
				if bend.distance <= brake_distance {
					braking_state_at_next_step(truck, bend)
				} else {
					scheduled_state_at_next_step(truck, schedule)
				}
			NoBendAhead => scheduled_state_at_next_step(truck, schedule)
		}
	}
}

## A turn ahead of the truck: how far off it is, and how fast it can be
## taken.
ComingBend : { distance : Distance, turn_speed : Speed }

## The next turn of the route past a point, or none: the route ends first.
NextBend : [BendAhead(ComingBend), NoBendAhead]

## How far ahead of the rider the truck starts.
start_lead : Distance
start_lead = Distance.metres(500.0)

## How far ahead of the rider the truck's schedule ends.
finish_lead : Distance
finish_lead = Distance.metres(100.0)

## The truck takes a turn at this fraction of the speed the turn allows.
turn_caution : Fraction
turn_caution = Fraction.of(0.8)

## The truck starts to brake when a turn is this close.
brake_distance : Distance
brake_distance = VehicleLimits.bend_approach

## 10% over the rider's own cruise acceleration.
chase_acceleration : Acceleration
chase_acceleration = VehicleLimits.cruise_acceleration.times(1.1)

## 10% over the rider's own top speed.
top_speed : Speed
top_speed = VehicleLimits.top_speed.times(1.1)

## The next turn of `route` past `route_position`.
next_bend : Route, Distance -> NextBend
next_bend = |route, route_position|
	next_bend_on(route.route_segments(), { route_position, segment_start: Distance.zero })

## Where the truck should be along the route, when the rider is
## `rider_distance` along it.
scheduled_position : { rider_distance : Distance, route_length : Distance } -> Distance
scheduled_position = |{ rider_distance, route_length }| {
	fraction_left = 1.0 - rider_distance.portion(route_length)
	extra_lead = start_lead.minus(finish_lead).times(fraction_left)
	rider_distance.plus(finish_lead).plus(extra_lead)
}

## The next turn past `route_position` along `segments`, the first of which
## starts at `segment_start`. The route's last segment ends in no turn.
next_bend_on : List(Segment), { route_position : Distance, segment_start : Distance } -> NextBend
next_bend_on = |segments, { route_position, segment_start }|
	match segments {
		[] => NoBendAhead
		[segment, .. as later_segments] => {
			segment_end = segment_start.plus(segment.length)
			if route_position < segment_end {
				match segment.ending {
					Bends({ turn, .. }) =>
						BendAhead({
							distance: segment_end.minus(route_position),
							turn_speed: VehicleLimits.turn_speed(turn.abs()),
						})
					RouteEnds => NoBendAhead
				}
			} else {
				next_bend_on(later_segments, { route_position, segment_start: segment_end })
			}
		}
	}

## The truck one step on, slowing for `turn`, so that it reaches the turn at a
## cautious speed.
braking_state_at_next_step : Truck, ComingBend -> Truck
braking_state_at_next_step = |truck, turn| {
	target_speed = turn.turn_speed.times(turn_caution.to_f64())
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
		pace: if speed < truck.speed {
			Slowing
		} else {
			NotSlowing
		},
	}
}

## The truck one step on with no turn close: it speeds up while it is short of
## `schedule`, and otherwise holds its speed.
scheduled_state_at_next_step : Truck, Distance -> Truck
scheduled_state_at_next_step = |truck, schedule| {
	speed =
		if truck.route_position < schedule {
			top_speed.min(truck.speed.accelerated_by(chase_acceleration))
		} else {
			truck.speed
		}
	{
		route_position: truck.route_position.plus(speed.step_length()),
		speed,
		pace: NotSlowing,
	}
}

expect start_lead.to_metres() == 500.0
expect finish_lead.to_metres() == 100.0
expect turn_caution.to_f64() == 0.8
expect brake_distance.to_metres() == 60.0
expect top_speed.to_metres_a_step() == 2.75

chase_metres : F64
chase_metres = chase_acceleration.to_metres_a_step_each_step()

expect
	[
		(chase_metres, 0.011),
		(top_speed.to_metres_a_step(), 2.75),
		(chase_metres / VehicleLimits.cruise_acceleration.to_metres_a_step_each_step(), 1.1),
		(top_speed.portion(VehicleLimits.top_speed), 1.1),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Truck.initial.route_position.to_metres() == 500.0
expect Truck.initial.speed.to_metres_a_step() == 0.3
expect !(Truck.initial.pace == Slowing)

## Where the schedule puts the truck, with the rider this far along a route
## 1000 m long.
schedule_at : F64 -> F64
schedule_at = |rider_distance|
	scheduled_position({
		rider_distance: Distance.metres(rider_distance),
		route_length: Distance.metres(1000.0),
	}).to_metres()

expect schedule_at(0.0) == 500.0
expect schedule_at(250.0) == 650.0
expect schedule_at(500.0) == 800.0
expect schedule_at(1000.0) == 1100.0
expect schedule_at(1000.0) - 1000.0 == 100.0
expect schedule_at(0.0) - 0.0 == 500.0

turn_distance : Route, F64 -> F64
turn_distance = |route, route_position|
	match next_bend(route, Distance.metres(route_position)) {
		BendAhead(t) => t.distance.to_metres()
		NoBendAhead => -1.0
	}

turn_v : Route, F64 -> F64
turn_v = |route, route_position|
	match next_bend(route, Distance.metres(route_position)) {
		BendAhead(t) => t.turn_speed.to_metres_a_step()
		NoBendAhead => -1.0
	}

expect turn_distance(World.route, 0.0) == 500.0
expect turn_distance(World.route, 450.0) == 50.0
expect turn_distance(World.route, 499.0) == 1.0
expect turn_v(World.route, 0.0) == 0.222
expect turn_v(World.route, 450.0) == 0.222
expect {
	first_turn = World.route.segment_at(Route.SegmentIndex.number(0)).bend_out_of().turn
	VehicleLimits.turn_speed(first_turn.abs()).to_metres_a_step() == 0.222
}

# The route's last segment, from 7220 m to its end at 7520 m, ends in no turn.
expect turn_distance(World.route, 7219.0) == 1.0
expect turn_distance(World.route, 7220.0) == -1.0
expect turn_distance(World.route, 7519.0) == -1.0
expect turn_distance(World.route, 7600.0) == -1.0

expect turn_distance(World.route, 500.0) == 320.0
expect turn_distance(World.route, 800.0) == 20.0
expect turn_distance(World.route, 820.0) == 400.0

## A rider at the start of the route, on its first segment, with the schedule
## laid out for a route 1000 m long.
rider_on_one_segment : {
	rider_distance : Distance,
	route : Route,
	route_length : Distance,
}
rider_on_one_segment = {
	rider_distance: Distance.zero,
	route: World.route,
	route_length: Distance.metres(1000.0),
}

free : Truck
free = Truck.at_next_step(
	{
		route_position: Distance.metres(100.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_on_one_segment,
)

expect
	[
		(free.speed.to_metres_a_step(), 0.311),
		(free.route_position.to_metres(), 100.311),
		(free.speed.change_from(Speed.metres_a_step(0.3)).to_metres_a_step_each_step(), 0.011),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

ahead : Truck
ahead = Truck.at_next_step(
	{
		route_position: Distance.metres(600.0),
		speed: Speed.metres_a_step(0.5),
		pace: NotSlowing,
	},
	rider_on_one_segment,
)

behind : Truck
behind = Truck.at_next_step(
	{
		route_position: Distance.metres(400.0),
		speed: Speed.metres_a_step(0.5),
		pace: NotSlowing,
	},
	rider_on_one_segment,
)

expect
	[
		(ahead.speed.to_metres_a_step(), 0.5),
		(ahead.route_position.to_metres(), 600.5),
		(behind.speed.change_from(ahead.speed).to_metres_a_step_each_step(), 0.011),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

capped : Truck
capped = Truck.at_next_step(
	{
		route_position: Distance.metres(100.0),
		speed: top_speed,
		pace: NotSlowing,
	},
	rider_on_one_segment,
)

expect capped.speed.to_metres_a_step() == 2.75
expect free.pace == NotSlowing
expect ahead.pace == NotSlowing
expect capped.pace == NotSlowing

braking : Truck
braking = Truck.at_next_step(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_on_one_segment,
)

expect
	[
		(braking.speed.to_metres_a_step(), 0.2994154176),
		(braking.route_position.to_metres() - 450.0, 0.2994154176),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect braking.pace == Slowing
expect braking.speed < Speed.metres_a_step(0.3)
expect braking.speed > Speed.metres_a_step(0.1776)

settled : Truck
settled = Truck.at_next_step(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.1776),
		pace: Slowing,
	},
	rider_on_one_segment,
)

expect settled.pace == NotSlowing
expect F64.to_bits(settled.speed.to_metres_a_step()) == F64.to_bits(0.1776)
expect Truck.at_next_step(
	{
		route_position: Distance.metres(440.0),
		speed: Speed.metres_a_step(0.3),
		pace: NotSlowing,
	},
	rider_on_one_segment,
).speed < Speed.metres_a_step(0.3)
expect !(
	Truck.at_next_step(
		{
			route_position: Distance.metres(439.0),
			speed: Speed.metres_a_step(0.3),
			pace: NotSlowing,
		},
		rider_on_one_segment,
	).speed < Speed.metres_a_step(0.3)
)
