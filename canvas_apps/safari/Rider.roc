## The rider's decisions and one step of the ride: how far to lean and how
## hard to accelerate, then the move, the crossing onto the next segment, the
## stop at the route's end, and where the rider looks.
import Acceleration
import Across
import Along
import Angle
import Bike
import lib.DeviceMath
import Gaze
import Geom
import LeanSearch
import RiderState
import Scenery
import Speed
import Throttle
import lib.Trig
import VehicleLimits
import World

Rider :: [].{
	Decision : { lean_step : Angle.Lean, accel : Acceleration }

	## A rider this slow near the route's end stops there.
	stopping_speed : Speed
	stopping_speed = Speed.metres_a_step(0.1)

	## The lean toward the best line, and the throttle for the bike once
	## it leans so.
	decide : RiderState, World.Segment -> Rider.Decision
	decide = |state, seg| {
		lean_step = LeanSearch.best_tilt_correction(state).minus(state.lean)
		{
			lean_step,
			accel: Throttle.get_forward_accel_decel(
				Bike.with_lean(state, state.lean.plus(lean_step)),
				seg,
			),
		}
	}

	rider_state_for_next_segment : RiderState, List(World.Segment) -> RiderState
	rider_state_for_next_segment = |rs, segs| {
		seg = rs.segment.segment_in(segs)
		next =
			match seg.ending {
				Continues({ next: index }) => index
				Terminates => crash "Rider.rider_state_for_next_segment: past the route's end"
			}
		on_next = Geom.centred_point_after(
			{ along: rs.along, across: rs.across },
			{
				segment_length: seg.length,
				turn: seg.exit_turn,
				lane_width: Scenery.lane_width,
			},
		)
		{
			..rs,
			segment: next,
			along: on_next.along,
			across: on_next.across,
			yaw: rs.yaw.minus(seg.exit_turn),
			gaze_yaw: Angle.straight_ahead,
		}
	}

	finish_clamp : RiderState, World.Segment -> RiderState
	finish_clamp = |moved, seg| {
		end = Along.at(seg.length)
		in_zone = end.distance_from(moved.along) < VehicleLimits.bend_approach
		if moved.along >= end {
			stopped_at(moved, end)
		} else if in_zone {
			if moved.speed < stopping_speed {
				stopped_at(moved, end)
			} else {
				moved
			}
		} else {
			moved
		}
	}

	stopped_at : RiderState, Along -> RiderState
	stopped_at = |s, at| { ..s, along: at, speed: Speed.at_rest }

	resolve_cross : RiderState, List(World.Segment) -> RiderState
	resolve_cross = |moved, segs| {
		on_next = rider_state_for_next_segment(moved, segs)
		if on_next.across.distance_from_middle() < Scenery.lane_half_width {
			on_next
		} else {
			moved
		}
	}

	advance : RiderState, List(World.Segment) -> RiderState
	advance = |state, segs| {
		seg = state.segment.segment_in(segs)
		dec = decide(state, seg)
		moved = Bike.simulate_rider_step(state, { lean_step: dec.lean_step, accel: dec.accel })
		resolved =
			match seg.ending {
				Continues(_) => resolve_cross(moved, segs)
				Terminates => finish_clamp(moved, seg)
			}
		Gaze.next_rider_gaze(resolved, segs)
	}

	is_finished : RiderState, List(World.Segment) -> Bool
	is_finished = |s, segs| {
		seg = s.segment.segment_in(segs)
		match seg.ending {
			Continues(_) => False
			Terminates => s.along >= Along.at(seg.length)
		}
	}
}

first_segments : List(World.Segment)
first_segments = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

first_segment : World.Segment
first_segment = World.route_segment(0)

## A rider on the centre line of the first segment, going the base speed.
rider_at : F64, F64 -> RiderState
rider_at = |along, lean_radians| {
	..RiderState.initial,
	along: Along.metres(along),
	lean: Angle.Lean.radians(lean_radians),
}

expect {
	upright = Rider.decide(rider_at(0.0, 0.0), first_segment)
	leaning = Rider.decide(rider_at(0.0, 0.5), first_segment)
	most_accel = VehicleLimits.a_accel.to_metres_a_step_each_step() + 0.000001
	upright.lean_step.abs() <= LeanSearch.max_tilt_correction
		and leaning.lean_step.abs() <= LeanSearch.max_tilt_correction
		and upright.accel.to_metres_a_step_each_step() <= most_accel
}

# The throttle is decided for the bike as it will lean.
expect {
	decision = Rider.decide(rider_at(0.0, 0.0), first_segment)
	same = Throttle.get_forward_accel_decel(
		Bike.with_lean(rider_at(0.0, 0.0), Angle.upright.plus(decision.lean_step)),
		first_segment,
	)
	chosen = decision.accel.to_metres_a_step_each_step()
	chosen.to_bits() == same.to_metres_a_step_each_step().to_bits()
}

