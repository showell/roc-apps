# VehicleLimits -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Num_
import Trig

VehicleLimits :: [].{

	a_accel : F64
	a_accel = 0.01

	v_max : F64
	v_max = 2.5

	approach_intersection_dist : F64
	approach_intersection_dist = 60.0

	turn_speed : F64 -> F64
	turn_speed = |angle_rad| ({
		d = Num_.round_real(((angle_rad * 180.0) / Trig.pi))
		(if (F64.to_bits(d) == F64.to_bits(15.0)) { 1.297 } else { (if (F64.to_bits(d) == F64.to_bits(20.0)) { 0.84 } else { (if (F64.to_bits(d) == F64.to_bits(30.0)) { 0.461 } else { (if (F64.to_bits(d) == F64.to_bits(50.0)) { 0.222 } else { (if (F64.to_bits(d) == F64.to_bits(70.0)) { 0.139 } else { (if (F64.to_bits(d) == F64.to_bits(80.0)) { 0.117 } else { 0.222 }) }) }) }) }) })
	})
}
