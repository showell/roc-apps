## Throttle decides how hard the rider speeds up or brakes. Each of four limits
## asks for nothing or for an acceleration no harder than its own, and the
## acceleration offered is held to the least of them.
import Acceleration
import Along
import Angle
import Coast
import EncounterReaction
import Gawking
import Motorcycle
import Route
import Segment
import Speed
import Steps
import lib.Trig
import VehicleLimits
import World

Throttle :: [].{

	acceleration : Motorcycle, Segment -> Acceleration
	acceleration = |motorcycle, seg| {
		offered =
			if motorcycle.lean.abs() >= lean_hold {
				Acceleration.steady
			} else {
				VehicleLimits.cruise_acceleration
			}
		v_end = exit_speed(seg)
		limits = [
			bend_limit(motorcycle, { segment: seg, exit_speed: v_end }),
			EncounterReaction.encounter_throttle(seg, motorcycle),
			Gawking.gawk_brake(motorcycle, seg),
			shoulder_limit(motorcycle),
		]
		limited = limits.fold(offered, held_to)
		allowed_speed(
			motorcycle,
			{
				segment: seg,
				exit_speed: v_end,
				next_speed: motorcycle.speed.accelerated_by(limited),
			},
		).change_from(motorcycle.speed)
	}
}

## The rider holds the throttle off while leaning this far or further.
lean_hold : Angle.Lean
lean_hold = Angle.Lean.degrees(2.0)

brake_decay : Steps
brake_decay = Steps.of(20)

## The acceleration `a`, held to what `limit` asks.
held_to : Acceleration, VehicleLimits.Limit -> Acceleration
held_to = |a, limit|
	match limit {
		AtMost(most) => a.min(most)
		NoLimit => a
	}

## The speed to leave `seg` at: the speed for its bend, or rest at the route's
## end.
exit_speed : Segment -> Speed
exit_speed = |seg|
	match seg.ending {
		Bends({ turn, .. }) => VehicleLimits.turn_speed(turn.abs())
		RouteEnds => Speed.at_rest
	}

## Whether the motorcycle is near enough the end of `seg` to brake for its bend.
is_near_end : Motorcycle, Segment -> Bool
is_near_end = |motorcycle, seg|
	Along.at(seg.length).distance_from(motorcycle.along) <= VehicleLimits.bend_approach

## Near the end of the segment, the brake that brings the rider to the exit
## speed at the point where they commit to the turn. Past that point there is
## no road left to brake on, and the limit holds the acceleration at none.
bend_limit : Motorcycle, { segment : Segment, exit_speed : Speed } -> VehicleLimits.Limit
bend_limit = |motorcycle, { segment: seg, exit_speed: v_end }|
	if is_near_end(motorcycle, seg) {
		d = seg.commit_along().distance_from(motorcycle.along)
		bend_a =
			if d <= VehicleLimits.least_braking_distance {
				Acceleration.steady
			} else {
				motorcycle.speed.acceleration_to({ target: v_end, within: d })
			}
		AtMost(bend_a)
	} else {
		NoLimit
	}

## Nothing, unless a coast from here leaves the road; then the brake for the
## shoulder it reaches.
shoulder_limit : Motorcycle -> VehicleLimits.Limit
shoulder_limit = |motorcycle|
	match Coast.project(motorcycle) {
		EndsAt(_) => NoLimit
		Leaves({ after, .. }) => AtMost(shoulder_brake(motorcycle, after))
	}

## The brake for a coast that leaves the road in `steps_to_shoulder`.
shoulder_brake : Motorcycle, Steps -> Acceleration
shoulder_brake = |motorcycle, steps_to_shoulder| {
	n = steps_to_shoulder.to_f64()
	even_braking = (0.0 - motorcycle.speed.to_metres_a_step()) / (2.0 * n.max(1.0))
	Acceleration.metres_a_step_each_step(even_braking * F64.e.pow((0.0 - n) / brake_decay.to_f64()))
}

## The speed the rider may reach: `next_speed`, held between rest and the top
## speed. Near the end of the segment a rider below the exit speed is lifted
## to it, unless they are gawking.
allowed_speed : Motorcycle,
{
	segment : Segment,
	exit_speed : Speed,
	next_speed : Speed,
} -> Speed
allowed_speed = |
	motorcycle,
	{
		segment: seg,
		exit_speed: v_end,
		next_speed: v0,
	},
| {
	v2 = v0.min(VehicleLimits.top_speed).max(Speed.at_rest)
	if is_near_end(motorcycle, seg) {
		if v2 < v_end {
			if Gawking.is_gawking(motorcycle, seg) {
				v2
			} else {
				v_end
			}
		} else {
			v2
		}
	} else {
		v2
	}
}

