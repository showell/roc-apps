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

	v_max : Speed
	v_max = Speed.metres_a_step(2.5)

	approach_intersection_dist : F64
	approach_intersection_dist = 60.0

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
