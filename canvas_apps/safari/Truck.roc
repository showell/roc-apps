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
	ComingBend : { distance : Distance, turn_speed : Speed }

	## The next turn of the route past a point, or none: the route ends first.
	NextBend : [BendAhead(Truck.ComingBend), NoBendAhead]

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
	brake_distance = VehicleLimits.bend_approach

	chase_acceleration : Acceleration
	chase_acceleration = VehicleLimits.cruise_acceleration.times(1.1)

	top_speed : Speed
	top_speed = VehicleLimits.top_speed.times(1.1)

	initial_truck : Truck.TruckState
	initial_truck = {
		route_position: start_lead,
		speed: VehicleLimits.base_speed,
		brake_lights: Off,
	}

	## The next turn of `route` past `route_position`.
	next_bend : List(World.Segment), Distance -> Truck.NextBend
	next_bend = |route, route_position|
		next_bend_on(route, { route_position, segment_start: Distance.zero })

	## Where the truck should be along the route, when the rider is
	## `rider_distance` along it.
	scheduled_position : { rider_distance : Distance, route_length : Distance } -> Distance
	scheduled_position = |{ rider_distance, route_length }| {
		fraction_left = 1.0 - rider_distance.ratio_to(route_length)
		rider_distance.plus(finish_lead).plus(start_lead.minus(finish_lead).times(fraction_left))
	}

	## The truck one step on: where the rider is along the route, the world's
	## segments, and the route's whole length decide its pace.
	advance : Truck.TruckState,
	{
		rider_distance : Distance,
		route : List(World.Segment),
		route_length : Distance,
	} -> Truck.TruckState
	advance = |truck, { rider_distance, route, route_length }| {
		schedule = scheduled_position({ rider_distance, route_length })
		match next_bend(route, truck.route_position) {
			BendAhead(bend) =>
				if bend.distance <= brake_distance {
					advance_braking(truck, bend)
				} else {
					advance_on_schedule(truck, schedule)
				}
			NoBendAhead => advance_on_schedule(truck, schedule)
		}
	}
}

## The next turn past `route_position` along `segments`, the first of which
## starts at `segment_start`. The route's last segment ends in no turn.
next_bend_on : List(World.Segment),
{
	route_position : Distance,
	segment_start : Distance,
} -> Truck.NextBend
next_bend_on = |segments, { route_position, segment_start }|
	match segments {
		[] => NoBendAhead
		[segment, .. as later_segments] => {
			segment_end = segment_start.plus(segment.length)
			if route_position < segment_end {
				match segment.ending {
					Continues(_) =>
						BendAhead({
							distance: segment_end.minus(route_position),
							turn_speed: VehicleLimits.turn_speed(segment.exit_turn.abs()),
						})
					Terminates => NoBendAhead
				}
			} else {
				next_bend_on(later_segments, { route_position, segment_start: segment_end })
			}
		}
	}

## The truck one step on, slowing for `turn`, so that it reaches the turn at a
## cautious speed.
advance_braking : Truck.TruckState, Truck.ComingBend -> Truck.TruckState
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
		brake_lights: if speed < truck.speed {
			On
		} else {
			Off
		},
	}
}

## The truck one step on with no turn close: it speeds up while it is short of
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

expect Truck.start_lead.to_metres() == 500.0
expect Truck.finish_lead.to_metres() == 100.0
expect Truck.turn_caution == 0.8
expect Truck.brake_distance.to_metres() == 60.0
expect Truck.top_speed.to_metres_a_step() == 2.75

chase_metres : F64
chase_metres = Truck.chase_acceleration.to_metres_a_step_each_step()

