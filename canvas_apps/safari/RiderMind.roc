## The rider's mind: how far to lean and how hard to accelerate.
import EncounterPlan
import LeanSearch
import Motorcycle
import Segment
import Throttle

RiderMind :: [].{

	## The lean toward the best line, and the acceleration the throttle gives
	## the motorcycle once it leans so, on `segment`, the one it is on, with the
	## segment's encounter at `encounter_timing`.
	controls : Motorcycle,
	{
		segment : Segment,
		encounter_timing : EncounterPlan.Timing,
	} -> Motorcycle.Controls
	controls = |motorcycle, ride| {
		lean = LeanSearch.best_lean(motorcycle)
		{ lean, acceleration: Throttle.next_acceleration(motorcycle.with_lean(lean), ride) }
	}
}
