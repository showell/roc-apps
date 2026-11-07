## Throttle decides the rider's speed for the next step. Each of four limits
## asks for nothing or for an acceleration no harder than its own, and the
## acceleration offered is held to the least of them.
import Acceleration
import Along
import Angle
import Animation
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
import World

Throttle :: [].{

	## The speed the motorcycle goes on the next step, on `segment`, whose
	## encounter stands at `encounter`.
	next_speed : Motorcycle, { segment : Segment, encounter : Animation.Timing } -> Speed
	next_speed = |motorcycle, { segment: seg, encounter }| {
		offered = VehicleLimits.cruise_acceleration
		limits = [
			bend_limit(motorcycle, seg),
			EncounterReaction.encounter_throttle(seg, encounter),
			Gawking.gawk_brake(motorcycle, seg),
			shoulder_limit(motorcycle),
		]
		limited = limits.fold(offered, held_to)
		allowed_speed(motorcycle.speed.accelerated_by(limited))
	}
}

## The speed to leave `seg` at: the speed for its bend, or rest at the route's
## end.
exit_speed : Segment -> Speed
exit_speed = |seg|
	match seg.ending {
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

## Whether the motorcycle is near enough the end of `seg` to brake for its bend.
is_near_end : Motorcycle, Segment -> Bool
is_near_end = |motorcycle, seg|
	Along.at(seg.length).distance_from(motorcycle.along) <= bend_approach

## How far short of a segment's end the rider starts to brake for its bend.
bend_approach : Distance
bend_approach = Distance.metres(60.0)

## Near the end of the segment, the brake that brings the rider to the exit
## speed at the point where they commit to the turn. Past that point there is
## no road left to brake on, and the limit holds the acceleration at none.
bend_limit : Motorcycle, Segment -> VehicleLimits.Limit
bend_limit = |motorcycle, seg|
	if is_near_end(motorcycle, seg) {
		v_end = exit_speed(seg)
		d = seg.commit_along().distance_from(motorcycle.along)
		AtMost(VehicleLimits.braking_to(motorcycle.speed, { target: v_end, within: d }))
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

## The speed the rider may reach: `next_speed`, held between rest and the top
## speed.
allowed_speed : Speed -> Speed
allowed_speed = |next_speed| next_speed.min(VehicleLimits.top_speed).max(Speed.at_rest)

first_segment : Segment
first_segment = World.route.segment_at(Route.SegmentIndex.number(0))

## A motorcycle on the centre line, upright.
centred_motorcycle : F64, F64 -> Motorcycle
centred_motorcycle = |along, speed| {
	..Motorcycle.initial,
	along: Along.metres(along),
	speed: Speed.metres_a_step(speed),
}

## This many metres a step, each step.
acceleration_of : F64 -> Acceleration
acceleration_of = |metres| Acceleration.metres_a_step_each_step(metres)

# A limit lowers what it is offered, and never raises it.
expect held_to(Acceleration.steady, NoLimit) == Acceleration.steady
expect held_to(acceleration_of(-0.5), NoLimit) == acceleration_of(-0.5)
expect held_to(acceleration_of(0.01), AtMost(acceleration_of(-0.5))) == acceleration_of(-0.5)
expect held_to(acceleration_of(-0.5), AtMost(Acceleration.steady)) == acceleration_of(-0.5)

expect exit_speed(first_segment).to_metres_a_step() == 0.222
expect exit_speed(World.route.segment_at(Route.SegmentIndex.number(18))) == Speed.at_rest

expect !is_near_end(centred_motorcycle(439.9, 0.3), first_segment)
expect is_near_end(centred_motorcycle(440.0, 0.3), first_segment)

## The bend limit for this motorcycle on the first segment.
bend_limit_at : Motorcycle -> VehicleLimits.Limit
bend_limit_at = |motorcycle| bend_limit(motorcycle, first_segment)

## The brake the bend limit asks of this motorcycle, near the bend.
bend_brake_at : Motorcycle -> F64
bend_brake_at = |motorcycle|
	match bend_limit_at(motorcycle) {
		AtMost(most) => most.to_metres_a_step_each_step()
		NoLimit => crash "Throttle's expects: this motorcycle is near the bend"
	}

# Far from the bend, it asks nothing; past the commit point, no acceleration.
expect bend_limit_at(centred_motorcycle(0.0, 0.3)) == NoLimit
expect bend_limit_at(centred_motorcycle(498.4, 0.3)) == AtMost(Acceleration.steady)
expect bend_limit_at(centred_motorcycle(600.0, 0.3)) == AtMost(Acceleration.steady)

# Short of the commit point it brakes, and harder for a faster rider.
expect bend_brake_at(centred_motorcycle(460.0, 0.3)) < 0.0
expect bend_brake_at(centred_motorcycle(460.0, 2.0)) < bend_brake_at(centred_motorcycle(460.0, 0.3))

## A motorcycle steering hard left at `speed`.
off_left : F64 -> Motorcycle
off_left = |speed| { ..centred_motorcycle(0.0, speed), yaw: Angle.Turn.radians(-1.5) }

expect Coast.project(off_left(0.048)) == Leaves({ side: Left, after: Steps.of(41) })
expect Coast.project(off_left(0.7)) == Leaves({ side: Left, after: Steps.of(3) })

# A coast that stays on the road asks nothing, and one that leaves it brakes.
expect shoulder_limit(centred_motorcycle(0.0, 0.3)) == NoLimit
expect shoulder_limit(off_left(0.7)) == AtMost(shoulder_brake(off_left(0.7).speed, Steps.of(3)))

## The shoulder brake at 1 metre a step.
brake_after : U32 -> Acceleration
brake_after = |steps_to_shoulder|
	shoulder_brake(Speed.metres_a_step(1.0), Steps.of(steps_to_shoulder))

expect brake_after(40) < Acceleration.steady
expect brake_after(40) > brake_after(2)

# A coast that leaves the road on its first step still brakes.
expect brake_after(1) < Acceleration.steady

## The speed the clamp allows for `next_speed` metres a step.
clamped_speed : F64 -> F64
clamped_speed = |next_speed| allowed_speed(Speed.metres_a_step(next_speed)).to_metres_a_step()

# Within its bounds the speed is as asked, at the top speed it is held, and
# outside them it is held to the nearer bound.
expect clamped_speed(1.0) == 1.0
expect clamped_speed(0.1) == 0.1
expect clamped_speed(2.5) == 2.5
expect clamped_speed(3.0) == 2.5
expect clamped_speed(0.0) == 0.0
expect clamped_speed(-1.0) == 0.0

## The change of speed that `Throttle.next_speed` makes for this motorcycle on
## `seg`, before its encounter is planned.
speed_change : Motorcycle, Segment -> Acceleration
speed_change = |motorcycle, seg|
	Throttle.next_speed(
		motorcycle,
		{ segment: seg, encounter: Unplanned },
	).change_from(motorcycle.speed)

## The whole decision for a motorcycle at the start of the segment, on the
## centre line.
decide : Speed, F64 -> Acceleration
decide = |speed, lean|
	speed_change({ ..Motorcycle.initial, speed, lean: Angle.Lean.radians(lean) }, first_segment)

# Each is within 1e-12 of its want.
expect
	[
		(decide(Speed.metres_a_step(0.3), 0.0), 0.01),
		(decide(VehicleLimits.top_speed, 0.0), 0.0),
		(decide(Speed.at_rest, 0.0), 0.01),
	].all(|(got, want)| (got.to_metres_a_step_each_step() - want).abs() <= 0.000000000001)

# On the middle of the road, a lean that coasts off it brakes, either way, and a
# slight one speeds up.
expect decide(Speed.metres_a_step(0.3), 0.034) < Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.001) > Acceleration.steady
expect decide(Speed.metres_a_step(0.3), -0.034) < Acceleration.steady

## The decision for a motorcycle at `along` on segment `index`, going 0.3
## metres a step.
decide_on : U32, F64 -> Acceleration
decide_on = |index, along|
	speed_change(
		centred_motorcycle(along, 0.3),
		World.route.segment_at(Route.SegmentIndex.number(index)),
	)

# A gawking rider brakes. A crossing cat's hold is CrossModuleExpects', which can
# name a step of the clock.
expect decide_on(3, 0.0) > Acceleration.steady
expect decide_on(2, 100.0) > Acceleration.steady
expect decide_on(2, 300.0) < Acceleration.steady
