## The motorcycle the rider sits on: where it is on the route, which way it
## points, how fast it goes and how far it leans, and the physics that moves it
## a step. The lean steers the motorcycle, and it moves along the middle of the
## step's turn, in its segment's frame.
import Acceleration
import Along
import Angle
import Distance
import Geom
import RoutePlace
import Speed
import VehicleLimits

## The motorcycle at one step. `route_place` places it on the route, and `yaw`
## is its turn from its segment's axis. `lean` is how far it tips. Nominal, not
## opaque: other modules read its fields.
Motorcycle := {
	route_place : RoutePlace,
	yaw : Angle.Turn,
	speed : Speed,
	lean : Angle.Lean,
}.{

	initial : Motorcycle
	initial = {
		route_place: RoutePlace.route_start,
		yaw: Angle.straight_ahead,
		speed: VehicleLimits.starting_speed,
		lean: Angle.upright,
	}

	## What the rider sets for a step: the lean the motorcycle takes, and how
	## hard it accelerates.
	Controls : { lean : Angle.Lean, acceleration : Acceleration }

	## The motorcycle one step on, at the lean its controls set and the speed
	## their acceleration gives, held to the top speed.
	motorcycle_at_next_step : Motorcycle, Motorcycle.Controls -> Motorcycle
	motorcycle_at_next_step = |motorcycle, { lean, acceleration }| {
		speed = allowed_speed(motorcycle.speed.accelerated_by(acceleration))
		step_length = speed.step_length()
		turn = lean.steer(turn_per_lean)
		mid = motorcycle.yaw.plus(turn.times(0.5)).to_radians()
		place = motorcycle.route_place
		{
			route_place: {
				..place,
				along: place.along.plus(step_length.times(mid.cos())),
				across: place.across.plus(step_length.times(mid.sin())),
			},
			yaw: motorcycle.yaw.plus(turn),
			speed,
			lean,
		}
	}

	## The controls that keep this motorcycle's lean and speed as they are.
	steady_controls : Motorcycle -> Motorcycle.Controls
	steady_controls = |motorcycle| { lean: motorcycle.lean, acceleration: Acceleration.steady }

	with_lean : Motorcycle, Angle.Lean -> Motorcycle
	with_lean = |motorcycle, lean| { ..motorcycle, lean }

	## This motorcycle carried over `bend`, the bend out of its segment, when
	## that puts it on the next segment's road: placed on that segment and turned
	## to its axis. Short of that, it stays where it is.
	cross_bend_if_on_road : Motorcycle, Geom.Bend -> Motorcycle
	cross_bend_if_on_road = |motorcycle, bend| {
		on_next = motorcycle.route_place.route_place_past_bend(bend)
		if on_next.is_on_road() {
			{
				..motorcycle,
				route_place: on_next,
				yaw: motorcycle.yaw.minus(bend.turn),
			}
		} else {
			motorcycle
		}
	}

	## This motorcycle stopped dead at `at` on its segment.
	stopped_at : Motorcycle, Along -> Motorcycle
	stopped_at = |motorcycle, at| {
		..motorcycle,
		route_place: { ..motorcycle.route_place, along: at },
		speed: Speed.at_rest,
	}

	## Whether this motorcycle has come to `at` on its segment, or gone past.
	has_reached : Motorcycle, Along -> Bool
	has_reached = |motorcycle, at| motorcycle.route_place.along >= at

	is_eq : _
}

## How far the motorcycle turns in a step for each radian of lean. This is an
## honest cheat, chosen by eye: a real bike's turn at a given lean depends on
## its speed, and here it doesn't. The ride never asks for more, because the
## lean search picks each step's lean by coasting this same physics, so the
## rider leans for the turn the bike really makes at any speed.
turn_per_lean : F64
turn_per_lean = 0.1

## The speed the rider may reach: `next_speed`, held to the top speed.
allowed_speed : Speed -> Speed
allowed_speed = |next_speed| next_speed.min(VehicleLimits.top_speed)

## The speed the clamp allows for `next_speed` metres a step.
clamped_speed : F64 -> F64
clamped_speed = |next_speed| allowed_speed(Speed.metres_a_step(next_speed)).to_metres_a_step()

# Up to the top speed the speed is as asked, and past it it is held there.
expect clamped_speed(1.0) == 1.0
expect clamped_speed(0.1) == 0.1
expect clamped_speed(2.5) == 2.5
expect clamped_speed(3.0) == 2.5
expect clamped_speed(0.0) == 0.0

