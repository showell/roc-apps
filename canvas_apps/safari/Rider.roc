## The rider's mind: how far to lean and how hard to accelerate.
import EncounterPlan
import LeanSearch
import Motorcycle
import Segment
import Throttle

Rider :: [].{

	## The lean toward the best line, and the speed the throttle gives the
	## motorcycle once it leans so.
	controls : Motorcycle,
	{
		segment : Segment,
		encounter_timing : EncounterPlan.Timing,
	} -> Motorcycle.Controls
	controls = |motorcycle, road| {
		lean = LeanSearch.best_lean(motorcycle)
		{ lean, speed: Throttle.next_speed(motorcycle.with_lean(lean), road) }
	}
}
