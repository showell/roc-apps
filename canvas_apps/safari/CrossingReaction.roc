## What a segment's crossing does to the rider. The rider reacts only to the
## crossing on their own segment, though animations play along the road ahead,
## and this is the one place that knows which crossings ask anything of them.
## A cat in the road stops the rider opening the throttle, without braking, and
## draws their eye. A bird asks nothing. The pigs' gaze is no crossing, and is
## Gaze's.
import Acceleration
import Along
import Attention
import Cat
import Route
import Segment
import Speed
import VehicleLimits
import World

CrossingReaction :: [].{

	## What `segment`'s crossing asks of the throttle of a rider on that
	## segment: a cat crossing holds the acceleration at none, which stops the
	## rider speeding up and never brakes.
	crossing_throttle : Segment, { along : Along, speed : Speed, .. } -> VehicleLimits.Limit
	crossing_throttle = |segment, rider|
		match segment.crossing {
			CatCrosses(crossing) => {
				approach = { gap: crossing.along.distance_from(rider.along), speed: rider.speed }
				if Cat.is_crossing(approach) {
					AtMost(Acceleration.steady)
				} else {
					NoLimit
				}
			}
			BirdHere(_) | QuietRoad => NoLimit
		}

	## How hard `segment`'s crossing holds the eye of a rider on that segment.
	crossing_attention : Segment, { along : Along, speed : Speed, .. } -> Attention
	crossing_attention = |segment, rider|
		match segment.crossing {
			CatCrosses(crossing) => {
				approach = { gap: crossing.along.distance_from(rider.along), speed: rider.speed }
				Cat.attention(approach)
			}
			BirdHere(_) | QuietRoad => Attention.none
		}
}

bird_segment : Segment
bird_segment = World.route.segment_at(Route.SegmentIndex.number(0))

quiet_segment : Segment
quiet_segment = World.route.segment_at(Route.SegmentIndex.number(1))

cat_segment : Segment
cat_segment = World.route.segment_at(Route.SegmentIndex.number(3))

cat_along : Along
cat_along =
	match cat_segment.crossing {
		CatCrosses(crossing) => crossing.along
		BirdHere(_) | QuietRoad => crash "CrossingReaction: segment 3 has a cat"
	}

## A rider `along` their segment at `speed` metres a step.
rider_at : Along, F64 -> { along : Along, speed : Speed }
rider_at = |along, speed| { along, speed: Speed.metres_a_step(speed) }

## A rider `gap` metres short of the cat, at `speed` metres a step.
short_of_cat : F64, F64 -> { along : Along, speed : Speed }
short_of_cat = |gap, speed| rider_at(Along.metres(cat_along.to_metres() - gap), speed)

## What the cat asks of the throttle of a rider `gap` metres short of it.
throttle_for_cat : F64, F64 -> VehicleLimits.Limit
throttle_for_cat = |gap, speed|
	CrossingReaction.crossing_throttle(cat_segment, short_of_cat(gap, speed))

## How hard the cat holds the eye of a rider `gap` metres short of it.
attention_to_cat : F64, F64 -> F64
attention_to_cat = |gap, speed|
	CrossingReaction.crossing_attention(cat_segment, short_of_cat(gap, speed)).to_f64()

expect throttle_for_cat(42.0, 1.0) == NoLimit
expect throttle_for_cat(41.0, 1.0) == NoLimit
expect throttle_for_cat(40.5, 1.0) == AtMost(Acceleration.steady)
expect throttle_for_cat(22.0, 1.0) == AtMost(Acceleration.steady)
expect throttle_for_cat(3.5, 1.0) == AtMost(Acceleration.steady)
expect throttle_for_cat(3.0, 1.0) == NoLimit
expect throttle_for_cat(2.0, 1.0) == NoLimit
expect throttle_for_cat(22.0, 0.0) == NoLimit

expect
	[
		(attention_to_cat(42.0, 1.0), 0.0),
		(attention_to_cat(41.0, 1.0), 0.0),
		(attention_to_cat(22.0, 1.0), 0.9),
		(attention_to_cat(3.0, 1.0), 1.8),
		(attention_to_cat(-38.5, 1.0), 0.9),
		(attention_to_cat(-80.0, 1.0), 0.0),
		(attention_to_cat(22.0, 0.0), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)

# A bird or a quiet road at each place on it, and at each speed.
expect
	[bird_segment, quiet_segment].all(
		|segment| [0.0, 60.0, 100.0, 200.0, 400.0].all(
			|along| [0.0, 0.3, 1.0].all(
				|speed| {
					rider = rider_at(Along.metres(along), speed)
					CrossingReaction.crossing_throttle(segment, rider) == NoLimit
						and CrossingReaction.crossing_attention(segment, rider) == Attention.none
				},
			),
		),
	)
