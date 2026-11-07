## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it and the rider slows. The pig passes out of sight to the
## side while it is still ahead, and the gaze eases back to the road.
##
## Two words keep the eyes and the throttle apart. A look is what the eyes do,
## and it ends once the pig is too far round. Gawking is what the speed does,
## and it lasts to the end of the segment.
import Acceleration
import Angle
import Attention
import Distance
import Easing
import Fraction
import RiderState
import Scenery
import Speed
import lib.Trig
import World

Gaze :: [].{

	## What a pig asks of the throttle: nothing, or to accelerate no harder than
	## this.
	GawkBrake : [NoLimit, AtMost(Acceleration)]

	## Where the rider wants to look: at the pig in sight, this far from the
	## way the bike points, or at the road.
	GazeTarget : [OnPig(Angle.Turn), OnRoad]

	## How far short of a pig the rider notices it, measured along the road.
	## The look and the gawking both start here.
	notice_distance : Distance
	notice_distance = Distance.metres(150.0)

	## How far from the way the bike points the rider will look. A pig this far
	## round, or further, is out of sight.
	look_release_angle : Angle.Turn
	look_release_angle = Angle.Turn.degrees(35.0)

	## The most the gaze swivels toward a pig in one step.
	look_swivel_rate : Angle.Turn
	look_swivel_rate = Angle.Turn.degrees(4.0)

	## The most the gaze turns back toward the road in one step.
	look_return_rate : Angle.Turn
	look_return_rate = Angle.Turn.degrees(0.2)

	## The share of its angle the gaze gives back in one step on its way to the
	## road, up to the return rate.
	look_return_ease : Fraction
	look_return_ease = Fraction.of(0.05)

	## How near straight ahead the gaze has to be to go all the way there in one
	## step, so that a return ends.
	look_return_snap : Angle.Turn
	look_return_snap = Angle.Turn.degrees(0.02)

	## How much look depth fades in one step. It is subtracted from the depth,
	## and is no share of it, so the fade runs at one rate all the way down.
	look_depth_decay : Fraction
	look_depth_decay = Fraction.of(0.0012)

	## The speed a gawking rider brakes down to.
	gawk_speed : Speed
	gawk_speed = Speed.metres_a_step(0.2)

	## How far short of the pig a gawking rider aims to reach `gawk_speed`.
	gawk_settle_distance : Distance
	gawk_settle_distance = Distance.metres(25.0)

	## The shortest distance the brake for a pig is worked out over. Past the
	## settle distance the rider is still coming down to `gawk_speed`, so the
	## brake keeps working at this distance's strength. `Throttle.bend_brake`
	## has a different guard, which lets go at its commit point: a rider who
	## reaches a bend has no more road to brake on, and a rider who reaches
	## the pig has the rest of the segment.
	gawk_least_distance : Distance
	gawk_least_distance = Distance.metres(1.0)

	## How strongly a look of this depth holds the rider's eye. The easing keeps
	## a shallow look from widening the view much.
	gaze_attention : Fraction -> Attention
	gaze_attention = |look_depth| Attention.from_fraction(Easing.smoothstep(look_depth))

	## Where the rider wants to look: at a distracting pig that is near enough
	## to notice and less than the release angle from the way the bike points,
	## or else at the road.
	desired_gaze : RiderState, World.Segment -> Gaze.GazeTarget
	desired_gaze = |state, seg|
		match seg.pig_interest {
			Distracting(pig) if is_gawking(state, seg) => {
				turn = turn_to(state, pig)
				if turn.abs() < look_release_angle {
					OnPig(turn)
				} else {
					OnRoad
				}
			}
			Distracting(_) | Unnoticed | NoPigs => OnRoad
		}

	## The gaze one step on. It swivels toward a pig by at most the swivel rate.
	## With only the road to look at, it gives back a share of its angle, up to
	## the return rate, and snaps home once it is close.
	next_gaze_yaw : RiderState, Gaze.GazeTarget -> Angle.Turn
	next_gaze_yaw = |state, target| {
		gaze = state.gaze_yaw
		match target {
			OnPig(turn) => gaze.plus(turn.minus(gaze).clamped_within(look_swivel_rate))
			OnRoad =>
				if gaze.abs() <= look_return_snap {
					Angle.straight_ahead
				} else {
					eased_back = gaze.times(look_return_ease.to_f64())
					gaze.minus(eased_back.clamped_within(look_return_rate))
				}
		}
	}

	## The rider's look depth after the gaze moves to `gaze_yaw`. It rises with
	## how far the gaze has turned, and it holds while the gaze is off straight
	## ahead by any amount, so it holds all through the return. It fades only
	## once the snap has put the gaze exactly straight ahead, which makes
	## `look_return_snap` the setting that starts the fade.
	next_look_depth : RiderState, Angle.Turn -> Fraction
	next_look_depth = |state, gaze_yaw|
		if gaze_yaw == Angle.straight_ahead {
			Fraction.clamp(state.look_depth.to_f64() - look_depth_decay.to_f64())
		} else {
			state.look_depth.max(Fraction.clamp(gaze_yaw.abs().ratio_to(look_release_angle)))
		}

	## This rider with the eyes moved on a step: the gaze, and the look depth it
	## leaves.
	next_rider_gaze : RiderState, List(World.Segment) -> RiderState
	next_rider_gaze = |state, route_segments| {
		seg = state.segment_index.segment_in(route_segments)
		gaze_yaw = next_gaze_yaw(state, desired_gaze(state, seg))
		{
			..state,
			gaze_yaw,
			look_depth: next_look_depth(state, gaze_yaw),
		}
	}

	## Whether the rider is gawking at this segment's pig. It starts where the
	## pig is noticed and asks only where the rider is, so it stays true past the
	## pig to the end of the segment: the rider brakes for the pig and doesn't
	## open the throttle until the next segment. Two things depend on that.
	## `gawk_brake` holds the rider down for as long as this is true, and
	## `Throttle.allowed_speed` leaves a gawking rider below the segment's exit
	## speed, where it lifts any other rider near the end up to it.
	is_gawking : RiderState, World.Segment -> Bool
	is_gawking = |state, seg|
		match seg.pig_interest {
			Distracting(pig) => state.along >= pig.along.minus(notice_distance)
			Unnoticed | NoPigs => False
		}

	## The brake for a gawking rider, who aims to be down to `gawk_speed` by
	## the settle distance before the pig.
	gawk_brake : RiderState, World.Segment -> Gaze.GawkBrake
	gawk_brake = |state, seg|
		match seg.pig_interest {
			Distracting(pig) if is_gawking(state, seg) => {
				room = pig.along.distance_from(state.along).minus(gawk_settle_distance)
				AtMost(
					state.speed.acceleration_to({
						target: gawk_speed,
						within: room.max(gawk_least_distance),
					}),
				)
			}
			Distracting(_) | Unnoticed | NoPigs => NoLimit
		}
}

