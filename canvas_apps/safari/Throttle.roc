## Throttle decides how hard the rider accelerates on the next step. Each limit
## asks for nothing or for an acceleration no harder than its own, and the
## acceleration offered is held to the least of them.
import Acceleration
import Along
import EncounterPlan
import Coast
import Distance
import EncounterReaction
import Gawking
import Motorcycle
import Route
import Segment
import Speed
import Steps
import VehicleLimits

Throttle :: [].{

	## The acceleration the motorcycle takes on the next step, on `route`, with
	## the encounter on the motorcycle's segment at `encounter_timing`.
	next_acceleration : Motorcycle,
	{
		route : Route,
		encounter_timing : EncounterPlan.Timing,
	} -> Acceleration
	next_acceleration = |motorcycle, { route, encounter_timing }| {
		segment = motorcycle.route_place.segment_on(route)
		offered = VehicleLimits.cruise_acceleration
		limits = [
			bend_limit(motorcycle, segment),
			EncounterReaction.encounter_throttle(segment, encounter_timing),
			Gawking.gawk_brake(motorcycle, segment),
			shoulder_limit(motorcycle),
		]
		limits.fold(offered, held_to)
	}
}

## The speed to leave `segment` at: the speed for its bend, or rest at the route's
## end.
exit_speed : Segment -> Speed
exit_speed = |segment|
	match segment.ending {
		Bends({ turn, .. }) => VehicleLimits.turn_speed(turn)
		RouteEnds => Speed.at_rest
	}

## How fast the shoulder brake fades with the steps left to the shoulder: it
## falls to about a third every 20 steps, a time constant chosen by eye.
brake_decay : Steps
brake_decay = Steps.of(20)

## The acceleration `a`, held to what `limit` asks.
held_to : Acceleration, VehicleLimits.Limit -> Acceleration
held_to = |a, limit|
	match limit {
		AtMost(most) => a.min(most)
		NoLimit => a
	}

## Whether the motorcycle is near enough the end of `segment` to brake for its bend.
is_near_end : Motorcycle, Segment -> Bool
is_near_end = |motorcycle, segment|
	Along.at(segment.length).distance_from(motorcycle.route_place.along) <= bend_approach

## How far short of a segment's end the rider starts to brake for its bend.
bend_approach : Distance
bend_approach = Distance.metres(60.0)

## Near the end of the segment, the brake that brings the rider to the exit
## speed at the point where they commit to the turn. Past that point there is
## no road left to brake on, and the limit holds the acceleration at none.
bend_limit : Motorcycle, Segment -> VehicleLimits.Limit
bend_limit = |motorcycle, segment|
	if is_near_end(motorcycle, segment) {
		segment_exit_speed = exit_speed(segment)
		room_to_commit = segment.commit_along().distance_from(motorcycle.route_place.along)
		AtMost(
			VehicleLimits.braking_to(
				motorcycle.speed,
				{ target: segment_exit_speed, within: room_to_commit },
			),
		)
	} else {
		NoLimit
	}

## Nothing, unless a coast from here leaves the road; then the brake for the
## shoulder it reaches.
shoulder_limit : Motorcycle -> VehicleLimits.Limit
shoulder_limit = |motorcycle|
	match Coast.project(motorcycle) {
		EndsAt(_) => NoLimit
		Leaves({ after, .. }) => AtMost(shoulder_brake(motorcycle.speed, after))
	}

## The brake at `speed` for a coast that leaves the road in
## `steps_to_shoulder`, which is at least one step.
shoulder_brake : Speed, Steps -> Acceleration
shoulder_brake = |speed, steps_to_shoulder| {
	n = steps_to_shoulder.to_f64()
	even_braking = -speed.to_metres_a_step() / (2.0 * n)
	Acceleration.metres_a_step_each_step(even_braking * F64.e.pow(-n / brake_decay.to_f64()))
}

## This many metres a step, each step.
acceleration_of : F64 -> Acceleration
acceleration_of = |metres| Acceleration.metres_a_step_each_step(metres)

# A limit lowers what it is offered, and never raises it.
expect held_to(Acceleration.steady, NoLimit) == Acceleration.steady
expect held_to(acceleration_of(-0.5), NoLimit) == acceleration_of(-0.5)
expect held_to(acceleration_of(0.01), AtMost(acceleration_of(-0.5))) == acceleration_of(-0.5)
expect held_to(acceleration_of(-0.5), AtMost(Acceleration.steady)) == acceleration_of(-0.5)

## The shoulder brake at 1 metre a step.
brake_after : U32 -> Acceleration
brake_after = |steps_to_shoulder|
	shoulder_brake(Speed.metres_a_step(1.0), Steps.of(steps_to_shoulder))

expect brake_after(40) < Acceleration.steady
expect brake_after(40) > brake_after(2)

# A coast that leaves the road on its first step still brakes.
expect brake_after(1) < Acceleration.steady
