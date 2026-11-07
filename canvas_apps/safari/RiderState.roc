## The rider from one step to the next: which segment of the route they are on,
## the motorcycle they ride, and where their eyes are.
import Motorcycle
import RiderEyes
import Route

## The rider at one step. `segment_index` is the segment of the route the
## motorcycle is on, which places its `along` and `across`.
RiderState := {
	segment_index : Route.SegmentIndex,
	motorcycle : Motorcycle,
	eyes : RiderEyes,
}.{

	initial : RiderState
	initial = {
		segment_index: Route.SegmentIndex.first,
		motorcycle: Motorcycle.initial,
		eyes: RiderEyes.initial,
	}
}

expect RiderState.initial.segment_index.to_i64() == 0
expect RiderState.initial.motorcycle == Motorcycle.initial
expect RiderState.initial.eyes == RiderEyes.initial
