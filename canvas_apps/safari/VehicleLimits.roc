## VehicleLimits holds the speeds and accelerations that the rider and the truck
## keep to, and how fast each turn may be taken.
import Acceleration
import Angle
import Distance
import Speed

VehicleLimits :: [].{

	cruise_acceleration : Acceleration
	cruise_acceleration = Acceleration.metres_a_step_each_step(0.01)

	starting_speed : Speed
	starting_speed = Speed.metres_a_step(0.3)

	top_speed : Speed
	top_speed = Speed.metres_a_step(2.5)

	## The acceleration that brings `speed` to `target` within a distance. A
	## target closer than `least_braking_distance` counts as reached, and the
	## speed holds. That keeps the division off zero, and it has a second job:
	## braking to rest at the route's end closes on the end geometrically, each
	## step covering a share of what is left, and never gets there. Holding the
	## speed once the end is that close is what lets the rider arrive.
	##
	## The brake is steady over the whole distance left, so in the last steps
	## before a target one step of it can land a little under the target. At the
	## first bend the rider goes 0.239 m a step with 0.115 m left to a bend taken
	## at 0.222, and lands on 0.205. Nobody sees an undershoot that small, and a
	## brake that never undershoots would move the whole ride, so the brake stays
	## steady and the ride stays as it is. A brake
	## that would take the speed below zero in one step crashes here, with its
	## reason, rather than in `Speed`.
	braking_to : Speed, { target : Speed, within : Distance } -> Acceleration
	braking_to = |speed, { target, within }|
		if within <= least_braking_distance {
			Acceleration.steady
		} else {
			acceleration = speed.acceleration_to({ target, within })
			match speed.accelerated_by_try(acceleration) {
				Ok(_) => acceleration
				Err(BelowRest) => crash "VehicleLimits.braking_to: a brake that would take the speed below zero; the ride never brakes this hard"
			}
		}

	## The speed a turn can be taken at, to the right or the left alike. A turn
	## counts as the whole degree its size rounds to, and that must be one in
	## `turn_speeds`.
	turn_speed : Angle.Turn -> Speed
	turn_speed = |turn| {
		whole_degrees =
			turn.abs().to_degrees().round_to_u32_try()
				?? crash "VehicleLimits.turn_speed: a turn is a finite angle"
		match turn_speeds.find_first(|row| row.whole_degrees == whole_degrees) {
			Ok(row) => row.speed
			Err(NotFound) => crash "VehicleLimits.turn_speed: no speed for a turn of ${whole_degrees.to_str()} degrees"
		}
	}
}

## The shortest distance `braking_to` works a brake out over.
least_braking_distance : Distance
least_braking_distance = Distance.metres(0.000001)

## The turns a route can make, in whole degrees, and the speed each is taken at.
turn_speeds : List({ whole_degrees : U32, speed : Speed })
turn_speeds = [
	{ whole_degrees: 15, speed: Speed.metres_a_step(1.297) },
	{ whole_degrees: 20, speed: Speed.metres_a_step(0.84) },
	{ whole_degrees: 30, speed: Speed.metres_a_step(0.461) },
	{ whole_degrees: 50, speed: Speed.metres_a_step(0.222) },
	{ whole_degrees: 70, speed: Speed.metres_a_step(0.139) },
	{ whole_degrees: 80, speed: Speed.metres_a_step(0.117) },
]

## One step of `braking_to`'s brake, from `speed`.
speed_after_braking : Speed, { target : Speed, within : Distance } -> Speed
speed_after_braking = |speed, { target, within }|
	speed.accelerated_by(VehicleLimits.braking_to(speed, { target, within }))

# A brake that lands exactly at rest is the hardest one allowed, and it
# returns its acceleration. One harder would go below zero, which crashes, and
# an expect can't test a crash, so this is the boundary from the side that
# holds.
expect
	speed_after_braking(
		Speed.metres_a_step(0.5),
		{ target: Speed.at_rest, within: Distance.metres(0.25) },
	)
		== Speed.at_rest

# At the first bend the steady brake lands a little under the bend's speed,
# and that undershoot is kept.
expect {
	bend_speed = Speed.metres_a_step(0.222)
	landed = speed_after_braking(
		Speed.metres_a_step(0.239),
		{ target: bend_speed, within: Distance.metres(0.115) },
	)
	landed < bend_speed and landed > Speed.metres_a_step(0.204)
}

## The speed for a turn of this many degrees.
speed_for_turn : F64 -> F64
speed_for_turn = |degrees| VehicleLimits.turn_speed(Angle.Turn.degrees(degrees)).to_metres_a_step()

# A turn counts as the whole degree its size rounds to, either side of the
# table's, to the right or the left.
expect
	[
		(14.5, 1.297),
		(15.4, 1.297),
		(49.5, 0.222),
		(50.4, 0.222),
		(-14.5, 1.297),
		(-50.4, 0.222),
	].all(|(degrees, speed)| speed_for_turn(degrees) == speed)
