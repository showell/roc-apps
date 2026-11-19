## Safari's angles, in radians, as four types.
##
## Anything that moves through the world, a rider, a camera or an aircraft,
## can rotate three ways. Yaw is turning left or right, about an axis that
## points straight up: which way the rider is heading, or where they look.
## Pitch is tipping the nose up or down, about an axis from side to side.
## Safari has no pitch: the camera always looks level. Roll is tipping
## sideways, about an axis that points straight ahead, as a bike leans into
## a curve. The camera rides with the bike, so it rolls too, and the whole
## picture tilts with the lean.
##
## Two of the types measure yaw. A bearing is a direction in the world: 0 is
## north, and a bearing grows to the rider's right. A turn is the angle
## between two directions, such as how far the rider's gaze is from straight
## ahead. A turn added to a bearing gives a bearing, and two bearings give
## the turn between them, but two bearings can't be added. A turn to the
## right is positive, and a turn to the left negative.
##
## The third type, a lean, measures roll: how far the bike tips from
## upright. A lean is never added to a direction. It turns the bike only
## through a rate (`steer`), the way a leaning bike follows a curve. The
## fourth, a lean change, is how far a lean moves in a step: a change added
## to a lean gives a lean.
import lib.Trig

Angle :: [].{

	Bearing :: F64.{

		radians : F64 -> Angle.Bearing
		radians = |count| Angle.Bearing.(count)

		to_radians : Angle.Bearing -> F64
		to_radians = |Angle.Bearing.(bearing)| bearing

		## The bearing `turn` to the right of this one.
		plus : Angle.Bearing, Angle.Turn -> Angle.Bearing
		plus = |Angle.Bearing.(bearing), Angle.Turn.(turn)| Angle.Bearing.(bearing + turn)

		## The shortest turn from `from` round to this bearing, between minus
		## and plus a half turn.
		turn_from : Angle.Bearing, Angle.Bearing -> Angle.Turn
		turn_from = |
			Angle.Bearing.(bearing),
			Angle.Bearing.(from),
		| Angle.Turn.(wrap(bearing - from))

		## The shortest turn from north round to this bearing.
		turn_from_north : Angle.Bearing -> Angle.Turn
		turn_from_north = |Angle.Bearing.(bearing)| Angle.Turn.(wrap(bearing))

		## Whether this bearing is no further right than `other`, read without
		## going round: for a sweep across a stretch of bearings.
		is_lte : Angle.Bearing, Angle.Bearing -> Bool
		is_lte = |Angle.Bearing.(bearing), Angle.Bearing.(other)| bearing <= other

		is_eq : _
	}

	Turn :: F64.{

		radians : F64 -> Angle.Turn
		radians = |count| Angle.Turn.(count)

		## The turn of this many degrees.
		degrees : F64 -> Angle.Turn
		degrees = |count| Angle.Turn.(count * Trig.degree)

		to_radians : Angle.Turn -> F64
		to_radians = |Angle.Turn.(turn)| turn

		## This turn in degrees: negative for a turn to the left.
		to_degrees : Angle.Turn -> F64
		to_degrees = |Angle.Turn.(turn)| turn * Trig.degrees_per_radian

		plus : Angle.Turn, Angle.Turn -> Angle.Turn
		plus = |Angle.Turn.(turn), Angle.Turn.(other)| Angle.Turn.(turn + other)

		minus : Angle.Turn, Angle.Turn -> Angle.Turn
		minus = |Angle.Turn.(turn), Angle.Turn.(other)| Angle.Turn.(turn - other)

		times : Angle.Turn, F64 -> Angle.Turn
		times = |Angle.Turn.(turn), factor| Angle.Turn.(turn * factor)

		## The same turn taken to the right.
		abs : Angle.Turn -> Angle.Turn
		abs = |Angle.Turn.(turn)| Angle.Turn.(turn.abs())

		## This turn, held to no more than `limit` either way. A limit below zero
		## is no range, so it crashes.
		clamped_within : Angle.Turn, Angle.Turn -> Angle.Turn
		clamped_within = |Angle.Turn.(turn), Angle.Turn.(limit)|
			if limit < 0.0 {
				crash "Angle.Turn.clamped_within: a limit below zero is no range to hold a turn to"
			} else {
				Angle.Turn.((0.0 - limit).max(F64.min(limit, turn)))
			}

		## How many of `whole` this turn is: negative for a turn to the left.
		ratio_to : Angle.Turn, Angle.Turn -> F64
		ratio_to = |Angle.Turn.(turn), Angle.Turn.(whole)| turn / whole

		## Whether this turn goes right. Straight ahead counts as right, so
		## every turn lies on one side or the other.
		is_right : Angle.Turn -> Bool
		is_right = |Angle.Turn.(turn)| turn >= 0.0

		## Whether this turn leaves the road on one line: within
		## `straight_or_back_tolerance` of 0 degrees, where it runs straight on, or
		## of 180 either way, where it folds straight back.
		is_straight_or_back : Angle.Turn -> Bool
		is_straight_or_back = |Angle.Turn.(turn)| {
			tolerance_sine = straight_or_back_tolerance.to_radians().sin()
			turn.sin().abs() <= tolerance_sine
		}

		is_gt : Angle.Turn, Angle.Turn -> Bool
		is_gt = |Angle.Turn.(turn), Angle.Turn.(other)| turn > other

		is_gte : Angle.Turn, Angle.Turn -> Bool
		is_gte = |Angle.Turn.(turn), Angle.Turn.(other)| turn >= other

		is_lt : Angle.Turn, Angle.Turn -> Bool
		is_lt = |Angle.Turn.(turn), Angle.Turn.(other)| turn < other

		is_lte : Angle.Turn, Angle.Turn -> Bool
		is_lte = |Angle.Turn.(turn), Angle.Turn.(other)| turn <= other

		is_eq : _
	}

	Lean :: F64.{

		radians : F64 -> Angle.Lean
		radians = |count| Angle.Lean.(count)

		## The lean of this many degrees.
		degrees : F64 -> Angle.Lean
		degrees = |count| Angle.Lean.(count * Trig.degree)

		to_radians : Angle.Lean -> F64
		to_radians = |Angle.Lean.(lean)| lean

		## This lean in degrees, as a canvas takes a rotation.
		to_degrees : Angle.Lean -> F64
		to_degrees = |Angle.Lean.(lean)| lean * Trig.degrees_per_radian

		## This lean, changed by `change`.
		plus : Angle.Lean, Angle.LeanChange -> Angle.Lean
		plus = |Angle.Lean.(lean), Angle.LeanChange.(change)| Angle.Lean.(lean + change)

		## This lean, changed by `change` the other way.
		minus : Angle.Lean, Angle.LeanChange -> Angle.Lean
		minus = |Angle.Lean.(lean), Angle.LeanChange.(change)| Angle.Lean.(lean - change)

		## The lean halfway between this one and `other`.
		halfway_to : Angle.Lean, Angle.Lean -> Angle.Lean
		halfway_to = |Angle.Lean.(lean), Angle.Lean.(other)| Angle.Lean.((lean + other) / 2.0)

		## The same lean taken to the right.
		abs : Angle.Lean -> Angle.Lean
		abs = |Angle.Lean.(lean)| Angle.Lean.(lean.abs())

		## How many of `whole` this lean is: negative for a lean to the left.
		ratio_to : Angle.Lean, Angle.Lean -> F64
		ratio_to = |Angle.Lean.(lean), Angle.Lean.(whole)| lean / whole

		## The turn this lean makes at `rate` radians of turn for each radian
		## of lean.
		steer : Angle.Lean, F64 -> Angle.Turn
		steer = |Angle.Lean.(lean), rate| Angle.Turn.(rate * lean)

		is_gt : Angle.Lean, Angle.Lean -> Bool
		is_gt = |Angle.Lean.(lean), Angle.Lean.(other)| lean > other

		is_gte : Angle.Lean, Angle.Lean -> Bool
		is_gte = |Angle.Lean.(lean), Angle.Lean.(other)| lean >= other

		is_lt : Angle.Lean, Angle.Lean -> Bool
		is_lt = |Angle.Lean.(lean), Angle.Lean.(other)| lean < other

		is_lte : Angle.Lean, Angle.Lean -> Bool
		is_lte = |Angle.Lean.(lean), Angle.Lean.(other)| lean <= other

		is_eq : _
	}

	## How far a lean changes, measured from the lean before, as a lean is
	## measured from upright.
	LeanChange :: F64.{

		## The change of this many degrees.
		degrees : F64 -> Angle.LeanChange
		degrees = |count| Angle.LeanChange.(count * Trig.degree)

		to_radians : Angle.LeanChange -> F64
		to_radians = |Angle.LeanChange.(change)| change

		is_eq : _
	}

	north : Angle.Bearing
	north = Angle.Bearing.(0.0)

	straight_ahead : Angle.Turn
	straight_ahead = Angle.Turn.(0.0)

	upright : Angle.Lean
	upright = Angle.Lean.(0.0)
}

