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

	## Where a coast ends up, and the motorcycle at each of its steps, the last
	## one the step that ends it.
	Path : { outcome : Coast.Outcome, path_motorcycles : List(Motorcycle) }

	## The coast from `motorcycle`, step by step.
	coast_path : Motorcycle -> Coast.Path
	coast_path = |motorcycle| coast_keeping(motorcycle, KeepPath)

	## Where a coast from `motorcycle` ends up.
	project : Motorcycle -> Coast.Outcome
	project = |motorcycle| coast_keeping(motorcycle, DropPath).outcome
}

## A coast from `motorcycle`, with its path or with an empty one. `project` runs
## inside every step of the ride, and building the path there makes a
## release-built ride two and a half times as slow, so only `coast_path` keeps
## it.
coast_keeping : Motorcycle, [KeepPath, DropPath] -> Coast.Path
coast_keeping = |motorcycle, keeping| {
	start = motorcycle.route_place
	inset_hw = Geom.road_half_width.minus(shoulder_margin)
	right_bound = Across.right_of_middle(inset_hw).max(start.across)
	left_bound = Across.left_of_middle(inset_hw).min(start.across)
	var $motorcycle = motorcycle
	var $steps_run = Steps.zero
	var $path = []
	while $steps_run < longest_coast {
		$motorcycle = $motorcycle.motorcycle_at_next_step($motorcycle.steady_controls())
		$steps_run = $steps_run.plus(Steps.one_step)
		$path =
			match keeping {
				KeepPath => $path.append($motorcycle)
				DropPath => $path
			}
		if $motorcycle.route_place.across < left_bound {
			return { outcome: Leaves({ side: Left, after: $steps_run }), path_motorcycles: $path }
		}
		if $motorcycle.route_place.across > right_bound {
			return { outcome: Leaves({ side: Right, after: $steps_run }), path_motorcycles: $path }
		}
		if $motorcycle.route_place.along.distance_from(start.along) >= Coast.clear_distance {
			return { outcome: EndsAt($motorcycle.route_place.across), path_motorcycles: $path }
		}
	}
	{ outcome: EndsAt($motorcycle.route_place.across), path_motorcycles: $path }
}

## How far inside each shoulder the rehearsal puts the road's edge: 5 cm.
## A coast that crosses this inset edge counts as leaving the road, so the
## line the search keeps never grazes the shoulder itself.
shoulder_margin : Distance
shoulder_margin = Distance.metres(0.05)

## A slow rider who leans can circle on the road and never get clear of where
## they started, so a coast ends after this many steps.
longest_coast : Steps
longest_coast = Steps.of(2000)
