## Where the rider's eyes are: the look away from the way the motorcycle
## points, and how far into a look the rider has gone. They are kept from one
## step to the next, as part of the `Rider`.
import Angle
import Attention
import Easing
import Fraction
import Gaze

## The rider's eyes at one step. `gaze_yaw` is the look away from the way the
## motorcycle points, and `look_depth` how far into a look the rider has gone,
## which outlasts the look. Nominal, not opaque: other modules read its fields.
RiderEyes := { gaze_yaw : Angle.Turn, look_depth : Fraction }.{

	initial : RiderEyes
	initial = { gaze_yaw: Angle.straight_ahead, look_depth: Fraction.zero }

	## These eyes moved on a step toward `target`: the gaze, and the look depth
	## it leaves.
	eyes_at_next_step : RiderEyes, Gaze.GazeTarget -> RiderEyes
	eyes_at_next_step = |eyes, target| {
		gaze_yaw = next_gaze_yaw(eyes, target)
		{ gaze_yaw, look_depth: next_look_depth(eyes, gaze_yaw) }
	}

	## How strongly the depth of these eyes' look holds the rider's eye. The
	## easing keeps a shallow look from widening the view much.
	attention : RiderEyes -> Attention
	attention = |eyes| Attention.from_fraction(Easing.smoothstep(eyes.look_depth))

	is_eq : _
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
		eyes.look_depth.max(Fraction.clamp(gaze_yaw.abs().ratio_to(Gaze.look_release_angle)))
	}

## Radians in `d` degrees.
radians_of_degrees : F64 -> F64
radians_of_degrees = |d| Angle.Turn.degrees(d).to_radians()

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
		|(from, to)| {
			returned = gaze_returning(head(radians_of_degrees(from)))
			(returned / radians_of_degrees(1.0) - to).abs() <= 0.000000000001
		},
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
expect gaze_after(head(radians_of_degrees(2.0)), 0.0) == 0.0

## Eyes `look_depth` into a look, looking `gaze_radians` from straight ahead.
eyes_at_depth : { look_depth : Fraction, gaze_radians : F64 } -> RiderEyes
eyes_at_depth = |{ look_depth, gaze_radians }| { ..head(gaze_radians), look_depth }

expect {
	wide_gaze = radians_of_degrees(20.0)
	small_gaze = radians_of_degrees(1.0)
	fresh_eyes = eyes_at_depth({ look_depth: Fraction.zero, gaze_radians: wide_gaze })
	deep_eyes = eyes_at_depth({ look_depth: Fraction.of(0.9), gaze_radians: small_gaze })
	rising = depth_after(fresh_eyes, wide_gaze)
	held = depth_after(deep_eyes, small_gaze)
	easing = depth_after(eyes_ahead_at_depth(0.9), 0.0)
	rising > 0.0 and held >= 0.9 and easing < 0.9 and easing > 0.0
}

## Eyes this deep into a look, looking straight ahead.
eyes_ahead_at_depth : F64 -> RiderEyes
eyes_ahead_at_depth = |depth| eyes_at_depth({ look_depth: Fraction.of(depth), gaze_radians: 0.0 })

# The depth holds until the gaze is exactly straight ahead, and fades from there.
expect depth_after(eyes_ahead_at_depth(0.9), return_rate / 10.0) == 0.9
expect (depth_after(eyes_ahead_at_depth(0.9), 0.0) - 0.8988).abs() <= 0.000000000001

expect eyes_ahead_at_depth(0.25).attention().to_f64() == 0.15625

expect depth_after(eyes_ahead_at_depth(0.0), 0.0) == 0.0
expect {
	right_angle = radians_of_degrees(90.0)
	eyes = eyes_at_depth({ look_depth: Fraction.zero, gaze_radians: right_angle })
	depth_after(eyes, right_angle) == 1.0
}
