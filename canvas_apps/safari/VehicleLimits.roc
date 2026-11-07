## VehicleLimits holds the speeds and accelerations that the rider and the truck
## keep to, and how fast each turn may be taken.
import Acceleration
import Angle
import Distance
import Speed

VehicleLimits :: [].{

	cruise_acceleration : Acceleration
	cruise_acceleration = Acceleration.metres_a_step_each_step(0.01)

	base_speed : Speed
	base_speed = Speed.metres_a_step(0.3)

	top_speed : Speed
	top_speed = Speed.metres_a_step(2.5)

	bend_approach : Distance
	bend_approach = Distance.metres(60.0)

	## The braking for a turn is worked out over the distance left to it, so a
	## turn closer than this counts as reached, and no division is by zero.
	least_braking_distance : Distance
	least_braking_distance = Distance.metres(0.000001)

	## The turns a route can make, in whole degrees, and the speed each is
	## taken at.
	turn_speeds : List({ degrees : F64, speed : Speed })
	turn_speeds = [
		{ degrees: 15.0, speed: Speed.metres_a_step(1.297) },
		{ degrees: 20.0, speed: Speed.metres_a_step(0.84) },
		{ degrees: 30.0, speed: Speed.metres_a_step(0.461) },
		{ degrees: 50.0, speed: Speed.metres_a_step(0.222) },
		{ degrees: 70.0, speed: Speed.metres_a_step(0.139) },
		{ degrees: 80.0, speed: Speed.metres_a_step(0.117) },
	]

	## The speed a turn of this size can be taken at, to the right or the left
	## alike: a caller passes the turn's `abs`. A turn counts as the whole
	## degree it rounds to, and that must be one in `turn_speeds`.
	turn_speed : Angle.Turn -> Speed
	turn_speed = |turn| {
		whole_degrees =
			(turn.to_radians() * 180.0 / F64.pi).round_to_i64_try()
				?? crash "VehicleLimits.turn_speed: a turn is a finite angle"
		degrees = whole_degrees.to_f64()
		match turn_speeds.find_first(|row| row.degrees == degrees) {
			Ok(row) => row.speed
			Err(NotFound) => crash "VehicleLimits.turn_speed: no speed for a turn of ${degrees.to_str()} degrees"
		}
	}
}

## The speed for a turn of this many degrees.
speed_for_turn : F64 -> F64
speed_for_turn = |degrees| VehicleLimits.turn_speed(Angle.Turn.degrees(degrees)).to_metres_a_step()

expect
	[
		(15.0, 1.297),
		(20.0, 0.84),
		(30.0, 0.461),
		(50.0, 0.222),
		(70.0, 0.139),
		(80.0, 0.117),
	].all(|(degrees, speed)| speed_for_turn(degrees) == speed)

# A turn counts as the whole degree it rounds to, either side of the table's.
expect
	[
		(14.5, 1.297),
		(15.4, 1.297),
		(49.5, 0.222),
		(50.4, 0.222),
	].all(|(degrees, speed)| speed_for_turn(degrees) == speed)
