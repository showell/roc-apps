## The rider's mind: how far to lean and how hard to accelerate.
import EncounterPlan
import LeanSearch
import Motorcycle
import Route
import Throttle

Rider :: [].{

	## The lean toward the best line, and the speed the throttle gives the
	## motorcycle once it leans so, on `route` with the encounter on the
	## motorcycle's segment at `encounter_timing`.
	controls : Motorcycle,
	{
		route : Route,
		encounter_timing : EncounterPlan.Timing,
	} -> Motorcycle.Controls
	controls = |motorcycle, ride| {
		lean = LeanSearch.best_lean(motorcycle)
		{ lean, speed: Throttle.next_speed(motorcycle.with_lean(lean), ride) }
	}
}
