## The rider's decisions and one step of the ride: how far to lean and how
## hard to accelerate, then the move, the crossing onto the next segment, the
## stop at the route's end, and where the rider looks.
import Angle
import Bike
import lib.DeviceMath
import Gaze
import LeanSearch
import Pose
import Scenery
import Speed
import Throttle
import lib.Trig
import VehicleLimits
import World

Rider :: [].{
	Decision : { tilt_step : Angle.Lean, accel : F64 }

	## A rider this slow near the route's end stops there.
	stopping_speed : Speed
	stopping_speed = Speed.metres_a_step(0.1)

	## The lean toward the best line, and the throttle for the bike once
	## it leans so.
	decide : Pose.RiderState, World.Segment -> Rider.Decision
	decide = |state, seg| {
		tilt_step = LeanSearch.best_tilt_correction(state).minus(state.tilt)
		{
			tilt_step,
			accel: Throttle.get_forward_accel_decel(
				Pose.with_tilt(state, state.tilt.plus(tilt_step)),
				seg,
			),
		}
	}

	rider_state_for_next_segment : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	rider_state_for_next_segment = |rs, segs| (
		{
			seg = rs.segment.segment_in(segs)
			hw = (Scenery.lane_width / 2.0)
			next =
				match seg.ending {
					Continues({ next: index }) => index
					Terminates => crash "Rider.rider_state_for_next_segment: past the route's end"
				}
			theta = seg.exit_turn.to_radians()
			c = Trig.r_cos(theta)
			s = Trig.r_sin(theta)
			da = (rs.along - (seg.length + (hw * DeviceMath.real_abs(s))))
			corner_shift = (hw * (1.0 - c))
			dx =
				if seg.exit_turn.is_right() {
					rs.across - corner_shift
				} else {
					rs.across + corner_shift
				}
			{
				..rs,
				segment: next,
				along: ((c * da) + (s * dx)),
				across: (((0.0 - s) * da) + (c * dx)),
				yaw: rs.yaw.minus(seg.exit_turn),
				gaze_yaw: Angle.straight_ahead,
			}
		}
	)

	finish_clamp : Pose.RiderState, World.Segment -> Pose.RiderState
	finish_clamp = |moved, seg| (
		{
			in_zone = ((seg.length - moved.along) < VehicleLimits.approach_intersection_dist)
			(
				if moved.along >= seg.length {
					stopped_at(moved, seg.length)
				} else {
					(
						if in_zone {
							(
								if moved.speed < stopping_speed {
									stopped_at(moved, seg.length)
								} else {
									moved
								}
							)
						} else {
							moved
						}
					)
				}
			)
		}
	)

	stopped_at : Pose.RiderState, F64 -> Pose.RiderState
	stopped_at = |s, at| {
		..s,
		along: at,
		speed: Speed.at_rest,
	}

	resolve_cross : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	resolve_cross = |moved, segs| (
		{
			on_next = rider_state_for_next_segment(moved, segs)
			(
				if DeviceMath.real_abs(on_next.across) < (Scenery.lane_width / 2.0) {
					on_next
				} else {
					moved
				}
			)
		}
	)

	get_next_rider_state : Pose.RiderState, List(World.Segment) -> Pose.RiderState
	get_next_rider_state = |state, segs| (
		{
			seg = state.segment.segment_in(segs)
			dec = decide(state, seg)
			moved = Bike.simulate_rider_step(state, { lean_step: dec.tilt_step, accel: dec.accel })
			resolved =
				match seg.ending {
					Continues(_) => resolve_cross(moved, segs)
					Terminates => finish_clamp(moved, seg)
				}
			Gaze.next_rider_gaze(resolved, segs)
		}
	)

	is_finished : Pose.RiderState, List(World.Segment) -> Bool
	is_finished = |s, segs| (
		{
			seg = s.segment.segment_in(segs)
			match seg.ending {
				Continues(_) => False
				Terminates => (s.along >= seg.length)
			}
		}
	)
}
