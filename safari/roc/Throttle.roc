# Throttle -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Arc
import Cat
import DeviceMath
import Gaze
import Num_
import Pose
import Trig
import VehicleLimits
import World

Throttle :: [].{

	tilt_hold : F64
	tilt_hold = (2.0 * Trig.deg)

	corner_brake : Pose.RiderState, World.Segment, F64, F64 -> F64
	corner_brake = |state, seg, v_end, a| ({
		d = (seg.commit_along - state.along)
		corner_a = (if (d <= F64.from_bits(4517329193108106637)) { 0.0 } else { (((v_end * v_end) - (state.v * state.v)) / (2.0 * d)) })
		(if (corner_a < a) { corner_a } else { a })
	})

	cat_gate : Pose.RiderState, World.Segment, F64 -> F64
	cat_gate = |state, seg, a| (if seg.has_cat { (if (a > 0.0) { (if Cat.cat_in_danger((seg.cat.along - state.along), state.v) { 0.0 } else { a }) } else { a }) } else { a })

	pig_gate : Pose.RiderState, World.Segment, F64 -> F64
	pig_gate = |state, seg, a| ({
		b = Gaze.pig_gaze_brake(state, seg)
		(if b.engaged { (if (b.accel < a) { b.accel } else { a }) } else { a })
	})

	brake_decay : F64
	brake_decay = 20.0

	shoulder_brake : Pose.RiderState, World.Segment, F64 -> F64
	shoulder_brake = |state, seg, a| ({
		sim = Arc.project_arc(state, seg)
		(if stayed_on_road(sim) { a } else { shoulder_brake_at(state, sim, a) })
	})

	stayed_on_road : Arc.ArcOutcome -> Bool
	stayed_on_road = |sim| (match sim.shoulder {
		ShoulderNone => True
		ShoulderLeft => False
		ShoulderRight => False
	})

	shoulder_brake_at : Pose.RiderState, Arc.ArcOutcome, F64 -> F64
	shoulder_brake_at = |state, sim, a| ({
		n = sim.frames
		sa = (((0.0 - state.v) / (2.0 * DeviceMath.real_max(n, 1.0))) * Num_.exp_real(((0.0 - n) / brake_decay)))
		(if (sa < a) { sa } else { a })
	})

	clamp_v : Pose.RiderState, World.Segment, F64, F64, Bool -> F64
	clamp_v = |state, seg, v_end, v0, near| ({
		v1 = (if (v0 > VehicleLimits.v_max) { VehicleLimits.v_max } else { v0 })
		v2 = (if (v1 < 0.0) { 0.0 } else { v1 })
		(if near { (if (v2 < v_end) { (if Gaze.gawk_engaged(state, seg) { v2 } else { v_end }) } else { v2 }) } else { v2 })
	})

	get_forward_accel_decel : Pose.RiderState, World.Segment -> F64
	get_forward_accel_decel = |state, seg| ({
		a0 = (if (DeviceMath.real_abs(state.tilt) >= tilt_hold) { 0.0 } else { VehicleLimits.a_accel })
		v_end = (if seg.terminates { 0.0 } else { VehicleLimits.turn_speed(seg.exit_angle) })
		near = ((seg.length - state.along) <= VehicleLimits.approach_intersection_dist)
		a1 = (if near { corner_brake(state, seg, v_end, a0) } else { a0 })
		a3 = pig_gate(state, seg, cat_gate(state, seg, a1))
		a4 = shoulder_brake(state, seg, a3)
		(clamp_v(state, seg, v_end, (state.v + a4), near) - state.v)
	})
}
