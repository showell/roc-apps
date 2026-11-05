## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it, the rider slows to look, and the gaze eases back to the
## road once the pig is behind.
import Acceleration
import Angle
import lib.DeviceMath
import Pigs
import Pose
import Scenery
import Speed
import lib.Trig
import World

Gaze :: [].{
	PigLook : { looking : Bool, dist : F64 }
	GazeBrake : { engaged : Bool, accel : Acceleration }

	gaze_look_dist : F64
	gaze_look_dist = 150.0

	gaze_release_angle : Angle.Turn
	gaze_release_angle = Angle.Turn.degrees(35.0)

	gaze_swivel_rate : Angle.Turn
	gaze_swivel_rate = Angle.Turn.degrees(4.0)

	gaze_return_rate : Angle.Turn
	gaze_return_rate = Angle.Turn.degrees(0.2)

	gaze_return_ease : F64
	gaze_return_ease = 0.05

	gaze_return_snap : Angle.Turn
	gaze_return_snap = Angle.Turn.degrees(0.02)

	focus_decay : F64
	focus_decay = 0.0012

	pig_gaze_speed : Speed
	pig_gaze_speed = Speed.metres_a_step(0.2)

	pig_gaze_settle_dist : F64
	pig_gaze_settle_dist = 25.0

	eyes_on_road_yaw : Angle.Turn
	eyes_on_road_yaw = Angle.Turn.degrees(6.0)

	smoothstep : F64 -> F64
	smoothstep = |t| ((t * t) * (3.0 - (2.0 * t)))

	gaze_focus : F64 -> F64
	gaze_focus = |f| smoothstep(f)

	no_look : Gaze.PigLook
	no_look = { looking: False, dist: 0.0 }

	pig_ahead : Pose.RiderState, World.Segment -> Gaze.PigLook
	pig_ahead = |state, seg|
		match seg.pig_attention {
			Distracting =>
				if state.yaw.abs() > eyes_on_road_yaw {
					no_look
				} else {
					pig_ahead_near(state, seg)
				}
			Unnoticed => no_look
		}

	pig_ahead_near : Pose.RiderState, World.Segment -> Gaze.PigLook
	pig_ahead_near = |state, seg| (
		{
			pig = Pigs.gaze_pig(seg.length)
			dist = (pig.along - state.along)
			(
				if dist > gaze_look_dist {
					no_look
				} else {
					pig_in_sight(state, { gaze_pig: pig, distance_ahead: dist })
				}
			)
		}
	)

	## The pig `distance_ahead` up the road is in sight while it is less
	## than the release angle from the way the bike points.
	pig_in_sight : Pose.RiderState,
	{
		gaze_pig : Scenery.Critter,
		distance_ahead : F64,
	} -> Gaze.PigLook
	pig_in_sight = |state, { gaze_pig: pig, distance_ahead: dist }| {
		toward_pig = Angle.Turn.radians(
			Trig.r_atan2(
				pig.across - state.across,
				dist,
			),
		).minus(state.yaw)
		if toward_pig.abs() >= gaze_release_angle {
			no_look
		} else {
			{ looking: True, dist }
		}
	}

	## The turn the rider wants to look: toward the pig in sight, or
	## straight ahead.
	desired_gaze : Pose.RiderState, World.Segment -> Angle.Turn
	desired_gaze = |state, seg|
		if pig_ahead(state, seg).looking {
			desired_gaze_at(state, Pigs.gaze_pig(seg.length))
		} else {
			Angle.straight_ahead
		}

	desired_gaze_at : Pose.RiderState, Scenery.Critter -> Angle.Turn
	desired_gaze_at = |state, pig| Angle.Turn.radians(
		Trig.r_atan2(
			pig.across - state.across,
			pig.along - state.along,
		),
	).minus(state.yaw)

	## Whether a gaze is exactly the rest position: +0.0, which `desired_gaze`
	## answers when there is nothing to look at.
	is_at_rest : Angle.Turn -> Bool
	is_at_rest = |gaze| gaze.to_radians().to_bits() == F64.to_bits(0.0)

	## The gaze one step on. It swivels toward `want` at no more than the
	## swivel rate; with nothing to look at it eases back toward the road,
	## and snaps there once it is close.
	next_gaze_yaw : Pose.RiderState, Angle.Turn -> Angle.Turn
	next_gaze_yaw = |state, want| {
		gaze = state.gaze_yaw
		if !is_at_rest(want) {
			gaze.plus(want.minus(gaze).within(gaze_swivel_rate))
		} else if gaze.abs() <= gaze_return_snap {
			Angle.straight_ahead
		} else {
			easing = gaze_return_rate.min(gaze.abs().times(gaze_return_ease))
			direction = Trig.r_sign(gaze.to_radians())
			gaze.minus(easing.times(direction))
		}
	}

	## The rider's focus after the gaze moves to `gaze_yaw`: it fades while
	## the gaze rests, and rises with how far the gaze has turned.
	next_focus : Pose.RiderState, Angle.Turn -> F64
	next_focus = |state, gaze_yaw|
		if is_at_rest(gaze_yaw) {
			DeviceMath.real_max(0.0, state.focus - focus_decay)
		} else {
			DeviceMath.real_max(
				state.focus,
				DeviceMath.real_min(gaze_yaw.abs().fraction_of(gaze_release_angle), 1.0),
			)
		}

	next_rider_gaze : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	next_rider_gaze = |state, segs| {
		seg = state.segment.segment_in(segs)
		gaze_yaw = next_gaze_yaw(state, desired_gaze(state, seg))
		{
			..state,
			gaze_yaw,
			focus: next_focus(state, gaze_yaw),
		}
	}

	gawk_engaged : Pose.RiderState, World.Segment -> Bool
	gawk_engaged = |state, seg|
		match seg.pig_attention {
			Distracting => (state.along >= (Pigs.gaze_pig(seg.length).along - gaze_look_dist))
			Unnoticed => False
		}

	pig_gaze_brake : Pose.RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake = |state, seg| (
		if gawk_engaged(state, seg) == False {
			{ engaged: False, accel: Acceleration.steady }
		} else {
			(
				if state.speed <= pig_gaze_speed {
					{ engaged: True, accel: Acceleration.steady }
				} else {
					pig_gaze_brake_easing(state, seg)
				}
			)
		}
	)

	pig_gaze_brake_easing : Pose.RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake_easing = |state, seg| (
		{
			d = ((Pigs.gaze_pig(seg.length).along - state.along) - pig_gaze_settle_dist)
			{
				engaged: True,
				accel: state.speed.acceleration_to({
					target: pig_gaze_speed,
					within: DeviceMath.real_max(d, 1.0),
				}),
			}
		}
	)
}
