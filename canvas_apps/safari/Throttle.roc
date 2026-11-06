## Throttle decides how hard the rider speeds up or brakes. The acceleration
## passes through a chain of limits, each of which can only lower it.
import Acceleration
import Along
import Angle
import Coast
import CrossingReaction
import lib.DeviceMath
import Gaze
import Float
import RiderState
import Speed
import Steps
import lib.Trig
import VehicleLimits
import World

Throttle :: [].{

	## The rider holds the throttle off while leaning this far or further.
	lean_hold : Angle.Lean
	lean_hold = Angle.Lean.degrees(2.0)

	bend_brake : RiderState,
	{
		segment : World.Segment,
		exit_speed : Speed,
		offered_acceleration : Acceleration,
	} -> Acceleration
	bend_brake = |
		state,
		{
			segment: seg,
			exit_speed: v_end,
			offered_acceleration: a,
		},
	| {
		d = seg.commit_along.distance_from(state.along)
		bend_a =
			if d <= VehicleLimits.least_braking_distance {
				Acceleration.steady
			} else {
				state.speed.acceleration_to({ target: v_end, within: d })
			}
		if bend_a < a {
			bend_a
		} else {
			a
		}
	}

	## The acceleration `a`, or none while the segment's crossing says the rider
	## may not accelerate. It stops the rider speeding up, and never brakes.
	crossing_limit : RiderState,
	{
		segment : World.Segment,
		offered_acceleration : Acceleration,
	} -> Acceleration
	crossing_limit = |state, { segment: seg, offered_acceleration: a }|
		match CrossingReaction.reaction_to(seg, state).throttle {
			NoAcceleration if a > Acceleration.steady => Acceleration.steady
			NoAcceleration | MayAccelerate => a
		}

	pig_limit : RiderState,
	{
		segment : World.Segment,
		offered_acceleration : Acceleration,
	} -> Acceleration
	pig_limit = |state, { segment: seg, offered_acceleration: a }| {
		b = Gaze.pig_gaze_brake(state, seg)
		if b.is_gawking {
			if b.acceleration < a {
				b.acceleration
			} else {
				a
			}
		} else {
			a
		}
	}

	brake_decay : Steps
	brake_decay = Steps.of(20)

	## The acceleration `a`, unless a coast from here leaves the road; then the
	## brake for the shoulder it reaches. One of the limits `acceleration`
	## passes the acceleration through in turn.
	shoulder_brake : RiderState, Acceleration -> Acceleration
	shoulder_brake = |state, a|
		match Coast.project(state).exit {
			StaysOn => a
			Leaves({ after: steps_to_shoulder, .. }) =>
				shoulder_brake_at(state, { steps_to_shoulder, offered_acceleration: a })
		}

	## The acceleration `a`, or the brake for a coast that leaves the road in
	## `steps_to_shoulder`, whichever is harder.
	shoulder_brake_at : RiderState,
	{
		steps_to_shoulder : Steps,
		offered_acceleration : Acceleration,
	} -> Acceleration
	shoulder_brake_at = |state, { steps_to_shoulder, offered_acceleration: a }| {
		n = steps_to_shoulder.to_f64()
		sa = Acceleration.metres_a_step_each_step(
			(
				(0.0 - state.speed.to_metres_a_step()) / (
					2.0 * DeviceMath.real_max(
						n,
						1.0,
					)
				)
			) * Float.exp((0.0 - n) / brake_decay.to_f64()),
		)
		if sa < a {
			sa
		} else {
			a
		}
	}

	allowed_speed : RiderState,
	{
		segment : World.Segment,
		exit_speed : Speed,
		next_speed : Speed,
		is_near_end : Bool,
	} -> Speed
	allowed_speed = |
		state,
		{
			segment: seg,
			exit_speed: v_end,
			next_speed: v0,
			is_near_end: near,
		},
	| {
		v1 =
			if v0 > VehicleLimits.top_speed {
				VehicleLimits.top_speed
			} else {
				v0
			}
		v2 =
			if v1 < Speed.at_rest {
				Speed.at_rest
			} else {
				v1
			}
		if near {
			if v2 < v_end {
				if Gaze.is_gawking(state, seg) {
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

	acceleration : RiderState, World.Segment -> Acceleration
	acceleration = |state, seg| {
		a0 =
			if state.lean.abs() >= lean_hold {
				Acceleration.steady
			} else {
				VehicleLimits.cruise_acceleration
			}
		v_end =
			match seg.ending {
				Continues(_) => VehicleLimits.turn_speed(seg.exit_turn.abs())
				Terminates => Speed.at_rest
			}
		left = Along.at(seg.length).distance_from(state.along)
		near = left <= VehicleLimits.bend_approach
		a1 =
			if near {
				bend_brake(
					state,
					{
						segment: seg,
						exit_speed: v_end,
						offered_acceleration: a0,
					},
				)
			} else {
				a0
			}
		a2 = crossing_limit(state, { segment: seg, offered_acceleration: a1 })
		a3 = pig_limit(state, { segment: seg, offered_acceleration: a2 })
		a4 = shoulder_brake(state, a3)
		allowed_speed(
			state,
			{
				segment: seg,
				exit_speed: v_end,
				next_speed: state.speed.accelerated_by(a4),
				is_near_end: near,
			},
		).change_from(state.speed)
	}
}

# Each is within 1e-12 of its want.
expect
	[
		(Throttle.lean_hold.to_radians(), 0.03490658503988659),
		(Throttle.brake_decay.to_f64(), 20.0),
		(Throttle.lean_hold.to_radians() / Trig.deg, 2.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

first_segment : World.Segment
first_segment = World.route_segment(0)

cat_segment : World.Segment
cat_segment = World.route_segment(3)

## A rider on the centre line, upright.
centred_rider : F64, F64 -> RiderState
centred_rider = |along, speed| {
	..RiderState.initial,
	along: Along.metres(along),
	speed: Speed.metres_a_step(speed),
}

## The bend brake for this rider, offered `offered`.
bend_brake_at : RiderState, F64 -> F64
bend_brake_at = |rider, offered|
	Throttle.bend_brake(
		rider,
		{
			segment: first_segment,
			exit_speed: Speed.metres_a_step(0.222),
			offered_acceleration: Acceleration.metres_a_step_each_step(offered),
		},
	).to_metres_a_step_each_step()

expect bend_brake_at(centred_rider(498.4, 0.3), 0.01) == 0.0
expect bend_brake_at(centred_rider(600.0, 0.3), 0.01) == 0.0
expect bend_brake_at(centred_rider(0.0, 0.3), -5.0) == -5.0

expect bend_brake_at(centred_rider(0.0, 0.3), 0.01) <= 0.01
expect bend_brake_at(centred_rider(0.0, 0.3), -5.0) <= -5.0
expect {
	fast = bend_brake_at(centred_rider(0.0, 2.0), 0.01)
	slow = bend_brake_at(centred_rider(0.0, 0.3), 0.01)
	fast < slow
}

## What the crossing limit lets through for a rider at `along` on `segment`.
limit_at : { segment : World.Segment, along : F64 }, F64 -> F64
limit_at = |{ segment, along }, offered|
	Throttle.crossing_limit(
		centred_rider(along, 0.3),
		{ segment, offered_acceleration: Acceleration.metres_a_step_each_step(offered) },
	).to_metres_a_step_each_step()

expect limit_at({ segment: first_segment, along: 0.0 }, 0.01) == 0.01
expect limit_at({ segment: first_segment, along: 0.0 }, -5.0) == -5.0
expect limit_at({ segment: cat_segment, along: 120.0 }, 0.01) == 0.0
expect limit_at({ segment: cat_segment, along: 120.0 }, -5.0) == -5.0
expect limit_at({ segment: cat_segment, along: 0.0 }, 0.01) == 0.01

## Throttle doesn't import Distance or Across, so these places and lengths come
## from what it does see.
across_at = |metres| RiderState.initial.across.plus(Speed.metres_a_step(metres).step_length())

## A rider steering hard left at `speed`.
rider_off_left : F64 -> RiderState
rider_off_left = |speed| { ..centred_rider(0.0, speed), yaw: Angle.Turn.radians(-1.5) }

expect Coast.project(rider_off_left(0.048)).exit == Leaves({ side: Left, after: Steps.of(40) })
expect Coast.project(rider_off_left(0.7)).exit == Leaves({ side: Left, after: Steps.of(2) })

# A coast that stays on the road takes what is offered, and one that leaves it
# brakes.
expect {
	offered = VehicleLimits.cruise_acceleration
	Throttle.shoulder_brake(centred_rider(0.0, 0.3), offered) == offered
		and Throttle.shoulder_brake(rider_off_left(0.7), offered) < Acceleration.steady
}

## The shoulder brake for a rider going 1 metre a step, offered `offered`.
brake_after : U32, F64 -> Acceleration
brake_after = |steps_to_shoulder, offered|
	Throttle.shoulder_brake_at(
		centred_rider(0.0, 1.0),
		{
			steps_to_shoulder: Steps.of(steps_to_shoulder),
			offered_acceleration: Acceleration.metres_a_step_each_step(offered),
		},
	)

expect brake_after(40, 0.01) < Acceleration.steady
expect brake_after(40, 0.01) > brake_after(2, 0.01)
expect
	brake_after(40, 0.0 - 9.0)
		< Acceleration.metres_a_step_each_step(0.0 - 8.999)

# A coast that leaves the road at once still brakes.
expect brake_after(0, 0.01) < Acceleration.steady

## The speed the clamp allows.
clamped_speed : { next_speed : F64, is_near_end : Bool } -> F64
clamped_speed = |{ next_speed, is_near_end }|
	Throttle.allowed_speed(
		centred_rider(0.0, 0.3),
		{
			segment: first_segment,
			exit_speed: Speed.metres_a_step(0.222),
			next_speed: Speed.metres_a_step(next_speed),
			is_near_end,
		},
	).to_metres_a_step()

expect clamped_speed({ next_speed: 1.0, is_near_end: False }) == 1.0
expect clamped_speed({ next_speed: 3.0, is_near_end: False }) == 2.5
expect clamped_speed({ next_speed: -1.0, is_near_end: False }) == 0.0
expect clamped_speed({ next_speed: 0.1, is_near_end: True }) == 0.222
expect clamped_speed({ next_speed: 0.5, is_near_end: True }) == 0.5
expect clamped_speed({ next_speed: 0.1, is_near_end: False }) == 0.1

## The whole decision for a rider at the start of the segment, on the centre
## line.
decide : Speed, F64 -> Acceleration
decide = |speed, lean|
	Throttle.acceleration(
		{ ..RiderState.initial, speed, lean: Angle.Lean.radians(lean) },
		first_segment,
	)

## The whole decision for a rider far off to the right.
wide_of_road : F64 -> Acceleration
wide_of_road = |lean|
	Throttle.acceleration(
		{
			..centred_rider(0.0, 0.3),
			across: across_at(100.0),
			lean: Angle.Lean.radians(lean),
		},
		first_segment,
	)

hold_radians : F64
hold_radians = Throttle.lean_hold.to_radians()

# Each is within 1e-12 of its want.
expect
	[
		(decide(Speed.metres_a_step(0.3), 0.0), 0.01),
		(decide(VehicleLimits.top_speed, 0.0), 0.0),
		(decide(Speed.at_rest, 0.0), 0.01),
		(wide_of_road(0.0 - 0.001), 0.01),
		(wide_of_road(0.0 - hold_radians), 0.0),
		(wide_of_road(0.0 - hold_radians - 0.5), 0.0),
	].all(|(got, want)| (got.to_metres_a_step_each_step() - want).abs() <= 0.000000000001)

expect decide(Speed.metres_a_step(0.3), hold_radians - 0.001) < Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.001) > Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.0 - (hold_radians - 0.001)) < Acceleration.steady

# These are Coast's projections. They sit here because Coast imports neither Speed
# nor VehicleLimits, and Throttle sees both.

## The coast of a rider at the start of the segment, going the base speed.
coast_of : F64, F64 -> Coast.Outcome
coast_of = |across, lean_radians|
	Coast.project({
		..RiderState.initial,
		across: across_at(across),
		lean: Angle.Lean.radians(lean_radians),
	})

straight : Coast.Outcome
straight = coast_of(0.0, 0.0)

wide : Coast.Outcome
wide = coast_of(3.0, 0.0)

stopped : Coast.Outcome
stopped = Coast.project({ ..RiderState.initial, speed: Speed.at_rest })

leaning : Coast.Outcome
leaning = coast_of(0.0, 0.2)

other_way : Coast.Outcome
other_way = coast_of(0.0, 0.0 - 0.2)

expect straight.forward.to_metres() == 25.0
expect straight.end_across.to_metres() == 0.0
expect wide.forward.to_metres() == 25.0
expect wide.end_across.to_metres() == 3.0
expect stopped.forward.to_metres() == 0.0
expect stopped.end_across.to_metres() == 0.0

expect straight.exit == StaysOn
expect wide.exit == StaysOn
expect stopped.exit == StaysOn

## How many steps a coast runs before it leaves the road.
steps_off_road : Coast.Outcome -> Steps
steps_off_road = |coast|
	match coast.exit {
		Leaves({ after, .. }) => after
		StaysOn => crash "Throttle's expects: this coast stays on the road"
	}

expect leaning.exit == Leaves({ side: Right, after: steps_off_road(leaning) })
expect other_way.exit == Leaves({ side: Left, after: steps_off_road(other_way) })

expect steps_off_road(leaning) < Coast.longest_coast
expect steps_off_road(leaning) > Steps.zero
expect leaning.forward <= Coast.clear_distance
expect leaning.end_across > RiderState.initial.across
expect other_way.end_across < RiderState.initial.across
expect steps_off_road(leaning) == steps_off_road(other_way)
expect leaning.end_across.to_metres() + other_way.end_across.to_metres() == 0.0

expect leaning.forward.minus(other_way.forward).to_metres().abs() <= 0.000001