# Each is within 1e-12 of its want.
expect
	[
		(lean_hold.to_radians(), 0.03490658503988659),
		(brake_decay.to_f64(), 20.0),
		(lean_hold.to_radians() / Trig.deg, 2.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

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
bend_limit_at = |motorcycle|
	bend_limit(motorcycle, { segment: first_segment, exit_speed: Speed.metres_a_step(0.222) })

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

## Throttle doesn't import Distance or Across, so these places and lengths come
## from what it does see.
across_at = |metres| Motorcycle.initial.across.plus(Speed.metres_a_step(metres).step_length())

## A motorcycle steering hard left at `speed`.
off_left : F64 -> Motorcycle
off_left = |speed| { ..centred_motorcycle(0.0, speed), yaw: Angle.Turn.radians(-1.5) }

expect Coast.project(off_left(0.048)) == Leaves({ side: Left, after: Steps.of(40) })
expect Coast.project(off_left(0.7)) == Leaves({ side: Left, after: Steps.of(2) })

# A coast that stays on the road asks nothing, and one that leaves it brakes.
expect shoulder_limit(centred_motorcycle(0.0, 0.3)) == NoLimit
expect shoulder_limit(off_left(0.7)) == AtMost(shoulder_brake(off_left(0.7), Steps.of(2)))

## The shoulder brake for a motorcycle going 1 metre a step.
brake_after : U32 -> Acceleration
brake_after = |steps_to_shoulder|
	shoulder_brake(centred_motorcycle(0.0, 1.0), Steps.of(steps_to_shoulder))

expect brake_after(40) < Acceleration.steady
expect brake_after(40) > brake_after(2)

# A coast that leaves the road at once still brakes.
expect brake_after(0) < Acceleration.steady

## The speed the clamp allows this motorcycle, for `next_speed` metres a step.
clamped_speed : Motorcycle, F64 -> F64
clamped_speed = |motorcycle, next_speed|
	allowed_speed(
		motorcycle,
		{
			segment: first_segment,
			exit_speed: Speed.metres_a_step(0.222),
			next_speed: Speed.metres_a_step(next_speed),
		},
	).to_metres_a_step()

## A motorcycle far from the bend, and one near it.
far_from_bend : Motorcycle
far_from_bend = centred_motorcycle(0.0, 0.3)

near_bend : Motorcycle
near_bend = centred_motorcycle(460.0, 0.3)

expect clamped_speed(far_from_bend, 1.0) == 1.0
expect clamped_speed(far_from_bend, 3.0) == 2.5
expect clamped_speed(far_from_bend, -1.0) == 0.0
expect clamped_speed(near_bend, 0.1) == 0.222
expect clamped_speed(near_bend, 0.5) == 0.5
expect clamped_speed(far_from_bend, 0.1) == 0.1

## The whole decision for a motorcycle at the start of the segment, on the
## centre line.
decide : Speed, F64 -> Acceleration
decide = |speed, lean|
	Throttle.acceleration(
		{ ..Motorcycle.initial, speed, lean: Angle.Lean.radians(lean) },
		first_segment,
	)

## The whole decision for a motorcycle far off to the right.
wide_of_road : F64 -> Acceleration
wide_of_road = |lean|
	Throttle.acceleration(
		{
			..centred_motorcycle(0.0, 0.3),
			across: across_at(100.0),
			lean: Angle.Lean.radians(lean),
		},
		first_segment,
	)

hold_radians : F64
hold_radians = lean_hold.to_radians()

# Each is within 1e-12 of its want.
expect
	[
		(decide(Speed.metres_a_step(0.3), 0.0), 0.01),
		(decide(VehicleLimits.top_speed, 0.0), 0.0),
		(decide(Speed.at_rest, 0.0), 0.01),
		(wide_of_road(-0.001), 0.01),
		(wide_of_road(-hold_radians), 0.0),
		(wide_of_road(-hold_radians - 0.5), 0.0),
	].all(|(got, want)| (got.to_metres_a_step_each_step() - want).abs() <= 0.000000000001)

expect decide(Speed.metres_a_step(0.3), hold_radians - 0.001) < Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.001) > Acceleration.steady
expect decide(Speed.metres_a_step(0.3), -(hold_radians - 0.001)) < Acceleration.steady

## The decision for a motorcycle at `along` on segment `index`, going 0.3
## metres a step.
decide_on : U32, F64 -> Acceleration
decide_on = |index, along|
	Throttle.acceleration(
		centred_motorcycle(along, 0.3),
		World.route.segment_at(Route.SegmentIndex.number(index)),
	)

# A crossing cat stops the throttle opening, and a gawking rider brakes.
expect decide_on(3, 0.0) > Acceleration.steady
expect decide_on(3, 120.0) == Acceleration.steady
expect decide_on(2, 100.0) > Acceleration.steady
expect decide_on(2, 300.0) < Acceleration.steady

# These are Coast's projections. They sit here because Coast imports neither Speed
# nor VehicleLimits, and Throttle sees both.

## The coast of a motorcycle at the start of the segment, going the base speed.
coast_of : F64, F64 -> Coast.Outcome
coast_of = |across, lean_radians|
	Coast.project({
		..Motorcycle.initial,
		across: across_at(across),
		lean: Angle.Lean.radians(lean_radians),
	})

straight : Coast.Outcome
straight = coast_of(0.0, 0.0)

wide : Coast.Outcome
wide = coast_of(3.0, 0.0)

stopped : Coast.Outcome
stopped = Coast.project({ ..Motorcycle.initial, speed: Speed.at_rest })

leaning : Coast.Outcome
leaning = coast_of(0.0, 0.2)

other_way : Coast.Outcome
other_way = coast_of(0.0, -0.2)

expect straight == EndsAt(across_at(0.0))
expect wide == EndsAt(across_at(3.0))
expect stopped == EndsAt(across_at(0.0))

# A rider this slow and this far over circles on the road, and the coast still ends.
expect {
	circling = Coast.project({
		..Motorcycle.initial,
		speed: Speed.metres_a_step(0.01),
		lean: Angle.Lean.radians(0.5),
	})
	match circling {
		EndsAt(_) => True
		Leaves(_) => False
	}
}

## How many steps a coast runs before it leaves the road.
steps_off_road : Coast.Outcome -> Steps
steps_off_road = |coast|
	match coast {
		Leaves({ after, .. }) => after
		EndsAt(_) => crash "Throttle's expects: this coast stays on the road"
	}

expect leaning == Leaves({ side: Right, after: steps_off_road(leaning) })
expect other_way == Leaves({ side: Left, after: steps_off_road(other_way) })

expect steps_off_road(leaning) < Coast.longest_coast
expect steps_off_road(leaning) > Steps.zero
expect steps_off_road(leaning) == steps_off_road(other_way)