expect
	[
		(chase_metres, 0.011),
		(Truck.top_speed.to_metres_a_step(), 2.75),
		((chase_metres / VehicleLimits.cruise_acceleration.to_metres_a_step_each_step()), 1.1),
		((Truck.top_speed.to_metres_a_step() / VehicleLimits.top_speed.to_metres_a_step()), 1.1),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Truck.initial_truck.route_position.to_metres() == 500.0
expect Truck.initial_truck.speed.to_metres_a_step() == 0.3
expect !(Truck.initial_truck.brake_lights == On)

## Where the schedule puts the truck, with the rider this far along a route
## 1000 m long.
schedule : F64 -> F64
schedule = |rider_distance|
	Truck.scheduled_position({
		rider_distance: Distance.metres(rider_distance),
		route_length: Distance.metres(1000.0),
	}).to_metres()

expect schedule(0.0) == 500.0
expect schedule(250.0) == 650.0
expect schedule(500.0) == 800.0
expect schedule(1000.0) == 1100.0
expect schedule(1000.0) - 1000.0 == 100.0
expect schedule(0.0) - 0.0 == 500.0

one_seg : List(World.Segment)
one_seg = [World.route_segment(0)]

turn_distance : List(World.Segment), F64 -> F64
turn_distance = |route, route_position|
	match Truck.next_bend(route, Distance.metres(route_position)) {
		BendAhead(t) => t.distance.to_metres()
		NoBendAhead => 0.0 - 1.0
	}

turn_v : List(World.Segment), F64 -> F64
turn_v = |route, route_position|
	match Truck.next_bend(route, Distance.metres(route_position)) {
		BendAhead(t) => t.turn_speed.to_metres_a_step()
		NoBendAhead => 0.0 - 1.0
	}

expect turn_distance(one_seg, 0.0) == 500.0
expect turn_distance(one_seg, 450.0) == 50.0
expect turn_distance(one_seg, 499.0) == 1.0
expect turn_v(one_seg, 0.0) == 0.222
expect turn_v(one_seg, 450.0) == 0.222
expect VehicleLimits.turn_speed(World.route_segment(0).exit_turn.abs()).to_metres_a_step() == 0.222
expect turn_distance(one_seg, 500.0) == -1.0
expect turn_distance(one_seg, 900.0) == -1.0
expect turn_distance([World.route_segment(18)], 0.0) == -1.0
expect turn_distance([], 0.0) == -1.0

two_seg : List(World.Segment)
two_seg = [World.route_segment(0), World.route_segment(1)]

expect turn_distance(two_seg, 0.0) == 500.0
expect turn_distance(two_seg, 500.0) == 320.0
expect turn_distance(two_seg, 800.0) == 20.0
expect turn_distance(two_seg, 820.0) == -1.0

## A rider at the start of a route 1000 m long, on the route's first segment.
on_one_seg : {
	rider_distance : Distance,
	route : List(World.Segment),
	route_length : Distance,
}
on_one_seg = {
	rider_distance: Distance.zero,
	route: one_seg,
	route_length: Distance.metres(1000.0),
}

free : Truck.TruckState
free = Truck.advance(
	{
		route_position: Distance.metres(100.0),
		speed: Speed.metres_a_step(0.3),
		brake_lights: Off,
	},
	on_one_seg,
)

expect
	[
		(free.speed.to_metres_a_step(), 0.311),
		(free.route_position.to_metres(), 100.311),
		(free.speed.change_from(Speed.metres_a_step(0.3)).to_metres_a_step_each_step(), 0.011),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

ahead : Truck.TruckState
ahead = Truck.advance(
	{
		route_position: Distance.metres(600.0),
		speed: Speed.metres_a_step(0.5),
		brake_lights: Off,
	},
	on_one_seg,
)

behind : Truck.TruckState
behind = Truck.advance(
	{
		route_position: Distance.metres(400.0),
		speed: Speed.metres_a_step(0.5),
		brake_lights: Off,
	},
	on_one_seg,
)

expect
	[
		(ahead.speed.to_metres_a_step(), 0.5),
		(ahead.route_position.to_metres(), 600.5),
		(behind.speed.change_from(ahead.speed).to_metres_a_step_each_step(), 0.011),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

capped : Truck.TruckState
capped = Truck.advance(
	{
		route_position: Distance.metres(100.0),
		speed: Truck.top_speed,
		brake_lights: Off,
	},
	on_one_seg,
)

expect capped.speed.to_metres_a_step() == 2.75
expect free.brake_lights == Off
expect ahead.brake_lights == Off
expect capped.brake_lights == Off

braking : Truck.TruckState
braking = Truck.advance(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.3),
		brake_lights: Off,
	},
	on_one_seg,
)

expect
	[
		(braking.speed.to_metres_a_step(), 0.2994154176),
		((braking.route_position.to_metres() - 450.0), 0.2994154176),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect braking.brake_lights == On
expect braking.speed < Speed.metres_a_step(0.3)
expect braking.speed > Speed.metres_a_step(0.1776)

settled : Truck.TruckState
settled = Truck.advance(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.1776),
		brake_lights: On,
	},
	on_one_seg,
)

expect settled.brake_lights == Off
expect F64.to_bits(settled.speed.to_metres_a_step()) == F64.to_bits(0.1776)
expect Truck.advance(
	{
		route_position: Distance.metres(440.0),
		speed: Speed.metres_a_step(0.3),
		brake_lights: Off,
	},
	on_one_seg,
).speed < Speed.metres_a_step(0.3)
expect !(
	Truck.advance(
		{
			route_position: Distance.metres(439.0),
			speed: Speed.metres_a_step(0.3),
			brake_lights: Off,
		},
		on_one_seg,
	).speed < Speed.metres_a_step(0.3)
)
