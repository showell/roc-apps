## VehicleLimits holds the speeds and accelerations that the rider and the truck
## keep to, and how fast each turn may be taken.
import Acceleration
import Angle
import Distance
import Speed

VehicleLimits :: [].{

	## What one limit on the throttle asks: nothing, or to accelerate no harder
	## than this.
	Limit : [NoLimit, AtMost(Acceleration)]

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
	braking_to : Speed, { target : Speed, within : Distance } -> Acceleration
	braking_to = |speed, { target, within }|
		if within <= least_braking_distance {
			Acceleration.steady
		} else {
			speed.acceleration_to({ target, within })
		}

	## The speed a turn can be taken at, to the right or the left alike. A turn
	## counts as the whole degree its size rounds to, and that must be one in
	## `turn_speeds`.
	turn_speed : Angle.Turn -> Speed
	turn_speed = |turn| {
		whole_degrees =
			(turn.abs().to_radians() * 180.0 / F64.pi).round_to_i64_try()
				?? crash "VehicleLimits.turn_speed: a turn is a finite angle"
		degrees = whole_degrees.to_f64()
		match turn_speeds.find_first(|row| row.degrees == degrees) {
			Ok(row) => row.speed
			Err(NotFound) => crash "VehicleLimits.turn_speed: no speed for a turn of ${degrees.to_str()} degrees"
		}
	}
}

## The shortest distance `braking_to` works a brake out over.
least_braking_distance : Distance
least_braking_distance = Distance.metres(0.000001)

## The turns a route can make, in whole degrees, and the speed each is taken at.
turn_speeds : List({ degrees : F64, speed : Speed })
turn_speeds = [
	{ degrees: 15.0, speed: Speed.metres_a_step(1.297) },
	{ degrees: 20.0, speed: Speed.metres_a_step(0.84) },
	{ degrees: 30.0, speed: Speed.metres_a_step(0.461) },
	{ degrees: 50.0, speed: Speed.metres_a_step(0.222) },
	{ degrees: 70.0, speed: Speed.metres_a_step(0.139) },
	{ degrees: 80.0, speed: Speed.metres_a_step(0.117) },
]

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
