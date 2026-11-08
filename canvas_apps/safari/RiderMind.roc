## The rider's mind: every decision the rider makes in a step. It chooses how
## far to lean, how hard to accelerate and where to look. Motorcycle and
## RiderEyes hold the dynamics, which carry those choices out.
import Animation
import Gaze
import LeanSearch
import Motorcycle
import Segment
import Throttle

RiderMind :: [].{

	## The lean toward the best line, and the acceleration the throttle gives
	## the motorcycle once it leans so, on `segment`, the one it is on, with the
	## segment's encounter at `encounter_stage`.
	controls : Motorcycle,
	{
		segment : Segment,
		encounter_stage : Animation.Stage,
	} -> Motorcycle.Controls
	controls = |motorcycle, ride| {
		lean = LeanSearch.best_lean(motorcycle)
		{ lean, acceleration: Throttle.next_acceleration(motorcycle.with_lean(lean), ride) }
	}

	## Where the rider wants to look from `motorcycle`, on `segment`, the one
	## it is on.
	gaze_target : Motorcycle, Segment -> Gaze.GazeTarget
	gaze_target = |motorcycle, segment| Gaze.desired_gaze(motorcycle, segment)
}
