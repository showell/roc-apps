# Arc -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Bike
import DeviceMath
import Pose
import Trig
import World

Arc :: [].{
	Shoulder : [ShoulderLeft, ShoulderNone, ShoulderRight]
	ArcOutcome : { shoulder : Arc.Shoulder, forward : F64, crossed : Bool, end_across : F64, frames : F64 }

	no_frames : F64
	no_frames = 1000000000.0

	straighten_margin : F64
	straighten_margin = 0.05

	turn_danger_steps : I64
	turn_danger_steps = 2000

	min_forward_progress : F64
	min_forward_progress = 25.0

	sim_loop : Pose.RiderState, F64, F64, F64, F64, Bool, I64, Pose.RiderState -> Arc.ArcOutcome
	sim_loop = |start, left_bound, right_bound, start_side, start_along, crossed, i, phys| (if (i >= turn_danger_steps) { { shoulder: ShoulderNone, forward: (phys.along - start_along), crossed: crossed, end_across: phys.across, frames: no_frames } } else { sim_step(start, left_bound, right_bound, start_side, start_along, crossed, i, Bike.simulate_rider_step(phys, 0.0, 0.0)) })

	sim_step : Pose.RiderState, F64, F64, F64, F64, Bool, I64, Pose.RiderState -> Arc.ArcOutcome
	sim_step = |start, left_bound, right_bound, start_side, start_along, crossed0, i, phys| ({
		across = phys.across
		forward = (phys.along - start_along)
		crossed = (if ((across * start_side) < 0.0) { True } else { crossed0 })
		(if (across < left_bound) { { shoulder: ShoulderLeft, forward: DeviceMath.real_min(forward, min_forward_progress), crossed: crossed, end_across: across, frames: I64.to_f64(i) } } else { (if (across > right_bound) { { shoulder: ShoulderRight, forward: DeviceMath.real_min(forward, min_forward_progress), crossed: crossed, end_across: across, frames: I64.to_f64(i) } } else { (if (forward < 0.0) { { shoulder: ShoulderNone, forward: forward, crossed: crossed, end_across: across, frames: no_frames } } else { (if (forward >= min_forward_progress) { { shoulder: ShoulderNone, forward: min_forward_progress, crossed: crossed, end_across: across, frames: no_frames } } else { sim_loop(start, left_bound, right_bound, start_side, start_along, crossed, (i + 1), phys) }) }) }) })
	})

	project_arc : Pose.RiderState, World.Segment -> Arc.ArcOutcome
	project_arc = |state, seg| ({
		inset_hw = ((seg.width / 2.0) - straighten_margin)
		right_bound = DeviceMath.real_max(inset_hw, state.across)
		left_bound = DeviceMath.real_min((0.0 - inset_hw), state.across)
		sim_loop(state, left_bound, right_bound, Trig.r_sign(state.across), state.along, False, 0, state)
	})
}
