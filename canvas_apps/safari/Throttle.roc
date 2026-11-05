# Throttle -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Acceleration
import Angle
import Arc
import CrossingReaction
import lib.DeviceMath
import Distance
import Gaze
import Num_
import Pose
import Speed
import lib.Trig
import VehicleLimits
import World

Throttle :: [].{

	## The rider holds the throttle off while leaning this far or further.
	tilt_hold : Angle.Lean
	tilt_hold = Angle.Lean.degrees(2.0)

	corner_brake : Pose.RiderState,
	{
		road_segment : World.Segment,
		exit_speed : Speed,
		offered_accel : Acceleration,
	} -> Acceleration
	corner_brake = |
		state,
		{
			road_segment: seg,
			exit_speed: v_end,
			offered_accel: a,
		},
	| (
		{
			d = Distance.metres(seg.commit_along - state.along)
			corner_a = (
				if d <= VehicleLimits.least_braking_distance {
					Acceleration.steady
				} else {
					state.speed.acceleration_to({ target: v_end, within: d })
				}
			)
			(
				if corner_a < a {
					corner_a
				} else {
					a
				}
			)
		}
	)

	## The acceleration `a`, or none while the segment's crossing says the rider
	## may not accelerate. It stops the rider speeding up, and never brakes.
	crossing_gate : Pose.RiderState,
	{
		road_segment : World.Segment,
		offered_accel : Acceleration,
	} -> Acceleration
	crossing_gate = |state, { road_segment: seg, offered_accel: a }|
		match CrossingReaction.reaction_to(seg, state).throttle {
			NoAcceleration if a > Acceleration.steady => Acceleration.steady
			NoAcceleration | MayAccelerate => a
		}

	pig_gate : Pose.RiderState,
	{
		road_segment : World.Segment,
		offered_accel : Acceleration,
	} -> Acceleration
	pig_gate = |state, { road_segment: seg, offered_accel: a }| (
		{
			b = Gaze.pig_gaze_brake(state, seg)
			(
				if b.engaged {
					(
						if b.accel < a {
							b.accel
						} else {
							a
						}
					)
				} else {
					a
				}
			)
		}
	)

	brake_decay : F64
	brake_decay = 20.0

	## The acceleration `a`, unless the arc ahead leaves the road; then the
	## brake for the shoulder it reaches. One of the gates `get_forward_accel_decel`
	## passes the acceleration through in turn.
	shoulder_brake : Pose.RiderState, Acceleration -> Acceleration
	shoulder_brake = |state, a| (
		{
			sim = Arc.project_arc(state)
			(
				if has_stayed_on_road(sim) {
					a
				} else {
					shoulder_brake_at(state, { arc_outcome: sim, offered_accel: a })
				}
			)
		}
	)

	has_stayed_on_road : Arc.ArcOutcome -> Bool
	has_stayed_on_road = |sim| (
		match sim.shoulder {
			ShoulderNone => True
			ShoulderLeft => False
			ShoulderRight => False
		}
	)

	shoulder_brake_at : Pose.RiderState,
	{
		arc_outcome : Arc.ArcOutcome,
		offered_accel : Acceleration,
	} -> Acceleration
	shoulder_brake_at = |state, { arc_outcome: sim, offered_accel: a }| (
		{
			n = sim.frames.to_f64()
			sa = Acceleration.metres_a_step_each_step(
				(
					(0.0 - state.speed.to_metres_a_step()) / (
						2.0 * DeviceMath.real_max(
							n,
							1.0,
						)
					)
				) * Num_.exp_real(((0.0 - n) / brake_decay)),
			)
			(
				if sa < a {
					sa
				} else {
					a
				}
			)
		}
	)

	clamp_v : Pose.RiderState,
	{
		road_segment : World.Segment,
		exit_speed : Speed,
		next_speed : Speed,
		is_near_end : Bool,
	} -> Speed
	clamp_v = |
		state,
		{
			road_segment: seg,
			exit_speed: v_end,
			next_speed: v0,
			is_near_end: near,
		},
	| (
		{
			v1 = (
				if v0 > VehicleLimits.v_max {
					VehicleLimits.v_max
				} else {
					v0
				}
			)
			v2 = (
				if v1 < Speed.at_rest {
					Speed.at_rest
				} else {
					v1
				}
			)
			(
				if near {
					(
						if v2 < v_end {
							(
								if Gaze.gawk_engaged(state, seg) {
									v2
								} else {
									v_end
								}
							)
						} else {
							v2
						}
					)
				} else {
					v2
				}
			)
		}
	)

	get_forward_accel_decel : Pose.RiderState, World.Segment -> Acceleration
	get_forward_accel_decel = |state, seg| (
		{
			a0 = (
				if state.tilt.abs() >= tilt_hold {
					Acceleration.steady
				} else {
					VehicleLimits.a_accel
				}
			)
			v_end =
				match seg.ending {
					Continues(_) => VehicleLimits.turn_speed(seg.exit_turn.abs())
					Terminates => Speed.at_rest
				}
			left = Distance.metres(seg.length.to_metres() - state.along)
			near = left <= VehicleLimits.approach_intersection_dist
			a1 = (
				if near {
					corner_brake(
						state,
						{
							road_segment: seg,
							exit_speed: v_end,
							offered_accel: a0,
						},
					)
				} else {
					a0
				}
			)
			a2 = crossing_gate(state, { road_segment: seg, offered_accel: a1 })
			a3 = pig_gate(state, { road_segment: seg, offered_accel: a2 })
			a4 = shoulder_brake(state, a3)
			(
				clamp_v(
					state,
					{
						road_segment: seg,
						exit_speed: v_end,
						next_speed: state.speed.accelerated_by(a4),
						is_near_end: near,
					},
				).change_from(state.speed)
			)
		}
	)
}
