## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it. The pig passes out of sight to the side while it is still
## ahead, and the gaze eases back to the road.
##
## Two words keep the eyes and the throttle apart. A look is what the eyes do,
## and it ends once the pig is too far round. Gawking is what the speed does,
## and it lasts to the end of the segment; it is Gawking's.
import Angle
import Attention
import Billboard
import Distance
import Easing
import Fraction
import Gawking
import Geom
import Motorcycle
import RiderEyes
import RiderState
import lib.Trig
import Route
import Segment
import World

Gaze :: [].{

	## Where the rider wants to look: at the pig in sight, this far from the
	## way the motorcycle points, or at the road.
	GazeTarget : [OnPig(Angle.Turn), OnRoad]

	## How far from the way the motorcycle points the rider will look. A pig
	## this far round, or further, is out of sight.
	look_release_angle : Angle.Turn
	look_release_angle = Angle.Turn.degrees(35.0)

	## How strongly a look of this depth holds the rider's eye. The easing keeps
	## a shallow look from widening the view much.
	gaze_attention : Fraction -> Attention
	gaze_attention = |look_depth| Attention.from_fraction(Easing.smoothstep(look_depth))

	## Where the rider wants to look: at a distracting pig that is near enough
	## to notice and less than the release angle from the way the motorcycle
	## points, or else at the road.
	desired_gaze : Motorcycle, Segment -> Gaze.GazeTarget
	desired_gaze = |motorcycle, seg|
		match Gawking.eye_catching_pig(seg) {
			CatchesEye(pig) if Gawking.is_gawking(motorcycle, seg) => {
				turn = turn_to(motorcycle, pig)
				if turn.abs() < look_release_angle {
					OnPig(turn)
				} else {
					OnRoad
				}
			}
			CatchesEye(_) | NoPigCatchesEye => OnRoad
		}

	## This rider with the eyes moved on a step, on `seg`, the segment the rider
	## is on: the gaze, and the look depth it leaves.
	next_rider_gaze : RiderState, Segment -> RiderState
	next_rider_gaze = |state, seg| {
		eyes = state.eyes
		gaze_yaw = next_gaze_yaw(eyes, desired_gaze(state.motorcycle, seg))
		{ ..state, eyes: { gaze_yaw, look_depth: next_look_depth(eyes, gaze_yaw) } }
	}
}

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

