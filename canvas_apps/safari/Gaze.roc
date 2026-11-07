## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it. The pig passes out of sight to the side while it is still
## ahead, and the gaze turns back to the road.
##
## Two words keep the eyes and the throttle apart. A look is what the eyes do,
## and it ends once the pig is too far round. Gawking is what the speed does,
## and it lasts to the end of the segment; it is Gawking's.
import Angle
import Attention
import Billboard
import Easing
import Fraction
import Gawking
import Geom
import Motorcycle
import RiderEyes
import Route
import Segment

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
		match Gawking.gawked_pig(motorcycle, seg) {
			GawkingAt(pig) => {
				turn = turn_to(motorcycle, pig)
				if turn.abs() < look_release_angle {
					OnPig(turn)
				} else {
					OnRoad
				}
			}
			NotGawking => OnRoad
		}

	## These eyes moved on a step, for a rider on `motorcycle` on `route`: the
	## gaze, and the look depth it leaves.
	eyes_at_next_step : RiderEyes, { motorcycle : Motorcycle, route : Route } -> RiderEyes
	eyes_at_next_step = |eyes, { motorcycle, route }| {
		segment = motorcycle.route_place.segment_on(route)
		gaze_yaw = next_gaze_yaw(eyes, desired_gaze(motorcycle, segment))
		{ gaze_yaw, look_depth: next_look_depth(eyes, gaze_yaw) }
	}
}

## The most the gaze swivels toward a pig in one step.
look_swivel_rate : Angle.Turn
look_swivel_rate = Angle.Turn.degrees(4.0)

## How far the gaze turns back toward the road in one step. A gaze nearer
## the road than this goes all the way there, so a return ends by itself.
look_return_rate : Angle.Turn
look_return_rate = Angle.Turn.degrees(0.2)

## How much look depth fades in one step. It is subtracted from the depth,
## and is no share of it, so the fade runs at one rate all the way down.
look_depth_decay : Fraction
look_depth_decay = Fraction.of(0.0012)

## The gaze one step on. It swivels toward a pig by at most the swivel rate.
## With only the road to look at, it turns back by the return rate, and the
## last step lands it straight ahead.
next_gaze_yaw : RiderEyes, Gaze.GazeTarget -> Angle.Turn
next_gaze_yaw = |eyes, target| {
	gaze = eyes.gaze_yaw
	match target {
		OnPig(turn) => gaze.plus(turn.minus(gaze).clamped_within(look_swivel_rate))
		OnRoad => gaze.minus(gaze.clamped_within(look_return_rate))
	}
}

## The rider's look depth after the gaze moves to `gaze_yaw`. It rises with
## how far the gaze has turned, and it holds while the gaze is off straight
## ahead by any amount, so it holds all through the return. It fades only
## once the return has put the gaze exactly straight ahead.
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
		x: pig.road_point.along.distance_from(motorcycle.route_place.along).to_metres(),
		y: pig.road_point.across.distance_from(motorcycle.route_place.across).to_metres(),
	}),
).minus(motorcycle.yaw)

expect Gaze.gaze_attention(Fraction.of(0.25)).to_f64() == 0.15625

## Radians in `d` degrees.
degrees : F64 -> F64
degrees = |d| Angle.Turn.degrees(d).to_radians()

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

return_rate : F64
return_rate = look_return_rate.to_radians()

expect gaze_after(head(0.0), 1.0) - swivel_rate == 0.0
expect gaze_after(head(0.0), -1.0) + swivel_rate == 0.0
expect gaze_after(head(0.0), swivel_rate / 2.0) - swivel_rate / 2.0 == 0.0

# Each is within 1e-12 of its want, in degrees. A far gaze and a near one move
# back by the same return rate.
expect
	[
		(30.0, 29.8),
		(-30.0, -29.8),
		(2.0, 1.8),
		(-2.0, -1.8),
	].all(
		|(from, to)|
			(gaze_returning(head(degrees(from))) / degrees(1.0) - to).abs() <= 0.000000000001,
	)

# A gaze within the return rate comes all the way home, exactly, and one just
# past it doesn't.
expect gaze_returning(head(return_rate)) == 0.0
expect gaze_returning(head(-return_rate)) == 0.0
expect gaze_returning(head(return_rate / 2.0)) == 0.0
expect gaze_returning(head(return_rate * 1.5)) > 0.0
expect gaze_returning(head(-return_rate * 1.5)) < 0.0
expect gaze_returning(head(0.0)) == 0.0

# A pig dead ahead is still a pig: the gaze swivels to it, and doesn't ease.
expect gaze_after(head(degrees(2.0)), 0.0) == 0.0

## Eyes with this look depth, looking `gaze_yaw` from straight ahead.
eyes_at_depth : F64, F64 -> RiderEyes
eyes_at_depth = |look_depth, gaze_yaw| { ..head(gaze_yaw), look_depth: Fraction.of(look_depth) }

expect {
	rising = depth_after(eyes_at_depth(0.0, degrees(20.0)), degrees(20.0))
	held = depth_after(eyes_at_depth(0.9, degrees(1.0)), degrees(1.0))
	easing = depth_after(eyes_at_depth(0.9, 0.0), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

# The depth holds until the gaze is exactly straight ahead, and fades from there.
expect depth_after(eyes_at_depth(0.9, 0.0), return_rate / 10.0) == 0.9
expect (depth_after(eyes_at_depth(0.9, 0.0), 0.0) - 0.8988).abs() <= 0.000000000001

expect depth_after(eyes_at_depth(0.0, 0.0), 0.0) == 0.0
expect depth_after(eyes_at_depth(0.0, degrees(90.0)), degrees(90.0)) == 1.0
