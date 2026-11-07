## What a segment's encounter does to the rider. The rider reacts only to the
## encounter on their own segment, though animations play along the road ahead,
## and this is the one place that knows which encounters ask anything of them.
## A cat in the road stops the rider opening the throttle, without braking, and
## draws their eye. A bird asks nothing. The pigs' gaze is no encounter, and is
## Gaze's.
import Acceleration
import Along
import Animation
import Attention
import Cat
import CatCrossing
import Route
import Segment
import Speed
import VehicleLimits
import World

EncounterReaction :: [].{

	## What `segment`'s encounter asks of the throttle of a rider on that
	## segment: a cat crossing holds the acceleration at none, which stops the
	## rider speeding up and never brakes.
	encounter_throttle : Segment, { along : Along, speed : Speed, .. } -> VehicleLimits.Limit
	encounter_throttle = |segment, rider|
		match segment.encounter {
			CatCrosses(crossing) =>
				if Cat.is_crossing(cat_approach(crossing, rider)) {
					AtMost(Acceleration.steady)
				} else {
					NoLimit
				}
			BirdHere(_) | QuietRoad => NoLimit
		}

	## How hard `segment`'s encounter holds the eye of a rider on that segment.
	encounter_attention : Segment, { along : Along, speed : Speed, .. } -> Attention
	encounter_attention = |segment, rider|
		match segment.encounter {
			CatCrosses(crossing) => Cat.attention(cat_approach(crossing, rider))
			BirdHere(_) | QuietRoad => Attention.none
		}
}

## How a rider comes on `crossing`'s cat: the gap along the road to it, and
## their speed.
cat_approach : CatCrossing, { along : Along, speed : Speed, .. } -> Animation.Approach
cat_approach = |crossing, rider| {
	gap: crossing.along.distance_from(rider.along),
	speed: rider.speed,
}

bird_segment : Segment
bird_segment = World.first_bird_segment

quiet_segment : Segment
quiet_segment = World.route.segment_at(Route.SegmentIndex.number(1))

cat_segment : Segment
cat_segment = World.first_cat_segment

cat_along : Along
cat_along = World.first_cat_crossing.along

## A rider `along` their segment at `speed` metres a step.
rider_at : Along, F64 -> { along : Along, speed : Speed }
rider_at = |along, speed| { along, speed: Speed.metres_a_step(speed) }

## A rider `gap` metres short of the cat, at `speed` metres a step.
short_of_cat : F64, F64 -> { along : Along, speed : Speed }
short_of_cat = |gap, speed| rider_at(Along.metres(cat_along.to_metres() - gap), speed)

## What the cat asks of the throttle of a rider `gap` metres short of it.
throttle_for_cat : F64, F64 -> VehicleLimits.Limit
throttle_for_cat = |gap, speed|
	EncounterReaction.encounter_throttle(cat_segment, short_of_cat(gap, speed))

## How hard the cat holds the eye of a rider `gap` metres short of it.
attention_to_cat : F64, F64 -> F64
attention_to_cat = |gap, speed|
	EncounterReaction.encounter_attention(cat_segment, short_of_cat(gap, speed)).to_f64()

# One case for each answer the cat gives; Cat's own expects hold its tables.
expect throttle_for_cat(22.0, 1.0) == AtMost(Acceleration.steady)
expect throttle_for_cat(42.0, 1.0) == NoLimit
expect attention_to_cat(22.0, 1.0) > 0.0

# A bird or a quiet road at each place on it, and at each speed.
expect
	[bird_segment, quiet_segment].all(
		|segment| [0.0, 60.0, 100.0, 200.0, 400.0].all(
			|along| [0.0, 0.3, 1.0].all(
				|speed| {
					rider = rider_at(Along.metres(along), speed)
					EncounterReaction.encounter_throttle(segment, rider) == NoLimit
						and EncounterReaction.encounter_attention(segment, rider) == Attention.none
				},
			),
		),
	)