## The gaze one step on. It swivels toward a pig by at most the swivel rate.
## With only the road to look at, it gives back a share of its angle, up to
## the return rate, and snaps home once it is close.
next_gaze_yaw : RiderEyes, Gaze.GazeTarget -> Angle.Turn
next_gaze_yaw = |eyes, target| {
	gaze = eyes.gaze_yaw
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
next_look_depth : RiderEyes, Angle.Turn -> Fraction
next_look_depth = |eyes, gaze_yaw|
	if gaze_yaw == Angle.straight_ahead {
		Fraction.clamp(eyes.look_depth.to_f64() - look_depth_decay.to_f64())
	} else {
		eyes.look_depth.max(Fraction.clamp(gaze_yaw.abs().portion(Gaze.look_release_angle)))
	}

## How far `pig` stands from the way the motorcycle points.
turn_to : Motorcycle, Geom.Placed(Billboard) -> Angle.Turn
turn_to = |motorcycle, pig| Angle.Turn.radians(
	F64.atan2({
		x: pig.road_point.along.distance_from(motorcycle.along).to_metres(),
		y: pig.road_point.across.distance_from(motorcycle.across).to_metres(),
	}),
).minus(motorcycle.yaw)

# Each is within 1e-12 of its want.
expect
	[
		(look_depth_decay.to_f64(), 0.0012),
		(Gaze.look_release_angle.to_radians() / Trig.degree, 35.0),
		(look_swivel_rate.to_radians() / Trig.degree, 4.0),
		(look_return_rate.to_radians() / Trig.degree, 0.2),
		(look_return_snap.to_radians() / Trig.degree, 0.02),
		(look_return_ease.to_f64(), 0.05),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect Gaze.gaze_attention(Fraction.of(0.25)).to_f64() == 0.15625

plain : Segment
plain = World.route.segment_at(Route.SegmentIndex.number(0))

distracting : Segment
distracting = World.route.segment_at(Route.SegmentIndex.number(2))

## A motorcycle `along` metres into the distracting segment, at rest in every
## other way. Gaze doesn't import Along, so `along` is a distance from the
## segment's start.
rider : F64 -> Motorcycle
rider = |along| {
	..Motorcycle.initial,
	along: Motorcycle.initial.along.plus(Distance.metres(along)),
}

## How far this motorcycle on the distracting segment wants to turn to the pig.
turn_to_pig : Motorcycle -> F64
turn_to_pig = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting) {
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
watched_pig : Geom.Placed(Billboard)
watched_pig =
	match Gawking.eye_catching_pig(distracting) {
		CatchesEye(pig) => pig
		NoPigCatchesEye => crash "Gaze's expects: this segment's pigs catch the eye"
	}

## A motorcycle on the distracting segment, `metres` short of the pig.
rider_short_of_pig : F64 -> Motorcycle
rider_short_of_pig = |metres| {
	..rider(0.0),
	along: watched_pig.road_point.along.minus(Distance.metres(metres)),
}

# The look starts where the pig is noticed, and not a centimetre sooner.
expect turn_to_pig(rider_short_of_pig(Gawking.notice_distance.to_metres())) > 0.0
expect Gaze.desired_gaze(rider_short_of_pig(150.01), distracting) == OnRoad

## A motorcycle 100 m short of the pig, turned so the pig is `degrees` off.
rider_with_pig_off : F64 -> Motorcycle
rider_with_pig_off = |degrees| {
	straight = rider_short_of_pig(100.0)
	{ ..straight, yaw: turn_to(straight, watched_pig).minus(Angle.Turn.degrees(degrees)) }
}

# The pig stays in sight up to the release angle, on either side of the
# motorcycle.
expect
	[
		(34.99, True),
		(-34.99, True),
		(35.01, False),
		(-35.01, False),
	].all(|(degrees, is_in_sight)| is_looking(rider_with_pig_off(degrees)) == is_in_sight)

## Whether this motorcycle's rider on the distracting segment wants to look at
## the pig.
is_looking : Motorcycle -> Bool
is_looking = |motorcycle|
	match Gaze.desired_gaze(motorcycle, distracting) {
		OnPig(_) => True
		OnRoad => False
	}

## Eyes looking `gaze_yaw` from straight ahead.
head : F64 -> RiderEyes
head = |gaze_yaw| { ..RiderEyes.initial, gaze_yaw: Angle.Turn.radians(gaze_yaw) }

## The gaze one step after `eyes`, wanting a pig `want` radians off.
gaze_after : RiderEyes, F64 -> F64
gaze_after = |eyes, want| next_gaze_yaw(eyes, OnPig(Angle.Turn.radians(want))).to_radians()

## The gaze one step after `eyes`, with only the road to look at.
gaze_returning : RiderEyes -> F64
gaze_returning = |eyes| next_gaze_yaw(eyes, OnRoad).to_radians()

## The look depth after the gaze moves to `gaze` radians.
depth_after : RiderEyes, F64 -> F64
depth_after = |eyes, gaze| next_look_depth(eyes, Angle.Turn.radians(gaze)).to_f64()

swivel_rate : F64
swivel_rate = look_swivel_rate.to_radians()

return_snap : F64
return_snap = look_return_snap.to_radians()

expect gaze_after(head(0.0), 1.0) - swivel_rate == 0.0
expect gaze_after(head(0.0), -1.0) + swivel_rate == 0.0
expect gaze_after(head(0.0), swivel_rate / 2.0) - swivel_rate / 2.0 == 0.0

expect {
	big = gaze_returning(head(30.0 * Trig.degree))
	small = gaze_returning(head(2.0 * Trig.degree))
	big < 30.0 * Trig.degree
		and big > 0.0
		and small < 2.0 * Trig.degree
		and small > 0.0
		and 30.0 * Trig.degree - big > 2.0 * Trig.degree - small
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
			(gaze_returning(head(from * Trig.degree)) / Trig.degree - to).abs() <= 0.000000000001,
	)

expect gaze_returning(head(return_snap)) == 0.0
expect gaze_returning(head(-return_snap)) == 0.0
expect gaze_returning(head(0.0)) == 0.0

# A pig dead ahead is still a pig: the gaze swivels to it, and doesn't ease.
expect gaze_after(head(2.0 * Trig.degree), 0.0) == 0.0

## Eyes with this look depth, looking `gaze_yaw` from straight ahead.
eyes_at_depth : F64, F64 -> RiderEyes
eyes_at_depth = |look_depth, gaze_yaw| { ..head(gaze_yaw), look_depth: Fraction.of(look_depth) }

expect {
	rising = depth_after(eyes_at_depth(0.0, 20.0 * Trig.degree), 20.0 * Trig.degree)
	held = depth_after(eyes_at_depth(0.9, 1.0 * Trig.degree), 1.0 * Trig.degree)
	easing = depth_after(eyes_at_depth(0.9, 0.0), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

# The depth holds until the gaze is exactly straight ahead, and fades from there.
expect depth_after(eyes_at_depth(0.9, 0.0), look_return_snap.to_radians()) == 0.9
expect (depth_after(eyes_at_depth(0.9, 0.0), 0.0) - 0.8988).abs() <= 0.000000000001

expect depth_after(eyes_at_depth(0.0, 0.0), 0.0) == 0.0
expect depth_after(eyes_at_depth(0.0, 90.0 * Trig.degree), 90.0 * Trig.degree) == 1.0

# The gawking outlasts the look.
expect !is_looking(rider(341.0))
expect Gawking.is_gawking(rider(341.0), distracting)
