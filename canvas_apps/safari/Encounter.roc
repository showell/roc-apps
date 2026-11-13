## An encounter is what the rider meets on one segment of the road: a cat
## crossing, a bird's flight, or nothing, a quiet road. A segment has one, so
## that the rider has one experience at a time, and most of the road is quiet,
## so that an encounter stands out.
import Along
import Animation
import BirdFlight
import CatCrossing
import Clock
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

	## Where `encounter`'s animation, started by `plan`, has got to with the
	## ride's clock at `now`, as long as its span lasts. A quiet road has nothing
	## to wait for, so it stays `Waiting`.
	encounter_stage : Encounter, { plan : EncounterPlan, now : Clock } -> Animation.Stage
	encounter_stage = |encounter, { plan, now }|
		match encounter.encounter_span() {
			Ok({ span, .. }) => plan.stage_at({ now, length: span.length })
			Err(QuietRoad) => Waiting
		}
}
