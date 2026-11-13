## Coast rehearses the rider's next few seconds: it runs the bike's real physics
## with no change of lean or speed, and says where the rider would end up.
import Across
import Motorcycle
import Distance
import Geom
import Steps

Coast :: [].{

	## Where a coast ends up: still on the road at this place across it, or off
	## a shoulder after this many steps, counting the step that leaves.
	Outcome : [EndsAt(Across), Leaves({ side : [Left, Right], after : Steps })]

	## How far ahead the rehearsal needs to look: 25 m along the road. A coast
	## that runs this far without leaving the road ends there.
	clear_distance : Distance
	clear_distance = Distance.metres(25.0)

	## Where a coast from `motorcycle` ends up.
	coast_outcome : Motorcycle -> Coast.Outcome
	coast_outcome = |motorcycle| coast_end(motorcycle).outcome

	## The motorcycle at each step of a coast from `motorcycle`, the last one the
	## step that ends it.
	path_motorcycles : Motorcycle -> List(Motorcycle)
	path_motorcycles = |motorcycle| {
		var $motorcycle = motorcycle
		var $path = []
		for _ in 0..<coast_end(motorcycle).steps_run.to_u32() {
			$motorcycle = coasting_step($motorcycle)
			$path = $path.append($motorcycle)
		}
		$path
	}
}

## Where a coast ends up, and how many steps it runs to get there.
CoastEnd : { outcome : Coast.Outcome, steps_run : Steps }

## The coast from `motorcycle`, run a step at a time until it crosses a bound,
## gets `clear_distance` along the road, or runs `longest_coast` steps.
coast_end : Motorcycle -> CoastEnd
coast_end = |motorcycle| {
	start = motorcycle.route_place.road_point
	bounds = coast_bounds(start.across)
	var $point = start
	var $steps_run = Steps.zero
	var $motorcycle = motorcycle
	while $steps_run < longest_coast and is_coasting({ bounds, start, point: $point }) {
		$motorcycle = coasting_step($motorcycle)
		$steps_run = $steps_run.plus(Steps.one_step)
		$point = $motorcycle.route_place.road_point
	}
	outcome =
		if $point.across < bounds.left {
			Leaves({ side: Left, after: $steps_run })
		} else if $point.across > bounds.right {
			Leaves({ side: Right, after: $steps_run })
		} else {
			EndsAt($point.across)
		}
	{ outcome, steps_run: $steps_run }
}

## How far across the road a coast may go before it counts as leaving.
CoastBounds : { left : Across, right : Across }

## The bounds of a coast that starts at `start_across`: the road's edges, inset
## by `shoulder_margin`, or `start_across` where that is further out.
coast_bounds : Across -> CoastBounds
coast_bounds = |start_across| {
	inset_half_width = Geom.road_half_width.minus(shoulder_margin)
	{
		left: Across.left_of_middle(inset_half_width).min(start_across),
		right: Across.right_of_middle(inset_half_width).max(start_across),
	}
}

## Whether a coast from `start` that has reached `point` goes on: it is within
## `bounds`, and short of `clear_distance` along the road.
is_coasting : {
	bounds : CoastBounds,
	start : Geom.RoadPoint,
	point : Geom.RoadPoint,
} -> Bool
is_coasting = |{ bounds, start, point }|
	point.across >= bounds.left
		and point.across <= bounds.right
		and point.along.distance_from(start.along) < Coast.clear_distance

## The motorcycle one step on, holding its lean and speed.
coasting_step : Motorcycle -> Motorcycle
coasting_step = |motorcycle| motorcycle.motorcycle_at_next_step(motorcycle.steady_controls())

## How far inside each shoulder the rehearsal puts the road's edge: 5 cm.
## A coast that crosses this inset edge counts as leaving the road, so the
## line the search keeps never grazes the shoulder itself.
shoulder_margin : Distance
shoulder_margin = Distance.metres(0.05)

## A slow rider who leans can circle on the road and never get clear of where
## they started, so a coast ends after this many steps.
longest_coast : Steps
longest_coast = Steps.of(2000)