expect Angle.Lean.radians(-0.5).ratio_to(Angle.Lean.radians(2.0)) == -0.25

## How near 0 or 180 degrees a turn may come and still turn the road off its
## line: a millionth of a degree. Rounding leaves the sine of a 180-degree turn
## at about 1.2e-16 rather than 0, which this is far above, and every turn a
## route makes is many degrees, which this is far below.
straight_or_back_tolerance : Angle.Turn
straight_or_back_tolerance = Angle.Turn.degrees(0.000001)

# Exactly straight, exactly back either way, and within the tolerance of each,
# leave the road on one line; twice the tolerance off, or a real bend, doesn't.
expect
	[
		(0.0, True),
		(0.0000005, True),
		(-0.0000005, True),
		(180.0, True),
		(-180.0, True),
		(179.9999995, True),
		(-179.9999995, True),
		(0.000002, False),
		(-0.000002, False),
		(179.999998, False),
		(-179.999998, False),
		(15.0, False),
		(90.0, False),
		(-120.0, False),
	].all(|(degrees, want)| Angle.Turn.degrees(degrees).is_straight_or_back() == want)

# A turn inside the limit stays, one past it is held to it on either side, and
# a limit of zero holds every turn straight ahead.
expect {
	clamped = |turn, limit| {
		held = Angle.Turn.radians(turn).clamped_within(Angle.Turn.radians(limit))
		held.to_radians()
	}
	[
		(0.3, 0.5, 0.3),
		(0.5, 0.5, 0.5),
		(0.7, 0.5, 0.5),
		(-0.7, 0.5, -0.5),
		(0.7, 0.0, 0.0),
		(-0.7, 0.0, 0.0),
	].all(|(turn, limit, want)| clamped(turn, limit) == want)
}

