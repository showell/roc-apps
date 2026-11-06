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
	Shoulder : [ShoulderLeft(Steps), ShoulderNone, ShoulderRight(Steps)]

	Outcome : {
		shoulder : Coast.Shoulder,
		forward : Distance,
		end_across : Across,
	}

	straighten_margin : Distance
	straighten_margin = Distance.metres(0.05)

	turn_danger_steps : Steps
	turn_danger_steps = Steps.of(2000)

	min_forward_progress : Distance
	min_forward_progress = Distance.metres(25.0)

	## What holds for the whole of one coast: the road's edges, and
	## the distance along the road the rider started from.
	Bounds : {
		left_bound : Across,
		right_bound : Across,
		start_along : Along,
	}

	## Where a coast has reached: how many steps it has run, and the coasting
	## rider.
	Progress(others) : { frame_count : Steps, coasting_rider : Bike.Motion(others) }

	sim_from : Coast.Bounds, Coast.Progress(others) -> Coast.Outcome
	sim_from = |course, { frame_count: i, coasting_rider: phys }|
		if i >= turn_danger_steps {
			{
				shoulder: ShoulderNone,
				forward: phys.along.distance_from(course.start_along),
				end_across: phys.across,
			}
		} else {
			sim_step(
				course,
				{
					frame_count: i,
					coasting_rider: Bike.simulate_rider_step(
						phys,
						{ lean_step: Angle.upright, accel: Acceleration.steady },
					),
				},
			)
		}

	sim_step : Coast.Bounds, Coast.Progress(others) -> Coast.Outcome
	sim_step = |course, { frame_count: i, coasting_rider: phys }| {
		across = phys.across
		forward = phys.along.distance_from(course.start_along)
		if across < course.left_bound {
			{
				shoulder: ShoulderLeft(i),
				forward: forward.min(min_forward_progress),
				end_across: across,
			}
		} else if across > course.right_bound {
			{
				shoulder: ShoulderRight(i),
				forward: forward.min(min_forward_progress),
				end_across: across,
			}
		} else if forward < Distance.zero {
			{
				shoulder: ShoulderNone,
				forward: forward,
				end_across: across,
			}
		} else if forward >= min_forward_progress {
			{
				shoulder: ShoulderNone,
				forward: min_forward_progress,
				end_across: across,
			}
		} else {
			sim_from(course, { frame_count: i.plus(Steps.one_step), coasting_rider: phys })
		}
	}

	project : Bike.Motion(others) -> Coast.Outcome
	project = |state| {
		inset_hw = Scenery.lane_half_width.minus(straighten_margin)
		right_bound = Across.right_of_middle(inset_hw).max(state.across)
		left_bound = Across.left_of_middle(inset_hw).min(state.across)
		sim_from(
			{ left_bound, right_bound, start_along: state.along },
			{ frame_count: Steps.zero, coasting_rider: state },
		)
	}
}

expect Coast.straighten_margin.to_metres() == 0.05
expect Coast.min_forward_progress.to_metres() == 25.0
expect Coast.turn_danger_steps.to_f64() == 2000.0