## A motorcycle well along a segment, leaning a little to the right.
riding : Motorcycle
riding = {
	route_place: {
		..RoutePlace.route_start,
		along: Along.metres(120.5),
		across: RoutePlace.route_start.across.plus(Distance.metres(2.25)),
	},
	yaw: Angle.Turn.radians(0.375),
	speed: Speed.metres_a_step(0.8),
	lean: Angle.Lean.radians(0.125),
}

# The first two steps change the lean and the speed a little from the step
# before, and the third keeps them.
first_step : Motorcycle
first_step = riding.motorcycle_at_next_step({
	lean: Angle.Lean.radians(0.175),
	acceleration: Acceleration.metres_a_step_each_step(0.01),
})

second_step : Motorcycle
second_step = first_step.motorcycle_at_next_step({
	lean: Angle.Lean.radians(0.155),
	acceleration: Acceleration.metres_a_step_each_step(0.005),
})

third_step : Motorcycle
third_step = second_step.motorcycle_at_next_step(second_step.steady_controls())

expect
	[
		(first_step.yaw.to_radians(), 0.3925),
		(first_step.speed.to_metres_a_step(), 0.81),
		(first_step.lean.to_radians(), 0.175),
		(second_step.yaw.to_radians(), 0.40800000000000003),
		(second_step.speed.to_metres_a_step(), 0.8150000000000001),
		(second_step.lean.to_radians(), 0.155),
		(third_step.yaw.to_radians(), 0.42350000000000004),
		(third_step.speed.to_metres_a_step(), 0.8150000000000001),
		(third_step.lean.to_radians(), 0.155),
	].all(|(got, want)| got == want)

# Each is within 1e-9 of its want, scaled up by a want past 1.
expect
	[
		(first_step.route_place.along.to_metres(), 121.25108639750266),
		(first_step.route_place.across.to_metres(), 2.5532642799382796),
		(second_step.route_place.along.to_metres(), 122.00167174017032),
		(second_step.route_place.across.to_metres(), 2.8708278851774045),
		(third_step.route_place.along.to_metres(), 122.7472448817898),
		(third_step.route_place.across.to_metres(), 3.1999869508214647),
	].all(|(got, want)| (got - want).abs() <= 0.000000001 * want.abs().max(1.0))

expect {
	a = Motorcycle.initial.motorcycle_at_next_step(Motorcycle.initial.steady_controls())
	b = Motorcycle.motorcycle_at_next_step(
		Motorcycle.initial,
		{ lean: Angle.Lean.radians(0.5), acceleration: Acceleration.metres_a_step_each_step(0.25) },
	)
	[
		(a.route_place.across.to_metres(), 0.0),
		(a.yaw.to_radians(), 0.0),
		(a.lean.to_radians(), 0.0),
		(a.speed.to_metres_a_step(), 0.3),
		(b.lean.to_radians(), 0.5),
		(b.speed.to_metres_a_step(), 0.55),
		(b.yaw.to_radians(), 0.05),
	].all(|(got, want)| got == want)
}

## A bend at the end of a 500-metre segment, turning a little to the right.
gentle_bend : Geom.Bend
gentle_bend = { segment_length: Distance.metres(500.0), turn: Angle.Turn.radians(0.3) }

## A motorcycle on the middle of the road, `along` metres down its segment.
motorcycle_at : F64 -> Motorcycle
motorcycle_at = |along| {
	..Motorcycle.initial,
	route_place: { ..RoutePlace.route_start, along: Along.metres(along) },
}

## The place of a motorcycle `along` metres down its segment, carried over the
## gentle bend.
place_past_bend : F64 -> RoutePlace
place_past_bend = |along| motorcycle_at(along).route_place.route_place_past_bend(gentle_bend)

# Carried over the bend from well short of it, a place lands far off the next
# segment's road, and from the bend itself it lands on it. Either way it is on
# the next segment.
expect place_past_bend(100.0).across.distance_from_middle() > Distance.metres(100.0)
expect place_past_bend(500.0).is_on_road()
expect {
	next_index = RoutePlace.route_start.segment_index.next()
	[100.0, 500.0].all(|along| place_past_bend(along).segment_index == next_index)
}

# So from well short of the bend the motorcycle stays where it was, and from the
# bend it crosses, turned to the next segment's axis.
expect motorcycle_at(100.0).cross_bend_if_on_road(gentle_bend) == motorcycle_at(100.0)
expect {
	crossed = motorcycle_at(500.0).cross_bend_if_on_road(gentle_bend)
	next_index = RoutePlace.route_start.segment_index.next()
	crossed.route_place.segment_index == next_index and crossed.yaw.to_radians() == -0.3
}

expect motorcycle_at(300.0).has_reached(Along.metres(300.0))
expect motorcycle_at(310.0).has_reached(Along.metres(300.0))
expect !motorcycle_at(299.99).has_reached(Along.metres(300.0))