## The turn `x`, taken a whole circle at a time to between minus pi and pi. A
## turn of more than `most_wrapped_circles` circles crashes, because no angle
## here grows that far unless it is a bug.
wrap : F64 -> F64
wrap = |x| wrap_within(x, most_wrapped_circles)

most_wrapped_circles : I64
most_wrapped_circles = 64

## The turn `x`, taken to between minus pi and pi in at most `circles_left` circles.
wrap_within : F64, I64 -> F64
wrap_within = |x, circles_left|
	if x > F64.pi and circles_left > 0 {
		wrap_within(x - F64.tau, circles_left - 1)
	} else if x < -F64.pi and circles_left > 0 {
		wrap_within(x + F64.tau, circles_left - 1)
	} else if x > F64.pi or x < -F64.pi {
		crash "Angle.wrap: a turn of more circles than an angle here can reach"
	} else {
		x
	}

expect
	[
		(0.0, 0.0),
		(3.0, 3.0),
		(-3.0, -3.0),
		(4.0, 4.0 - F64.tau),
		(-4.0, F64.tau - 4.0),
		(8.0, 8.0 - F64.tau),
	].all(|(x, want)| wrap(x) == want)

# The most circles a turn can be taken round, one way or the other.
expect wrap_within(8.0, 1) == 8.0 - F64.tau
expect wrap_within(-8.0, 1) == F64.tau - 8.0
expect wrap_within(3.0, 0) == 3.0
