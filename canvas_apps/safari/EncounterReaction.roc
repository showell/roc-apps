## What the encounters ahead do to the rider. The rider reacts only to the cat
## on their own segment, though animals move along the whole road ahead, and
## this is the one place that knows which encounters ask anything of them. A
## cat in the road stops the rider opening the throttle, without braking, and
## draws their eye. A bird asks nothing. The pigs' gaze is no encounter, and is
## Gaze's.
import Acceleration
import Attention
import Cat
import EncountersAhead
import VehicleLimits

EncounterReaction :: [].{

	## What `encounters` ask of the throttle: a cat crossing the rider's own
	## segment holds the acceleration at none, which stops the rider speeding up
	## and never brakes.
	encounter_throttle : EncountersAhead -> VehicleLimits.Limit
	encounter_throttle = |encounters|
		match encounters.rider_cat_approach() {
			Ok(approach) =>
				if Cat.is_crossing(approach) {
					AtMost(Acceleration.steady)
				} else {
					NoLimit
				}
			Err(NoCat) => NoLimit
		}

	## How hard `encounters` hold the rider's eye.
	encounter_attention : EncountersAhead -> Attention
	encounter_attention = |encounters|
		match encounters.rider_cat_approach() {
			Ok(approach) => Cat.attention(approach)
			Err(NoCat) => Attention.none
		}
}
