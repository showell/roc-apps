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

	straighten_margin : Distance
	straighten_margin = Distance.metres(0.05)

	clear_distance : Distance
	clear_distance = Distance.metres(25.0)

	project : Motorcycle -> Coast.Outcome
	project = |state| {
		inset_hw = Geom.road_half_width.minus(straighten_margin)
		right_bound = Across.right_of_middle(inset_hw).max(state.across)
		left_bound = Across.left_of_middle(inset_hw).min(state.across)
		var $rider = state
		var $steps_run = Steps.zero
		while $steps_run < longest_coast {
			$rider = $rider.motorcycle_at_next_step($rider.steady_controls())
			$steps_run = $steps_run.plus(Steps.one_step)
			if $rider.across < left_bound {
				return Leaves({ side: Left, after: $steps_run })
			}
			if $rider.across > right_bound {
				return Leaves({ side: Right, after: $steps_run })
			}
			if $rider.along.distance_from(state.along) >= clear_distance {
				return EndsAt($rider.across)
			}
		}
		EndsAt($rider.across)
	}
}

## A slow rider who leans can circle on the road and never get clear of where
## they started, so a coast ends after this many steps.
longest_coast : Steps
longest_coast = Steps.of(2000)
