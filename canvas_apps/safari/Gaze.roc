## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it, the rider slows to look, and the gaze eases back to the
## road once the pig is behind.
import Acceleration
import Angle
import Attention
import lib.DeviceMath
import Easing
import Fraction
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

	gaze_focus : Fraction -> Attention
	gaze_focus = |focus| Attention.from_fraction(Easing.smoothstep(focus))

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
	next_focus : Pose.RiderState, Angle.Turn -> Fraction
	next_focus = |state, gaze_yaw|
		if is_at_rest(gaze_yaw) {
			Fraction.clamp(state.focus.to_f64() - focus_decay)
		} else {
			state.focus.max(Fraction.clamp(gaze_yaw.abs().fraction_of(gaze_release_angle)))
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

# Each is within 1e-12 of its want.
expect
	[
		(Gaze.gaze_look_dist, 150.0),
		(Gaze.focus_decay, 0.0012),
		(Gaze.pig_gaze_speed.to_metres_a_step(), 0.2),
		(Gaze.pig_gaze_settle_dist, 25.0),
		(Gaze.gaze_release_angle.to_radians() / Trig.deg, 35.0),
		(Gaze.gaze_swivel_rate.to_radians() / Trig.deg, 4.0),
		(Gaze.gaze_return_rate.to_radians() / Trig.deg, 0.2),
		(Gaze.gaze_return_snap.to_radians() / Trig.deg, 0.02),
		(Gaze.eyes_on_road_yaw.to_radians() / Trig.deg, 6.0),
		(Gaze.gaze_return_ease, 0.05),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Gaze.gaze_focus(Fraction.of(0.5)).to_f64() == 0.5

plain : World.Segment
plain = World.route_segment(0)

distracting : World.Segment
distracting = World.route_segment(2)

expect plain.pig_attention == Unnoticed
expect distracting.pig_attention == Distracting

## A rider on the distracting segment, at rest in every other way.
rider : F64, F64 -> Pose.RiderState
rider = |along, yaw| {
	..Pose.initial_rider_state,
	segment: World.SegmentIndex.number(2),
	along,
	yaw: Angle.Turn.radians(yaw),
}

expect !(Gaze.pig_ahead(rider(200.0, 0.0), plain).looking)
expect !(Gaze.pig_ahead(rider(200.0, (10.0 * Trig.deg)), distracting).looking)
expect !(Gaze.pig_ahead(rider(100.0, 0.0), distracting).looking)
expect !(Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking)
expect Gaze.pig_ahead(rider(200.0, 0.0), distracting).looking
expect !Gaze.no_look.looking
expect Gaze.pig_ahead(rider(200.0, 0.0), distracting).dist == 142.0
expect Gaze.pig_ahead(rider(100.0, 0.0), distracting).dist == 0.0
expect Gaze.no_look.dist == 0.0

expect {
	far = Gaze.desired_gaze(rider(200.0, 0.0), distracting).to_radians()
	near = Gaze.desired_gaze(rider(320.0, 0.0), distracting).to_radians()
	far > 0.0 and near > far
}

expect Gaze.desired_gaze(rider(200.0, 0.0), plain).to_radians().to_bits() == F64.to_bits(0.0)

## A rider looking `gaze_yaw` from straight ahead.
head : F64, F64 -> Pose.RiderState
head = |gaze_yaw, along| {
	..rider(along, 0.0),
	gaze_yaw: Angle.Turn.radians(gaze_yaw),
}

## The gaze one step after `state`, wanting `want` radians.
gaze_after : Pose.RiderState, F64 -> F64
gaze_after = |state, want| Gaze.next_gaze_yaw(state, Angle.Turn.radians(want)).to_radians()

## The focus after the gaze moves to `gaze` radians.
focus_after : Pose.RiderState, F64 -> F64
focus_after = |state, gaze| Gaze.next_focus(state, Angle.Turn.radians(gaze)).to_f64()

swivel_rate : F64
swivel_rate = Gaze.gaze_swivel_rate.to_radians()

return_snap : F64
return_snap = Gaze.gaze_return_snap.to_radians()

expect gaze_after(head(0.0, 200.0), 1.0) - swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), (0.0 - 1.0)) + swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), (swivel_rate / 2.0)) - (swivel_rate / 2.0) == 0.0

expect {
	big = gaze_after(head((30.0 * Trig.deg), 200.0), 0.0)
	small = gaze_after(head((2.0 * Trig.deg), 200.0), 0.0)
	big < (30.0 * Trig.deg)
		and big > 0.0
		and small < (2.0 * Trig.deg)
		and small > 0.0
		and ((30.0 * Trig.deg) - big) > ((2.0 * Trig.deg) - small)
}

expect gaze_after(head(return_snap, 200.0), 0.0) == 0.0
expect gaze_after(head((0.0 - return_snap), 200.0), 0.0) == 0.0
expect gaze_after(head(0.0, 200.0), 0.0) == 0.0

## A rider with this focus, looking `gaze_yaw` from straight ahead.
rider_with_focus : F64, F64 -> Pose.RiderState
rider_with_focus = |focus, gaze_yaw| {
	..head(gaze_yaw, 200.0),
	focus: Fraction.of(focus),
}

expect {
	rising = focus_after(rider_with_focus(0.0, (20.0 * Trig.deg)), (20.0 * Trig.deg))
	held = focus_after(rider_with_focus(0.9, (1.0 * Trig.deg)), (1.0 * Trig.deg))
	easing = focus_after(rider_with_focus(0.9, 0.0), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

expect focus_after(rider_with_focus(0.0, 0.0), 0.0) == 0.0
expect focus_after(rider_with_focus(0.0, (90.0 * Trig.deg)), (90.0 * Trig.deg)) == 1.0
expect !(Gaze.gawk_engaged(rider(200.0, 0.0), plain))
expect !(Gaze.gawk_engaged(rider(100.0, 0.0), distracting))
expect Gaze.gawk_engaged(rider(200.0, 0.0), distracting)
expect Gaze.gawk_engaged(rider(341.0, 0.0), distracting)

# The gawking outlasts the look.
expect !Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking
expect Gaze.gawk_engaged(rider(341.0, 0.0), distracting)