## How far `pig` stands from the way the bike points.
turn_to : RiderState, Scenery.Critter -> Angle.Turn
turn_to = |state, pig| Angle.Turn.radians(
	F64.atan2({
		x: pig.along.distance_from(state.along).to_metres(),
		y: pig.across.distance_from(state.across).to_metres(),
	}),
).minus(state.yaw)

# Each is within 1e-12 of its want.
expect
	[
		(Gaze.notice_distance.to_metres(), 150.0),
		(Gaze.look_depth_decay.to_f64(), 0.0012),
		(Gaze.gawk_speed.to_metres_a_step(), 0.2),
		(Gaze.gawk_settle_distance.to_metres(), 25.0),
		(Gaze.gawk_least_distance.to_metres(), 1.0),
		(Gaze.look_release_angle.to_radians() / Trig.deg, 35.0),
		(Gaze.look_swivel_rate.to_radians() / Trig.deg, 4.0),
		(Gaze.look_return_rate.to_radians() / Trig.deg, 0.2),
		(Gaze.look_return_snap.to_radians() / Trig.deg, 0.02),
		(Gaze.look_return_ease.to_f64(), 0.05),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Gaze.gaze_attention(Fraction.of(0.25)).to_f64() == 0.15625

plain : World.Segment
plain = World.route_segment(0)

distracting : World.Segment
distracting = World.route_segment(2)

expect plain.pig_interest == NoPigs

## A rider on the distracting segment, at rest in every other way. Gaze doesn't
## import Along, so `along` is a distance from the segment's start.
rider : F64 -> RiderState
rider = |along| {
	..RiderState.initial,
	segment_index: World.SegmentIndex.number(2),
	along: RiderState.initial.along.plus(Distance.metres(along)),
}

## How far this rider on the distracting segment wants to turn to the pig.
turn_to_pig : RiderState -> F64
turn_to_pig = |state|
	match Gaze.desired_gaze(state, distracting) {
		OnPig(turn) => turn.to_radians()
		OnRoad => crash "Gaze's expects: no pig in sight"
	}

expect {
	far = turn_to_pig(rider(200.0))
	near = turn_to_pig(rider(320.0))
	far > 0.0 and near > far
}

expect Gaze.desired_gaze(rider(200.0), plain) == OnRoad
expect Gaze.desired_gaze(rider(100.0), distracting) == OnRoad
expect Gaze.desired_gaze(rider(341.0), distracting) == OnRoad

## The pig that catches the eye on the distracting segment.
watched_pig : Scenery.Critter
watched_pig =
	match distracting.pig_interest {
		Distracting(pig) => pig
		NoPigs | Unnoticed => crash "Gaze's expects: this segment's pigs catch the eye"
	}

# The rider watches a pig of the herd.
expect distracting.pigs.count_if(|pig| pig == watched_pig) == 1

## A rider on the distracting segment, `metres` short of the pig.
rider_short_of_pig : F64 -> RiderState
rider_short_of_pig = |metres| {
	..rider(0.0),
	along: watched_pig.along.minus(Distance.metres(metres)),
}

# The look starts where the pig is noticed, and not a centimetre sooner.
expect turn_to_pig(rider_short_of_pig(Gaze.notice_distance.to_metres())) > 0.0
expect Gaze.desired_gaze(rider_short_of_pig(150.01), distracting) == OnRoad

## A rider 100 m short of the pig, turned so the pig is `degrees` off.
rider_with_pig_off : F64 -> RiderState
rider_with_pig_off = |degrees| {
	straight = rider_short_of_pig(100.0)
	{ ..straight, yaw: turn_to(straight, watched_pig).minus(Angle.Turn.degrees(degrees)) }
}

# The pig stays in sight up to the release angle, on either side of the bike.
expect
	[
		(34.99, True),
		(-34.99, True),
		(35.01, False),
		(-35.01, False),
	].all(|(degrees, is_in_sight)| is_looking(rider_with_pig_off(degrees)) == is_in_sight)

## Whether this rider on the distracting segment wants to look at the pig.
is_looking : RiderState -> Bool
is_looking = |state|
	match Gaze.desired_gaze(state, distracting) {
		OnPig(_) => True
		OnRoad => False
	}

## A rider looking `gaze_yaw` from straight ahead.
head : F64, F64 -> RiderState
head = |gaze_yaw, along| { ..rider(along), gaze_yaw: Angle.Turn.radians(gaze_yaw) }

## The gaze one step after `state`, wanting a pig `want` radians off.
gaze_after : RiderState, F64 -> F64
gaze_after = |state, want| Gaze.next_gaze_yaw(state, OnPig(Angle.Turn.radians(want))).to_radians()

## The gaze one step after `state`, with only the road to look at.
gaze_returning : RiderState -> F64
gaze_returning = |state| Gaze.next_gaze_yaw(state, OnRoad).to_radians()

## The look depth after the gaze moves to `gaze` radians.
depth_after : RiderState, F64 -> F64
depth_after = |state, gaze| Gaze.next_look_depth(state, Angle.Turn.radians(gaze)).to_f64()

swivel_rate : F64
swivel_rate = Gaze.look_swivel_rate.to_radians()

return_snap : F64
return_snap = Gaze.look_return_snap.to_radians()

expect gaze_after(head(0.0, 200.0), 1.0) - swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), -1.0) + swivel_rate == 0.0
expect gaze_after(head(0.0, 200.0), swivel_rate / 2.0) - swivel_rate / 2.0 == 0.0

