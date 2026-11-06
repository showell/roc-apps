## Coast rehearses the rider's next few seconds: it runs the bike's real physics
## with no change of lean or speed, and says where the rider would end up.
import Acceleration
import Across
import Along
import Angle
import Bike
import Distance
import Scenery
import Steps

Coast :: [].{

	## Where a coast ends up: off a shoulder after this many steps, or still
	## on the road.
	Exit : [StaysOn, Leaves({ side : [Left, Right], after : Steps })]

	Outcome : {
		exit : Coast.Exit,
		forward : Distance,
		end_across : Across,
	}

	straighten_margin : Distance
	straighten_margin = Distance.metres(0.05)

	longest_coast : Steps
	longest_coast = Steps.of(2000)

	clear_distance : Distance
	clear_distance = Distance.metres(25.0)

	## What holds for the whole of one coast: the road's edges, and
	## the distance along the road the rider started from.
	Bounds : {
		left_bound : Across,
		right_bound : Across,
		start_along : Along,
	}

	## Where a coast has reached: how many steps it has run, and the coasting
	## rider.
	Progress(others) : { steps_run : Steps, coasting_rider : Bike.Motion(others) }

	coast_from : Coast.Bounds, Coast.Progress(others) -> Coast.Outcome
	coast_from = |course, { steps_run: i, coasting_rider: phys }|
		if i >= longest_coast {
			{
				exit: StaysOn,
				forward: phys.along.distance_from(course.start_along),
				end_across: phys.across,
			}
		} else {
			judge_place(
				course,
				{
					steps_run: i,
					coasting_rider: Bike.advance(
						phys,
						{ lean_step: Angle.upright, acceleration: Acceleration.steady },
					),
				},
			)
		}

	judge_place : Coast.Bounds, Coast.Progress(others) -> Coast.Outcome
	judge_place = |course, { steps_run: i, coasting_rider: phys }| {
		across = phys.across
		forward = phys.along.distance_from(course.start_along)
		if across < course.left_bound {
			{
				exit: Leaves({ side: Left, after: i }),
				forward: forward.min(clear_distance),
				end_across: across,
			}
		} else if across > course.right_bound {
			{
				exit: Leaves({ side: Right, after: i }),
				forward: forward.min(clear_distance),
				end_across: across,
			}
		} else if forward < Distance.zero {
			{ exit: StaysOn, forward, end_across: across }
		} else if forward >= clear_distance {
			{
				exit: StaysOn,
				forward: clear_distance,
				end_across: across,
			}
		} else {
			coast_from(course, { steps_run: i.plus(Steps.one_step), coasting_rider: phys })
		}
	}

	project : Bike.Motion(others) -> Coast.Outcome
	project = |state| {
		inset_hw = Scenery.road_half_width.minus(straighten_margin)
		right_bound = Across.right_of_middle(inset_hw).max(state.across)
		left_bound = Across.left_of_middle(inset_hw).min(state.across)
		coast_from(
			{ left_bound, right_bound, start_along: state.along },
			{ steps_run: Steps.zero, coasting_rider: state },
		)
	}
}

expect Coast.straighten_margin.to_metres() == 0.05
expect Coast.clear_distance.to_metres() == 25.0
expect Coast.longest_coast.to_f64() == 2000.0
