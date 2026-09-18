# Rider -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Bike
import DeviceMath
import Gaze
import LeanSearch
import Pose
import Throttle
import Trig
import VehicleLimits
import World

Rider :: [].{
	Decision : { tilt_step : F64, accel : F64 }

	decide : Pose.RiderState, World.Segment -> Rider.Decision
	decide = |state, seg| ({
		tilt_step = (LeanSearch.best_tilt_correction(state, seg) - state.tilt)
		{ tilt_step: tilt_step, accel: Throttle.get_forward_accel_decel(Pose.with_tilt(state, (state.tilt + tilt_step)), seg) }
	})

	rider_state_for_next_segment : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	rider_state_for_next_segment = |rs, segs| ({
		seg = (List.get(segs, I64.to_u64_wrap(rs.segment)) ?? crash("list-at out of range"))
		hw = (seg.width / 2.0)
		theta = seg.exit_angle
		sgn = (if seg.exit_right { 1.0 } else { (0.0 - 1.0) })
		c = Trig.r_cos(theta)
		s = Trig.r_sin(theta)
		da = (rs.along - (seg.length + (hw * s)))
		dx = (rs.across - ((sgn * hw) * (1.0 - c)))
		{ segment: seg.exit_to, along: ((c * da) + ((sgn * s) * dx)), across: ((((0.0 - sgn) * s) * da) + (c * dx)), yaw: (rs.yaw - (sgn * theta)), v: rs.v, tilt: rs.tilt, heading: rs.heading, gaze_yaw: 0.0, focus: rs.focus }
	})

	finish_clamp : Pose.RiderState, World.Segment -> Pose.RiderState
	finish_clamp = |moved, seg| ({
		in_zone = ((seg.length - moved.along) < VehicleLimits.approach_intersection_dist)
		(if (moved.along >= seg.length) { stopped_at(moved, seg.length) } else { (if in_zone { (if (moved.v < 0.1) { stopped_at(moved, seg.length) } else { moved }) } else { moved }) })
	})

	stopped_at : Pose.RiderState, F64 -> Pose.RiderState
	stopped_at = |s, at| { segment: s.segment, along: at, across: s.across, yaw: s.yaw, v: 0.0, tilt: s.tilt, heading: s.heading, gaze_yaw: s.gaze_yaw, focus: s.focus }

	resolve_cross : Pose.RiderState, World.Segment, List(World.Segment) -> Pose.RiderState
	resolve_cross = |moved, seg, segs| ({
		on_next = rider_state_for_next_segment(moved, segs)
		(if (DeviceMath.real_abs(on_next.across) < ((List.get(segs, I64.to_u64_wrap(seg.exit_to)) ?? crash("list-at out of range")).width / 2.0)) { on_next } else { moved })
	})

	get_next_rider_state : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	get_next_rider_state = |state, segs| ({
		seg = (List.get(segs, I64.to_u64_wrap(state.segment)) ?? crash("list-at out of range"))
		dec = decide(state, seg)
		moved = Bike.simulate_rider_step(state, dec.tilt_step, dec.accel)
		resolved = (if seg.terminates { finish_clamp(moved, seg) } else { resolve_cross(moved, seg, segs) })
		Gaze.next_rider_gaze(resolved, segs)
	})

	is_finished : Pose.RiderState, List(World.Segment) -> Bool
	is_finished = |s, segs| ({
		seg = (List.get(segs, I64.to_u64_wrap(s.segment)) ?? crash("list-at out of range"))
		(if seg.terminates { (s.along >= seg.length) } else { False })
	})
}