expect {
	big = gaze_returning(head(30.0 * Trig.deg, 200.0))
	small = gaze_returning(head(2.0 * Trig.deg, 200.0))
	big < 30.0 * Trig.deg
		and big > 0.0
		and small < 2.0 * Trig.deg
		and small > 0.0
		and 30.0 * Trig.deg - big > 2.0 * Trig.deg - small
}

# Each is within 1e-12 of its want, in degrees. A far gaze moves at the return
# rate and a near one by its share, and 4 degrees is where they meet.
expect
	[
		(30.0, 29.8),
		(-30.0, -29.8),
		(4.0, 3.8),
		(-4.0, -3.8),
		(2.0, 1.9),
		(-2.0, -1.9),
	].all(
		|(from, to)|
			(gaze_returning(head(from * Trig.deg, 200.0)) / Trig.deg - to).abs() <= 0.000000000001,
	)

expect gaze_returning(head(return_snap, 200.0)) == 0.0
expect gaze_returning(head(-return_snap, 200.0)) == 0.0
expect gaze_returning(head(0.0, 200.0)) == 0.0

# A pig dead ahead is still a pig: the gaze swivels to it, and doesn't ease.
expect gaze_after(head(2.0 * Trig.deg, 200.0), 0.0) == 0.0

## A rider with this look depth, looking `gaze_yaw` from straight ahead.
rider_at_depth : F64, F64 -> RiderState
rider_at_depth = |look_depth, gaze_yaw| {
	..head(gaze_yaw, 200.0),
	look_depth: Fraction.of(look_depth),
}

