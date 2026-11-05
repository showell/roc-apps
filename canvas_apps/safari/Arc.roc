# Arc -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Acceleration
import Angle
import Bike
import lib.DeviceMath
import Scenery
import Steps
import lib.Trig

Arc :: [].{
	Shoulder : [ShoulderLeft, ShoulderNone, ShoulderRight]
	ArcOutcome : {
		shoulder : Arc.Shoulder,
		forward : F64,
		crossed : Bool,
		end_across : F64,
		frames : Steps,
	}

	no_frames : Steps
	no_frames = Steps.of(1000000000)

	straighten_margin : F64
	straighten_margin = 0.05

	turn_danger_steps : Steps
	turn_danger_steps = Steps.of(2000)

	min_forward_progress : F64
	min_forward_progress = 25.0

	## What holds for the whole of one projected arc: the road's edges, and
	## the side and distance along the road the rider started from.
	ArcCourse : {
		left_bound : F64,
		right_bound : F64,
		start_side : F64,
		start_along : F64,
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
				forward: (phys.along - course.start_along),
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
			forward = (phys.along - course.start_along)
			crossed = (
				if (across * course.start_side) < 0.0 {
					True
				} else {
					crossed0
				}
			)
			(
				if across < course.left_bound {
					{
						shoulder: ShoulderLeft,
						forward: DeviceMath.real_min(forward, min_forward_progress),
						crossed: crossed,
						end_across: across,
						frames: i,
					}
				} else {
					(
						if across > course.right_bound {
							{
								shoulder: ShoulderRight,
								forward: DeviceMath.real_min(forward, min_forward_progress),
								crossed: crossed,
								end_across: across,
								frames: i,
							}
						} else {
							(
								if forward < 0.0 {
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
			inset_hw = ((Scenery.lane_width / 2.0) - straighten_margin)
			right_bound = DeviceMath.real_max(inset_hw, state.across)
			left_bound = DeviceMath.real_min((0.0 - inset_hw), state.across)
			sim_from(
				{
					left_bound,
					right_bound,
					start_side: Trig.r_sign(state.across),
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

expect Arc.no_frames.to_f64() == 1000000000.0
expect Arc.straighten_margin == 0.05
expect Arc.min_forward_progress == 25.0
expect Arc.turn_danger_steps.to_f64() == 2000.0
