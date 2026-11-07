## What a segment's encounter does to the rider. The rider reacts only to the
## encounter on their own segment, and this is the one place that knows which
## encounters ask anything of them. A cat in the road stops the rider opening
## the throttle, without braking, and draws their eye. A bird asks nothing. The
## pigs' gaze is no encounter, and is Gaze's.
import Acceleration
import Animation
import Attention
import Cat
import Route
import Segment
import VehicleLimits
import World

EncounterReaction :: [].{

	## What `segment`'s encounter, at `timing`, asks of the throttle of a rider
	## on that segment: while a cat crosses, the rider eases off, holding the
	## acceleration at none, which stops them speeding up and never brakes.
	encounter_throttle : Segment, Animation.Timing -> VehicleLimits.Limit
	encounter_throttle = |segment, timing|
		match segment.encounter {
			CatCrosses(_) =>
				if Cat.is_crossing(Cat.crossing_stage(timing)) {
					AtMost(Acceleration.steady)
				} else {
					NoLimit
				}
			BirdHere(_) | QuietRoad => NoLimit
		}

	## How hard `segment`'s encounter, at `timing`, holds the eye of a rider on
	## that segment.
	encounter_attention : Segment, Animation.Timing -> Attention
	encounter_attention = |segment, timing|
		match segment.encounter {
			CatCrosses(_) => Cat.attention(Cat.crossing_stage(timing))
			BirdHere(_) | QuietRoad => Attention.none
		}
}

bird_segment : Segment
bird_segment = World.route.segment_at(Route.SegmentIndex.number(0))

quiet_segment : Segment
quiet_segment = World.route.segment_at(Route.SegmentIndex.number(1))

cat_segment : Segment
cat_segment = World.route.segment_at(Route.SegmentIndex.number(3))

# Before its encounter is planned, no segment asks anything of the rider. A
# planned one is CrossModuleExpects', which can name a step of the clock.
expect
	[bird_segment, quiet_segment, cat_segment].all(
		|segment|
			EncounterReaction.encounter_throttle(segment, Unplanned) == NoLimit
				and EncounterReaction.encounter_attention(segment, Unplanned) == Attention.none,
	)