expect {
	rising = depth_after(rider_at_depth(0.0, 20.0 * Trig.deg), 20.0 * Trig.deg)
	held = depth_after(rider_at_depth(0.9, 1.0 * Trig.deg), 1.0 * Trig.deg)
	easing = depth_after(rider_at_depth(0.9, 0.0), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

# The depth holds until the gaze is exactly straight ahead, and fades from there.
expect depth_after(rider_at_depth(0.9, 0.0), Gaze.look_return_snap.to_radians()) == 0.9
expect (depth_after(rider_at_depth(0.9, 0.0), 0.0) - 0.8988).abs() <= 0.000000000001

expect depth_after(rider_at_depth(0.0, 0.0), 0.0) == 0.0
expect depth_after(rider_at_depth(0.0, 90.0 * Trig.deg), 90.0 * Trig.deg) == 1.0
expect !Gaze.is_gawking(rider(200.0), plain)
expect !Gaze.is_gawking(rider(100.0), distracting)
expect Gaze.is_gawking(rider(200.0), distracting)
expect Gaze.is_gawking(rider(341.0), distracting)

expect Gaze.gawk_brake(rider(200.0), plain) == NoLimit
expect Gaze.gawk_brake(rider(100.0), distracting) == NoLimit

## The brake for a rider `metres` short of the pig, going `speed` metres a step.
brake_short_of_pig : F64, F64 -> F64
brake_short_of_pig = |metres, speed| {
	state = { ..rider_short_of_pig(metres), speed: Speed.metres_a_step(speed) }
	match Gaze.gawk_brake(state, distracting) {
		AtMost(brake) => brake.to_metres_a_step_each_step()
		NoLimit => crash "Gaze's expects: this rider is gawking"
	}
}

# Each is within 1e-12 of its want. The brake works out the road left to the
# settle distance, until there's less than the least distance left.
expect
	[
		((125.0, 0.3), -0.00025),
		((75.0, 0.3), -0.0005),
		((27.0, 0.3), -0.0125),
		((26.0, 0.3), -0.025),
		((25.5, 0.3), -0.025),
		((0.0, 0.3), -0.025),
		((-10.0, 0.3), -0.025),
		((125.0, 0.2), 0.0),
		((125.0, 0.1), 0.00015),
	].all(
		|
			((metres, speed), want),
		| (brake_short_of_pig(metres, speed) - want).abs() <= 0.000000000001,
	)

# The gawking outlasts the look.
expect !is_looking(rider(341.0))
expect Gaze.is_gawking(rider(341.0), distracting)
