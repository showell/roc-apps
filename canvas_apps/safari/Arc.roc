# Arc -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Acceleration
import Across
import Along
import Angle
import Bike
import Distance
import Scenery
import Steps

Arc :: [].{

	## Where an arc ends up: off a shoulder after this many frames, or still
	## on the road.
	Shoulder : [
		ShoulderLeft(Steps),
		ShoulderNone,
		ShoulderRight(Steps),
	]

	ArcOutcome : {
		shoulder : Arc.Shoulder,
		forward : Distance,
		end_across : Across,
	}

	straighten_margin : Distance
	straighten_margin = Distance.metres(0.05)

	turn_danger_steps : Steps
	turn_danger_steps = Steps.of(2000)

	min_forward_progress : Distance
	min_forward_progress = Distance.metres(25.0)

	## What holds for the whole of one projected arc: the road's edges, and
	## the distance along the road the rider started from.
	ArcCourse : {
		left_bound : Across,
		right_bound : Across,
		start_along : Along,
	}

	## Where a projected arc has reached: how many frames it has run, and the
	## coasting rider.
	ArcProgress(others) : {
		frame_count : Steps,
		coasting_rider : Bike.Motion(others),
	}

	sim_from : Arc.ArcCourse, Arc.ArcProgress(others) -> Arc.ArcOutcome
	sim_from = |
		course,
		{
			frame_count: i,
			coasting_rider: phys,
		},
	|
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

	sim_step : Arc.ArcCourse, Arc.ArcProgress(others) -> Arc.ArcOutcome
	sim_step = |
		course,
		{
			frame_count: i,
			coasting_rider: phys,
		},
	| {
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
			sim_from(
				course,
				{
					frame_count: i.plus(Steps.one_step),
					coasting_rider: phys,
				},
			)
		}
	}

	project_arc : Bike.Motion(others) -> Arc.ArcOutcome
	project_arc = |state| {
		inset_hw = Scenery.lane_half_width.minus(straighten_margin)
		right_bound = Across.right_of_middle(inset_hw).max(state.across)
		left_bound = Across.left_of_middle(inset_hw).min(state.across)
		sim_from(
			{
				left_bound,
				right_bound,
				start_along: state.along,
			},
			{
				frame_count: Steps.zero,
				coasting_rider: state,
			},
		)
	}
}

expect Arc.straighten_margin.to_metres() == 0.05
expect Arc.min_forward_progress.to_metres() == 25.0
expect Arc.turn_danger_steps.to_f64() == 2000.0
