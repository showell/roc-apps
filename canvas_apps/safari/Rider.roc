## The rider's decisions and one step of the ride: how far to lean and how
## hard to accelerate, then the move, the crossing onto the next segment, the
## stop at the route's end, and where the rider looks.
import Acceleration
import Across
import Along
import Angle
import Bike
import Fraction
import Gaze
import Geom
import LeanSearch
import RiderState
import Scenery
import Speed
import Throttle
import VehicleLimits
import World

Rider :: [].{
	Decision : { lean_step : Angle.Lean, acceleration : Acceleration }

	## The end of a segment that continues, and the segment it continues onto.
	Seam : { segment : World.Segment, next : World.SegmentIndex }

	## A rider this slow near the route's end stops there.
	stopping_speed : Speed
	stopping_speed = Speed.metres_a_step(0.1)

	## The lean toward the best line, and the throttle for the bike once
	## it leans so.
	decide : RiderState, World.Segment -> Rider.Decision
	decide = |state, seg| {
		lean_step = LeanSearch.best_lean(state).minus(state.lean)
		{
			lean_step,
			acceleration: Throttle.acceleration(
				Bike.with_lean(state, state.lean.plus(lean_step)),
				seg,
			),
		}
	}

	rider_on_next_segment : RiderState, Rider.Seam -> RiderState
	rider_on_next_segment = |rs, { segment: seg, next }| {
		on_next = Geom.centred_point_after(
			{ along: rs.along, across: rs.across },
			{
				segment_length: seg.length,
				turn: seg.exit_turn,
				road_width: Scenery.road_width,
			},
		)
		{
			..rs,
			segment_index: next,
			along: on_next.along,
			across: on_next.across,
			yaw: rs.yaw.minus(seg.exit_turn),
		}
	}

	stop_at_route_end : RiderState, World.Segment -> RiderState
	stop_at_route_end = |moved, seg| {
		end = Along.at(seg.length)
		in_zone = end.distance_from(moved.along) < VehicleLimits.bend_approach
		if moved.along >= end or (in_zone and moved.speed < stopping_speed) {
			stopped_at(moved, end)
		} else {
			moved
		}
	}

	stopped_at : RiderState, Along -> RiderState
	stopped_at = |s, at| { ..s, along: at, speed: Speed.at_rest }

	cross_if_on_road : RiderState, Rider.Seam -> RiderState
	cross_if_on_road = |moved, seam| {
		on_next = rider_on_next_segment(moved, seam)
		if on_next.across.distance_from_middle() < Scenery.road_half_width {
			on_next
		} else {
			moved
		}
	}

	rider_state_at_next_step : RiderState, List(World.Segment) -> RiderState
	rider_state_at_next_step = |state, route_segments| {
		seg = state.segment_index.segment_in(route_segments)
		moved = Bike.bike_motion_at_next_step(state, decide(state, seg))
		resolved =
			match seg.ending {
				Continues({ next }) => cross_if_on_road(moved, { segment: seg, next })
				Terminates => stop_at_route_end(moved, seg)
			}
		Gaze.next_rider_gaze(resolved, route_segments)
	}

	is_finished : RiderState, List(World.Segment) -> Bool
	is_finished = |s, route_segments| {
		seg = s.segment_index.segment_in(route_segments)
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

first_seam : Rider.Seam
first_seam = { segment: first_segment, next: World.SegmentIndex.number(1) }

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
	most_accel = VehicleLimits.cruise_acceleration.to_metres_a_step_each_step() + 0.000001
	upright.lean_step.abs() <= LeanSearch.max_lean_change
		and leaning.lean_step.abs() <= LeanSearch.max_lean_change
		and upright.acceleration.to_metres_a_step_each_step() <= most_accel
}

# The throttle is decided for the bike as it will lean.
expect {
	decision = Rider.decide(rider_at(0.0, 0.0), first_segment)
	same = Throttle.acceleration(
		Bike.with_lean(rider_at(0.0, 0.0), Angle.upright.plus(decision.lean_step)),
		first_segment,
	)
	chosen = decision.acceleration.to_metres_a_step_each_step()
	chosen.to_bits() == same.to_metres_a_step_each_step().to_bits()
}

at_seam : RiderState
at_seam = {
	..RiderState.initial,
	look_depth: Fraction.of(0.4),
	along: Along.metres(499.0),
	across: Across.metres(0.5),
	yaw: Angle.Turn.radians(0.1),
	speed: Speed.metres_a_step(1.25),
	lean: Angle.Lean.radians(0.05),
	heading: Angle.Bearing.radians(0.7),
}

crossed : RiderState
crossed = Rider.rider_on_next_segment(at_seam, first_seam)

expect crossed.speed.to_metres_a_step() == 1.25
expect crossed.lean.to_radians() == 0.05
expect crossed.look_depth.to_f64() == 0.4
expect crossed.heading.to_radians() - 0.7 == 0.0
expect crossed.yaw.to_radians() - (0.1 - first_segment.exit_turn.to_radians()) == 0.0

expect crossed.segment_index.to_i64() == 1
expect first_segment.ending == Continues({ next: World.SegmentIndex.number(1) })

expect {
	far = Rider.rider_on_next_segment(rider_at(100.0, 0.0), first_seam)
	far.across.distance_from_middle() >= Scenery.road_half_width
}

expect Rider.cross_if_on_road(rider_at(100.0, 0.0), first_seam).segment_index.to_i64() == 0
expect Rider.cross_if_on_road(rider_at(499.0, 0.0), first_seam).segment_index.to_i64() == 1

last_seg : World.Segment
last_seg = World.route_segment(18)

clamped_at_finish : F64, F64 -> RiderState
clamped_at_finish = |along, speed|
	Rider.stop_at_route_end(
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
one_step_on = Rider.rider_state_at_next_step(RiderState.initial, first_segments)

expect one_step_on.along > Along.start
expect one_step_on.speed > Speed.at_rest
expect one_step_on.segment_index == World.SegmentIndex.first
expect one_step_on.across.distance_from_middle() < Scenery.road_half_width
expect one_step_on.speed <= VehicleLimits.top_speed

# These test LeanSearch's search. They sit here because LeanSearch doesn't import
# RiderState, and Rider does.

## The lean the search picks for a rider at the start of the segment, in radians.
searched_lean : F64, F64 -> F64
searched_lean = |across, lean_radians|
	LeanSearch.best_lean({
		..RiderState.initial,
		across: Across.metres(across),
		lean: Angle.Lean.radians(lean_radians),
	}).to_radians()

max_correction : F64
max_correction = LeanSearch.max_lean_change.to_radians()

centred : F64
centred = searched_lean(0.0, 0.0)

offset : F64
offset = searched_lean(1.0, 0.0)

held : F64
held = searched_lean(0.0, 0.5)

expect offset.abs() <= max_correction
expect (held - 0.5).abs() <= max_correction
expect centred.abs() <= max_correction
expect held > centred
