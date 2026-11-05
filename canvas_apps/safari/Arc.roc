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
import lib.Trig

Arc :: [].{
	Shoulder : [ShoulderLeft, ShoulderNone, ShoulderRight]
	ArcOutcome : {
		shoulder : Arc.Shoulder,
		forward : Distance,
		crossed : Bool,
		end_across : Across,
		frames : Steps,
	}

	no_frames : Steps
	no_frames = Steps.of(1000000000)

	straighten_margin : Distance
	straighten_margin = Distance.metres(0.05)

	turn_danger_steps : Steps
	turn_danger_steps = Steps.of(2000)

	min_forward_progress : Distance
	min_forward_progress = Distance.metres(25.0)

	## What holds for the whole of one projected arc: the road's edges, and
	## the side and distance along the road the rider started from.
	ArcCourse : {
		left_bound : Across,
		right_bound : Across,
		start_side : F64,
		start_along : Along,
	}

	## Where a projected arc has reached: whether it has crossed the centre
	## line, how many frames it has run, and the coasting rider.
	ArcProgress(others) : {
		has_crossed : Bool,
		frame_count : Steps,
		coasting_rider : Bike.Motion(others),
	}

	sim_from : Arc.ArcCourse, Arc.ArcProgress(others) -> Arc.ArcOutcome
	sim_from = |
		course,
		{
			has_crossed: crossed,
			frame_count: i,
			coasting_rider: phys,
		},
	| (
		if i >= turn_danger_steps {
			{
				shoulder: ShoulderNone,
				forward: phys.along.distance_from(course.start_along),
				crossed: crossed,
				end_across: phys.across,
				frames: no_frames,
			}
		} else {
			sim_step(
				course,
				{
					has_crossed: crossed,
					frame_count: i,
					coasting_rider: Bike.simulate_rider_step(
						phys,
						{ lean_step: Angle.upright, accel: Acceleration.steady },
					),
				},
			)
		}
	)

	sim_step : Arc.ArcCourse, Arc.ArcProgress(others) -> Arc.ArcOutcome
	sim_step = |
		course,
		{
			has_crossed: crossed0,
			frame_count: i,
			coasting_rider: phys,
		},
	| (
		{
			across = phys.across
			forward = phys.along.distance_from(course.start_along)
			crossed = (
				if (across.to_metres() * course.start_side) < 0.0 {
					True
				} else {
					crossed0
				}
			)
			(
				if across < course.left_bound {
					{
						shoulder: ShoulderLeft,
						forward: forward.min(min_forward_progress),
						crossed: crossed,
						end_across: across,
						frames: i,
					}
				} else {
					(
						if across > course.right_bound {
							{
								shoulder: ShoulderRight,
								forward: forward.min(min_forward_progress),
								crossed: crossed,
								end_across: across,
								frames: i,
							}
						} else {
							(
								if forward < Distance.zero {
									{
										shoulder: ShoulderNone,
										forward: forward,
										crossed: crossed,
										end_across: across,
										frames: no_frames,
									}
								} else {
									(
										if forward >= min_forward_progress {
											{
												shoulder: ShoulderNone,
												forward: min_forward_progress,
												crossed: crossed,
												end_across: across,
												frames: no_frames,
											}
										} else {
											sim_from(
												course,
												{
													has_crossed: crossed,
													frame_count: i.plus(Steps.one_step),
													coasting_rider: phys,
												},
											)
										}
									)
								}
							)
						}
					)
				}
			)
		}
	)

	project_arc : Bike.Motion(others) -> Arc.ArcOutcome
	project_arc = |state| (
		{
			inset_hw = Scenery.lane_half_width.minus(straighten_margin)
			right_bound = Across.right_of_middle(inset_hw).max(state.across)
			left_bound = Across.left_of_middle(inset_hw).min(state.across)
			sim_from(
				{
					left_bound,
					right_bound,
					start_side: Trig.r_sign(state.across.to_metres()),
					start_along: state.along,
				},
				{
					has_crossed: False,
					frame_count: Steps.zero,
					coasting_rider: state,
				},
			)
		}
	)

	eq_Shoulder : Arc.Shoulder, Arc.Shoulder -> Bool
	eq_Shoulder = |ex, ey| (
		match ex {
			ShoulderLeft => (
				match ey {
					ShoulderLeft => True
					_ => False
				}
			)
			ShoulderNone => (
				match ey {
					ShoulderNone => True
					_ => False
				}
			)
			ShoulderRight => (
				match ey {
					ShoulderRight => True
					_ => False
				}
			)
		}
	)
}
