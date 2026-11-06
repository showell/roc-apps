## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it, the rider slows to look, and the gaze eases back to the
## road once the pig is behind.
import Acceleration
import Angle
import Attention
import Distance
import Easing
import Fraction
import Pigs
import RiderState
import Scenery
import Speed
import lib.Trig
import World

Gaze :: [].{
	PigLook : { looking : Bool, dist : Distance }
	GazeBrake : { engaged : Bool, accel : Acceleration }

	## Where the rider wants to look: at the pig in sight, this far from the
	## way the bike points, or at the road.
	GazeTarget : [OnPig(Angle.Turn), OnRoad]

	gaze_look_dist : Distance
	gaze_look_dist = Distance.metres(150.0)

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

	attention_decay : F64
	attention_decay = 0.0012

	pig_gaze_speed : Speed
	pig_gaze_speed = Speed.metres_a_step(0.2)

	pig_gaze_settle_dist : Distance
	pig_gaze_settle_dist = Distance.metres(25.0)

	eyes_on_road_yaw : Angle.Turn
	eyes_on_road_yaw = Angle.Turn.degrees(6.0)

	gaze_attention : Fraction -> Attention
	gaze_attention = |attention| Attention.from_fraction(Easing.smoothstep(attention))

	no_look : Gaze.PigLook
	no_look = { looking: False, dist: Distance.zero }

	pig_ahead : RiderState, World.Segment -> Gaze.PigLook
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

	pig_ahead_near : RiderState, World.Segment -> Gaze.PigLook
	pig_ahead_near = |state, seg| {
		pig = Pigs.gaze_pig(seg.length)
		dist = pig.along.distance_from(state.along)
		if dist > gaze_look_dist {
			no_look
		} else {
			pig_in_sight(state, { gaze_pig: pig, distance_ahead: dist })
		}
	}

	## The pig `distance_ahead` up the road is in sight while it is less
	## than the release angle from the way the bike points.
	pig_in_sight : RiderState,
	{
		gaze_pig : Scenery.Critter,
		distance_ahead : Distance,
	} -> Gaze.PigLook
	pig_in_sight = |state, { gaze_pig: pig, distance_ahead: dist }| {
		toward_pig = Angle.Turn.radians(
			Trig.r_atan2(pig.across.distance_from(state.across).to_metres(), dist.to_metres()),
		).minus(state.yaw)
		if toward_pig.abs() >= gaze_release_angle {
			no_look
		} else {
			{ looking: True, dist }
		}
	}

	## Where the rider wants to look: the pig in sight, or else the road.
	desired_gaze : RiderState, World.Segment -> Gaze.GazeTarget
	desired_gaze = |state, seg|
		if pig_ahead(state, seg).looking {
			OnPig(desired_gaze_at(state, Pigs.gaze_pig(seg.length)))
		} else {
			OnRoad
		}

	desired_gaze_at : RiderState, Scenery.Critter -> Angle.Turn
	desired_gaze_at = |state, pig| Angle.Turn.radians(
		Trig.r_atan2(
			pig.across.distance_from(state.across).to_metres(),
			pig.along.distance_from(state.along).to_metres(),
		),
	).minus(state.yaw)

	## The gaze one step on. It swivels toward a pig at no more than the
	## swivel rate; with only the road to look at it eases back, and snaps
	## there once it is close.
	next_gaze_yaw : RiderState, Gaze.GazeTarget -> Angle.Turn
	next_gaze_yaw = |state, target| {
		gaze = state.gaze_yaw
		match target {
			OnPig(want) => gaze.plus(want.minus(gaze).within(gaze_swivel_rate))
			OnRoad =>
				if gaze.abs() <= gaze_return_snap {
					Angle.straight_ahead
				} else {
					easing = gaze_return_rate.min(gaze.abs().times(gaze_return_ease))
					direction = Trig.r_sign(gaze.to_radians())
					gaze.minus(easing.times(direction))
				}
		}
	}

	## The rider's attention after the gaze moves to `gaze_yaw`: it fades while
	## the gaze rests, and rises with how far the gaze has turned.
	next_attention : RiderState, Angle.Turn -> Fraction
	next_attention = |state, gaze_yaw|
		if gaze_yaw == Angle.straight_ahead {
			Fraction.clamp(state.attention.to_f64() - attention_decay)
		} else {
			state.attention.max(Fraction.clamp(gaze_yaw.abs().fraction_of(gaze_release_angle)))
		}

	next_rider_gaze : RiderState, List(World.Segment) -> RiderState
	next_rider_gaze = |state, route| {
		seg = state.segment.segment_in(route)
		gaze_yaw = next_gaze_yaw(state, desired_gaze(state, seg))
		{
			..state,
			gaze_yaw,
			attention: next_attention(state, gaze_yaw),
		}
	}

	gawk_engaged : RiderState, World.Segment -> Bool
	gawk_engaged = |state, seg|
		match seg.pig_attention {
			Distracting => state.along >= Pigs.gaze_pig(seg.length).along.minus(gaze_look_dist)
			Unnoticed => False
		}

	pig_gaze_brake : RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake = |state, seg|
		if gawk_engaged(state, seg) == False {
			{ engaged: False, accel: Acceleration.steady }
		} else if state.speed <= pig_gaze_speed {
			{ engaged: True, accel: Acceleration.steady }
		} else {
			pig_gaze_brake_easing(state, seg)
		}

	pig_gaze_brake_easing : RiderState, World.Segment -> Gaze.GazeBrake
	pig_gaze_brake_easing = |state, seg| {
		pig = Pigs.gaze_pig(seg.length)
		d = pig.along.distance_from(state.along).minus(pig_gaze_settle_dist)
		{
			engaged: True,
			accel: state.speed.acceleration_to({
				target: pig_gaze_speed,
				within: d.max(Distance.metres(1.0)),
			}),
		}
	}
}