## Rider doesn't import Fraction, so this focus comes from Gaze.
focused_rider : RiderState
focused_rider = {
	..RiderState.initial,
	focus: Gaze.next_focus(RiderState.initial, Gaze.gaze_release_angle.times(0.4)),
}

at_seam : RiderState
at_seam = {
	..focused_rider,
	along: Along.metres(499.0),
	across: Across.metres(0.5),
	yaw: Angle.Turn.radians(0.1),
	speed: Speed.metres_a_step(1.25),
	lean: Angle.Lean.radians(0.05),
	heading: Angle.Bearing.radians(0.7),
	gaze_yaw: Angle.Turn.radians(0.3),
}

crossed : RiderState
crossed = Rider.rider_state_for_next_segment(at_seam, first_segments)

expect crossed.speed.to_metres_a_step() == 1.25
expect crossed.lean.to_radians() == 0.05
expect crossed.focus.to_f64() == 0.4
expect crossed.gaze_yaw.to_radians() == 0.0
expect crossed.heading.to_radians() - 0.7 == 0.0
expect crossed.yaw.to_radians() - (0.1 - first_segment.exit_turn.to_radians()) == 0.0

expect crossed.segment.to_i64() == 1
expect first_segment.ending == Continues({ next: World.SegmentIndex.number(1) })

expect {
	far = Rider.rider_state_for_next_segment(rider_at(100.0, 0.0), first_segments)
	far.across.distance_from_middle() >= Scenery.lane_half_width
}

expect Rider.resolve_cross(rider_at(100.0, 0.0), first_segments).segment.to_i64() == 0
expect Rider.resolve_cross(rider_at(499.0, 0.0), first_segments).segment.to_i64() == 1

last_seg : World.Segment
last_seg = World.route_segment(18)

clamped_at_finish : F64, F64 -> RiderState
clamped_at_finish = |along, speed|
	Rider.finish_clamp(
		{
			..RiderState.initial,
			along: Along.metres(along),
			speed: Speed.metres_a_step(speed),
		},
		last_seg,
	)

expect clamped_at_finish(300.0, 0.5).along.to_metres() == 300.0
expect clamped_at_finish(300.0, 0.5).speed.to_metres_a_step() == 0.0
expect clamped_at_finish(310.0, 0.5).along.to_metres() == 300.0
expect clamped_at_finish(310.0, 0.5).speed.to_metres_a_step() == 0.0
expect clamped_at_finish(290.0, 0.05).along.to_metres() == 300.0
expect clamped_at_finish(290.0, 0.05).speed.to_metres_a_step() == 0.0
expect clamped_at_finish(290.0, 0.5).along.to_metres() == 290.0
expect clamped_at_finish(290.0, 0.5).speed.to_metres_a_step() == 0.5
expect clamped_at_finish(100.0, 0.05).along.to_metres() == 100.0
expect clamped_at_finish(100.0, 0.05).speed.to_metres_a_step() == 0.05

expect Rider.is_finished({ ..rider_at(300.0, 0.0), speed: Speed.at_rest }, [last_seg])
expect !Rider.is_finished({ ..rider_at(299.0, 0.0), speed: Speed.at_rest }, [last_seg])
expect last_seg.ending == Terminates
expect !Rider.is_finished(rider_at(499.0, 0.0), first_segments)

one_step_on : RiderState
one_step_on = Rider.advance(RiderState.initial, first_segments)

expect one_step_on.along > Along.start
expect one_step_on.speed > Speed.at_rest
expect one_step_on.segment == World.SegmentIndex.first
expect one_step_on.across.distance_from_middle() < Scenery.lane_half_width
expect one_step_on.speed <= VehicleLimits.v_max

# These are LeanSearch's search. They sit here because LeanSearch imports
# neither Pose nor Speed, and Rider sees both.

## The lean the search picks for a rider at the start of the segment, in radians.
searched_lean : F64, F64 -> F64
searched_lean = |across, lean_radians|
	LeanSearch.best_tilt_correction({
		..RiderState.initial,
		across: Across.metres(across),
		lean: Angle.Lean.radians(lean_radians),
	}).to_radians()

max_correction : F64
max_correction = LeanSearch.max_tilt_correction.to_radians()

centred : F64
centred = searched_lean(0.0, 0.0)

offset : F64
offset = searched_lean(1.0, 0.0)

held : F64
held = searched_lean(0.0, 0.5)

expect centred >= (0.0 - max_correction)
expect centred <= max_correction
expect offset >= (0.0 - max_correction)
expect offset <= max_correction
expect held >= (0.5 - max_correction)
expect held <= (0.5 + max_correction)
expect DeviceMath.real_abs((held - 0.5)) <= max_correction
expect DeviceMath.real_abs(centred) <= max_correction
expect held > centred

# The search gives the same lean every time.
expect searched_lean(1.0, 0.0) - offset == 0.0
expect searched_lean(0.0, 0.5) - held == 0.0
