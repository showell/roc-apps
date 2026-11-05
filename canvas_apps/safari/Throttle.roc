# Throttle -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Acceleration
import Along
import Angle
import Arc
import CrossingReaction
import lib.DeviceMath
import Gaze
import Num_
import Pose
import Speed
import Steps
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
			d = seg.commit_along.distance_from(state.along)
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
	shoulder_brake = |state, a|
		match Arc.project_arc(state).shoulder {
			ShoulderNone => a
			ShoulderLeft(frames) | ShoulderRight(frames) =>
				shoulder_brake_at(state, { frames, offered_accel: a })
		}

	## The acceleration `a`, or the brake for an arc that leaves the road in
	## `frames`, whichever is harder.
	shoulder_brake_at : Pose.RiderState,
	{
		frames : Steps,
		offered_accel : Acceleration,
	} -> Acceleration
	shoulder_brake_at = |state, { frames, offered_accel: a }| (
		{
			n = frames.to_f64()
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
			left = Along.at(seg.length).distance_from(state.along)
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

# Each is within 1e-12 of its want.
expect
	[
		(Throttle.tilt_hold.to_radians(), 0.03490658503988659),
		(Throttle.brake_decay, 20.0),
		(Throttle.tilt_hold.to_radians() / Trig.deg, 2.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

first_segment : World.Segment
first_segment = World.route_segment(0)

cat_segment : World.Segment
cat_segment = World.route_segment(3)

## A rider on the centre line, upright.
centred_rider : F64, F64 -> Pose.RiderState
centred_rider = |along, speed| {
	..Pose.initial_rider_state,
	along: Along.metres(along),
	speed: Speed.metres_a_step(speed),
}

## The corner brake for this rider, offered `offered`.
corner_brake_at : Pose.RiderState, F64 -> F64
corner_brake_at = |rider, offered|
	Throttle.corner_brake(
		rider,
		{
			road_segment: first_segment,
			exit_speed: Speed.metres_a_step(0.222),
			offered_accel: Acceleration.metres_a_step_each_step(offered),
		},
	).to_metres_a_step_each_step()

expect corner_brake_at(centred_rider(498.4, 0.3), 0.01) == 0.0
expect corner_brake_at(centred_rider(600.0, 0.3), 0.01) == 0.0
expect corner_brake_at(centred_rider(0.0, 0.3), -5.0) == -5.0

expect corner_brake_at(centred_rider(0.0, 0.3), 0.01) <= 0.01
expect corner_brake_at(centred_rider(0.0, 0.3), -5.0) <= -5.0
expect {
	fast = corner_brake_at(centred_rider(0.0, 2.0), 0.01)
	slow = corner_brake_at(centred_rider(0.0, 0.3), 0.01)
	fast < slow
}

## What the crossing gate lets through for a rider at `along` on `road_segment`.
gate_at : { road_segment : World.Segment, along : F64 }, F64 -> F64
gate_at = |{ road_segment, along }, offered|
	Throttle.crossing_gate(
		centred_rider(along, 0.3),
		{ road_segment, offered_accel: Acceleration.metres_a_step_each_step(offered) },
	).to_metres_a_step_each_step()

expect gate_at({ road_segment: first_segment, along: 0.0 }, 0.01) == 0.01
expect gate_at({ road_segment: first_segment, along: 0.0 }, -5.0) == -5.0
expect gate_at({ road_segment: cat_segment, along: 120.0 }, 0.01) == 0.0
expect gate_at({ road_segment: cat_segment, along: 120.0 }, -5.0) == -5.0
expect gate_at({ road_segment: cat_segment, along: 0.0 }, 0.01) == 0.01

## Throttle doesn't import Across, so these places come from what it does see.
across_at = |metres| Pose.initial_rider_state.across.plus(Speed.metres_a_step(metres).step_length())

## A rider steering hard left at `speed`.
rider_off_left : F64 -> Pose.RiderState
rider_off_left = |speed| {
	..centred_rider(0.0, speed),
	yaw: Angle.Turn.radians(-1.5),
}

expect Arc.project_arc(rider_off_left(0.048)).shoulder == ShoulderLeft(Steps.of(40))
expect Arc.project_arc(rider_off_left(0.7)).shoulder == ShoulderLeft(Steps.of(2))

# An arc that stays on the road takes what is offered, and one that leaves it
# brakes.
expect {
	offered = VehicleLimits.a_accel
	Throttle.shoulder_brake(centred_rider(0.0, 0.3), offered) == offered
		and Throttle.shoulder_brake(rider_off_left(0.7), offered) < Acceleration.steady
}

## The shoulder brake for a rider going 1 metre a step, offered `offered`.
brake_in_frames : U32, F64 -> Acceleration
brake_in_frames = |frames, offered|
	Throttle.shoulder_brake_at(
		centred_rider(0.0, 1.0),
		{
			frames: Steps.of(frames),
			offered_accel: Acceleration.metres_a_step_each_step(offered),
		},
	)

expect brake_in_frames(40, 0.01) < Acceleration.steady
expect brake_in_frames(40, 0.01) > brake_in_frames(2, 0.01)
expect
	brake_in_frames(40, 0.0 - 9.0)
		< Acceleration.metres_a_step_each_step(0.0 - 8.999)

# An arc that leaves the road at once still brakes.
expect brake_in_frames(0, 0.01) < Acceleration.steady

## The speed the clamp allows.
clamped_speed : { next_speed : F64, is_near_end : Bool } -> F64
clamped_speed = |{ next_speed, is_near_end }|
	Throttle.clamp_v(
		centred_rider(0.0, 0.3),
		{
			road_segment: first_segment,
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
decide = |speed, tilt|
	Throttle.get_forward_accel_decel(
		{
			..Pose.initial_rider_state,
			speed,
			tilt: Angle.Lean.radians(tilt),
		},
		first_segment,
	)

## The whole decision for a rider far off to the right.
wide_of_road : F64 -> Acceleration
wide_of_road = |tilt|
	Throttle.get_forward_accel_decel(
		{
			..centred_rider(0.0, 0.3),
			across: across_at(100.0),
			tilt: Angle.Lean.radians(tilt),
		},
		first_segment,
	)

hold_radians : F64
hold_radians = Throttle.tilt_hold.to_radians()

# Each is within 1e-12 of its want.
expect
	[
		(decide(Speed.metres_a_step(0.3), 0.0), 0.01),
		(decide(VehicleLimits.v_max, 0.0), 0.0),
		(decide(Speed.at_rest, 0.0), 0.01),
		(wide_of_road(0.0 - 0.001), 0.01),
		(wide_of_road(0.0 - hold_radians), 0.0),
		(wide_of_road((0.0 - hold_radians) - 0.5), 0.0),
	].all(|(got, want)| (got.to_metres_a_step_each_step() - want).abs() <= 0.000000000001)

expect decide(Speed.metres_a_step(0.3), hold_radians - 0.001) < Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.001) > Acceleration.steady
expect decide(Speed.metres_a_step(0.3), 0.0 - (hold_radians - 0.001)) < Acceleration.steady

# These are Arc's projections. They sit here because Arc imports neither Speed
# nor VehicleLimits, and Throttle sees both.

## The arc of a rider at the start of the segment, going the base speed.
arc_from : F64, F64 -> Arc.ArcOutcome
arc_from = |across, tilt_radians|
	Arc.project_arc({
		..Pose.initial_rider_state,
		across: across_at(across),
		tilt: Angle.Lean.radians(tilt_radians),
	})

straight : Arc.ArcOutcome
straight = arc_from(0.0, 0.0)

wide : Arc.ArcOutcome
wide = arc_from(3.0, 0.0)

stopped : Arc.ArcOutcome
stopped = Arc.project_arc({ ..Pose.initial_rider_state, speed: Speed.at_rest })

leaning : Arc.ArcOutcome
leaning = arc_from(0.0, 0.2)

other_way : Arc.ArcOutcome
other_way = arc_from(0.0, 0.0 - 0.2)

expect straight.forward.to_metres() == 25.0
expect straight.end_across.to_metres() == 0.0
expect wide.forward.to_metres() == 25.0
expect wide.end_across.to_metres() == 3.0
expect stopped.forward.to_metres() == 0.0
expect stopped.end_across.to_metres() == 0.0

expect straight.shoulder == ShoulderNone
expect wide.shoulder == ShoulderNone
expect stopped.shoulder == ShoulderNone

## How many frames an arc runs before it leaves the road.
frames_off_road : Arc.ArcOutcome -> Steps
frames_off_road = |arc|
	match arc.shoulder {
		ShoulderLeft(frames) | ShoulderRight(frames) => frames
		ShoulderNone => crash "Throttle's expects: this arc stays on the road"
	}

expect leaning.shoulder == ShoulderRight(frames_off_road(leaning))
expect other_way.shoulder == ShoulderLeft(frames_off_road(other_way))

expect frames_off_road(leaning) < Arc.turn_danger_steps
expect frames_off_road(leaning) > Steps.zero
expect leaning.forward <= Arc.min_forward_progress
expect leaning.end_across > Pose.initial_rider_state.across
expect other_way.end_across < Pose.initial_rider_state.across
expect frames_off_road(leaning) == frames_off_road(other_way)
expect leaning.end_across.to_metres() + other_way.end_across.to_metres() == 0.0

expect leaning.forward.minus(other_way.forward).to_metres().abs() <= 0.000001
