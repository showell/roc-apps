## An encounter is what the rider meets on one segment of the road: a cat
## crossing, a bird's flight, or nothing, a quiet road. A segment has one, so
## that the rider has one experience at a time, and most of the road is quiet,
## so that an encounter stands out.
import Along
import Animation
import BirdFlight
import CatCrossing
import EncounterPlan

Encounter := [CatCrosses(CatCrossing), BirdHere(BirdFlight), QuietRoad].{

	## What the ride plans `encounter` by: its animation's span, and where along
	## its segment its animal is, or none on a quiet road.
	encounter_span : Encounter -> Try(
		{ span : EncounterPlan.StepSpan, planned_along : Along },
		[QuietRoad],
	)
	encounter_span = |encounter|
		match encounter {
			CatCrosses(crossing) =>
				Ok({ span: CatCrossing.crossing_span, planned_along: crossing.planned_along() })
			BirdHere(flight) =>
				Ok({ span: BirdFlight.flight_span, planned_along: flight.planned_along() })
			QuietRoad => Err(QuietRoad)
		}

	## Where `encounter` has got to at `timing`, as long as its animal's
	## animation lasts. A quiet road has nothing to wait for, so it stays
	## `Waiting`.
	encounter_stage : Encounter, EncounterPlan.Timing -> Animation.Stage
	encounter_stage = |encounter, timing|
		match encounter {
			CatCrosses(_) => CatCrossing.crossing_stage(timing)
			BirdHere(_) => BirdFlight.flight_stage(timing)
			QuietRoad => Waiting
		}
}
