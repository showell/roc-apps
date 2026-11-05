# VehicleLimits -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Acceleration
import Angle
import Num_
import Speed
import lib.Trig

VehicleLimits :: [].{

	a_accel : Acceleration
	a_accel = Acceleration.metres_a_step_each_step(0.01)

	v_base : Speed
	v_base = Speed.metres_a_step(0.3)

	v_max : Speed
	v_max = Speed.metres_a_step(2.5)

	approach_intersection_dist : F64
	approach_intersection_dist = 60.0

	## The braking for a turn is worked out over the distance left to it, so a
	## turn closer than this counts as reached, and no division is by zero.
	least_braking_distance : F64
	least_braking_distance = 0.000001

	## The speed a turn of this size can be taken at, to the right or the left
	## alike: a caller passes the turn's `abs`.
	turn_speed : Angle.Turn -> Speed
	turn_speed = |turn| (
		{
			d = Num_.round_real(((turn.to_radians() * 180.0) / Trig.pi))
			Speed.metres_a_step(
				if d.to_bits() == F64.to_bits(15.0) {
					1.297
				} else {
					(
						if d.to_bits() == F64.to_bits(20.0) {
							0.84
						} else {
							(
								if d.to_bits() == F64.to_bits(30.0) {
									0.461
								} else {
									(
										if d.to_bits() == F64.to_bits(50.0) {
											0.222
										} else {
											(
												if d.to_bits() == F64.to_bits(70.0) {
													0.139
												} else {
													(
														if d.to_bits() == F64.to_bits(80.0) {
															0.117
														} else {
															0.222
														}
													)
												}
											)
										}
									)
								}
							)
						}
					)
				},
			)
		}
	)
}

expect VehicleLimits.a_accel.to_metres_a_step_each_step() == 0.01
expect VehicleLimits.v_max.to_metres_a_step() == 2.5
expect VehicleLimits.approach_intersection_dist == 60.0

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

# A turn counts as the whole degree it rounds to, and takes its speed the same
# either way. Any turn not in the table takes the 50 degree speed.
expect
	[
		(14.5, 1.297),
		(14.4, 0.222),
		(15.4, 1.297),
		(15.5, 0.222),
		(30.5, 0.222),
		(0.0, 0.222),
		(-15.0, 0.222),
		(-50.0, 0.222),
	].all(|(degrees, speed)| speed_for_turn(degrees) == speed)
