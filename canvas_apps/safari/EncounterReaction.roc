## What a segment's encounter does to the rider. The rider reacts only to the
## encounter on their own segment, and this is the one place that knows which
## encounters ask anything of them. A cat in the road stops the rider opening
## the throttle, without braking, and draws their eye. A bird asks nothing. The
## pigs' gaze is no encounter, and is Gaze's.
import Acceleration
import EncounterPlan
import Attention
import Cat
import Segment
import VehicleLimits

EncounterReaction :: [].{

	## What `segment`'s encounter, at `timing`, asks of the throttle of a rider
	## on that segment: while a cat crosses, the rider eases off, holding the
	## acceleration at none, which stops them speeding up and never brakes.
	encounter_throttle : Segment, EncounterPlan.Timing -> VehicleLimits.Limit
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
	encounter_attention : Segment, EncounterPlan.Timing -> Attention
	encounter_attention = |segment, timing|
		match segment.encounter {
			CatCrosses(_) => Cat.attention(Cat.crossing_stage(timing))
			BirdHere(_) | QuietRoad => Attention.none
		}
}