# Each is within 1e-12 of its want.
expect
	[
		(Gaze.gaze_look_dist.to_metres(), 150.0),
		(Gaze.attention_decay, 0.0012),
		(Gaze.pig_gaze_speed.to_metres_a_step(), 0.2),
		(Gaze.pig_gaze_settle_dist.to_metres(), 25.0),
		(Gaze.gaze_release_angle.to_radians() / Trig.deg, 35.0),
		(Gaze.gaze_swivel_rate.to_radians() / Trig.deg, 4.0),
		(Gaze.gaze_return_rate.to_radians() / Trig.deg, 0.2),
		(Gaze.gaze_return_snap.to_radians() / Trig.deg, 0.02),
		(Gaze.eyes_on_road_yaw.to_radians() / Trig.deg, 6.0),
		(Gaze.gaze_return_ease, 0.05),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Gaze.gaze_attention(Fraction.of(0.5)).to_f64() == 0.5

plain : World.Segment
plain = World.route_segment(0)

distracting : World.Segment
distracting = World.route_segment(2)

expect plain.pig_attention == Unnoticed
expect distracting.pig_attention == Distracting

## A rider on the distracting segment, at rest in every other way. Gaze doesn't
## import Along, so `along` is a distance from the segment's start.
rider : F64, F64 -> RiderState
rider = |along, yaw| {
	..RiderState.initial,
	segment: World.SegmentIndex.number(2),
	along: RiderState.initial.along.plus(Distance.metres(along)),
	yaw: Angle.Turn.radians(yaw),
}

expect !(Gaze.pig_ahead(rider(200.0, 0.0), plain).looking)
expect !(Gaze.pig_ahead(rider(200.0, (10.0 * Trig.deg)), distracting).looking)
expect !(Gaze.pig_ahead(rider(100.0, 0.0), distracting).looking)
expect !(Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking)
expect Gaze.pig_ahead(rider(200.0, 0.0), distracting).looking
expect !Gaze.no_look.looking
expect Gaze.pig_ahead(rider(200.0, 0.0), distracting).dist.to_metres() == 142.0
expect Gaze.pig_ahead(rider(100.0, 0.0), distracting).dist.to_metres() == 0.0
expect Gaze.no_look.dist.to_metres() == 0.0

## How far this rider on the distracting segment wants to turn to the pig.
turn_to_pig : RiderState -> F64
turn_to_pig = |state|
	match Gaze.desired_gaze(state, distracting) {
		OnPig(turn) => turn.to_radians()
		OnRoad => crash "Gaze's expects: no pig in sight"
	}

expect {
	far = turn_to_pig(rider(200.0, 0.0))
	near = turn_to_pig(rider(320.0, 0.0))
	far > 0.0 and near > far
}

expect Gaze.desired_gaze(rider(200.0, 0.0), plain) == OnRoad
expect Gaze.desired_gaze(rider(100.0, 0.0), distracting) == OnRoad

## A rider looking `gaze_yaw` from straight ahead.
head : F64, F64 -> RiderState
head = |gaze_yaw, along| { ..rider(along, 0.0), gaze_yaw: Angle.Turn.radians(gaze_yaw) }

## The gaze one step after `state`, wanting a pig `want` radians off.
gaze_after : RiderState, F64 -> F64
gaze_after = |state, want| Gaze.next_gaze_yaw(state, OnPig(Angle.Turn.radians(want))).to_radians()

## The gaze one step after `state`, with only the road to look at.
gaze_returning : RiderState -> F64
gaze_returning = |state| Gaze.next_gaze_yaw(state, OnRoad).to_radians()

## The attention after the gaze moves to `gaze` radians.
attention_after : RiderState, F64 -> F64
attention_after = |state, gaze| Gaze.next_attention(state, Angle.Turn.radians(gaze)).to_f64()

swivel_rate : F64
swivel_rate = Gaze.gaze_swivel_rate.to_radians()

return_snap : F64
return_snap = Gaze.gaze_return_snap.to_radians()

expect gaze_after(head(0.0, 200.0), 1.0) - swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), (0.0 - 1.0)) + swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), (swivel_rate / 2.0)) - (swivel_rate / 2.0) == 0.0

expect {
	big = gaze_returning(head((30.0 * Trig.deg), 200.0))
	small = gaze_returning(head((2.0 * Trig.deg), 200.0))
	big < (30.0 * Trig.deg)
		and big > 0.0
		and small < (2.0 * Trig.deg)
		and small > 0.0
		and ((30.0 * Trig.deg) - big) > ((2.0 * Trig.deg) - small)
}

expect gaze_returning(head(return_snap, 200.0)) == 0.0
expect gaze_returning(head((0.0 - return_snap), 200.0)) == 0.0
expect gaze_returning(head(0.0, 200.0)) == 0.0

# A pig dead ahead is still a pig: the gaze swivels to it, and doesn't ease.
expect gaze_after(head((2.0 * Trig.deg), 200.0), 0.0) == 0.0

## A rider with this attention, looking `gaze_yaw` from straight ahead.
rider_with_attention : F64, F64 -> RiderState
rider_with_attention = |attention, gaze_yaw| {
	..head(gaze_yaw, 200.0),
	attention: Fraction.of(attention),
}

expect {
	rising = attention_after(rider_with_attention(0.0, (20.0 * Trig.deg)), (20.0 * Trig.deg))
	held = attention_after(rider_with_attention(0.9, (1.0 * Trig.deg)), (1.0 * Trig.deg))
	easing = attention_after(rider_with_attention(0.9, 0.0), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

expect attention_after(rider_with_attention(0.0, 0.0), 0.0) == 0.0
expect attention_after(rider_with_attention(0.0, (90.0 * Trig.deg)), (90.0 * Trig.deg)) == 1.0
expect !(Gaze.gawk_engaged(rider(200.0, 0.0), plain))
expect !(Gaze.gawk_engaged(rider(100.0, 0.0), distracting))
expect Gaze.gawk_engaged(rider(200.0, 0.0), distracting)
expect Gaze.gawk_engaged(rider(341.0, 0.0), distracting)

# The gawking outlasts the look.
expect !Gaze.pig_ahead(rider(341.0, 0.0), distracting).looking
expect Gaze.gawk_engaged(rider(341.0, 0.0), distracting)
