## The rider's decisions and one step of the ride: how far to lean and how
## hard to accelerate, then the move, the crossing onto the next segment, the
## stop at the route's end, and where the rider looks.
import Acceleration
import Across
import Along
import Angle
import Fraction
import Gaze
import Geom
import LeanSearch
import Motorcycle
import RiderState
import Speed
import Throttle
import VehicleLimits
import World

Rider :: [].{
	Decision : { lean_step : Angle.LeanChange, acceleration : Acceleration }

	rider_state_at_next_step : RiderState, List(World.Segment) -> RiderState
	rider_state_at_next_step = |state, route_segments| {
		seg = state.segment_index.segment_in(route_segments)
		moved = {
			..state,
			motorcycle: state.motorcycle.motorcycle_at_next_step(decide(state.motorcycle, seg)),
		}
		resolved =
			match seg.ending {
				Continues({ next }) => {
					seam = { segment: seg, next }
					cross_if_on_road(moved, { seam, route_segments })
				}
				Terminates => {
					stopped = { ..moved, motorcycle: stop_at_route_end(moved.motorcycle, seg) }
					{ rider: stopped, segment: seg }
				}
			}
		Gaze.next_rider_gaze(resolved.rider, resolved.segment)
	}

	is_finished : RiderState, List(World.Segment) -> Bool
	is_finished = |s, route_segments| {
		seg = s.segment_index.segment_in(route_segments)
		match seg.ending {
			Continues(_) => False
			Terminates => s.motorcycle.along >= Along.at(seg.length)
		}
	}
}

## The end of a segment that continues, and the segment it continues onto.
Seam : { segment : World.Segment, next : World.SegmentIndex }

## A rider, and the segment of the route they are on.
RiderOnSegment : { rider : RiderState, segment : World.Segment }

## The lean toward the best line, and the throttle for the motorcycle once it
## leans so.
decide : Motorcycle, World.Segment -> Rider.Decision
decide = |motorcycle, seg| {
	lean_step = LeanSearch.best_lean(motorcycle).change_from(motorcycle.lean)
	{
		lean_step,
		acceleration: Throttle.acceleration(
			motorcycle.with_lean(motorcycle.lean.plus(lean_step)),
			seg,
		),
	}
}

rider_on_next_segment : RiderState, Seam -> RiderState
rider_on_next_segment = |rs, { segment: seg, next }| {
	m = rs.motorcycle
	on_next = Geom.point_in_segment_after(
		{ along: m.along, across: m.across },
		World.bend_out_of(seg),
	)
	{
		..rs,
		segment_index: next,
		motorcycle: {
			..m,
			along: on_next.along,
			across: on_next.across,
			yaw: m.yaw.minus(seg.exit_turn),
		},
	}
}

## The motorcycle held at the route's end once it reaches it. The throttle
## brakes it to rest there, and this catches the last step's overrun.
stop_at_route_end : Motorcycle, World.Segment -> Motorcycle
stop_at_route_end = |moved, seg| {
	end = Along.at(seg.length)
	if moved.along >= end {
		stopped_at(moved, end)
	} else {
		moved
	}
}

## This motorcycle stopped dead at `at`. The book shows it as the plainest
## record update, so it stands alone.
stopped_at : Motorcycle, Along -> Motorcycle
stopped_at = |m, at| { ..m, along: at, speed: Speed.at_rest }

## The rider on the next segment if that puts them on its road, else where
## they were, with the segment they end on.
cross_if_on_road : RiderState,
{
	seam : Seam,
	route_segments : List(World.Segment),
} -> RiderOnSegment
cross_if_on_road = |moved, { seam, route_segments }| {
	on_next = rider_on_next_segment(moved, seam)
	if on_next.motorcycle.across.distance_from_middle() < Geom.road_half_width {
		{ rider: on_next, segment: seam.next.segment_in(route_segments) }
	} else {
		{ rider: moved, segment: seam.segment }
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

first_seam : Seam
first_seam = { segment: first_segment, next: World.SegmentIndex.number(1) }

## A motorcycle on the centre line of the first segment, going the base speed.
motorcycle_at : F64, F64 -> Motorcycle
motorcycle_at = |along, lean_radians| {
	..Motorcycle.initial,
	along: Along.metres(along),
	lean: Angle.Lean.radians(lean_radians),
}

## A rider on that motorcycle.
rider_at : F64, F64 -> RiderState
rider_at = |along, lean_radians| {
	..RiderState.initial,
	motorcycle: motorcycle_at(along, lean_radians),
}

expect {
	upright = decide(motorcycle_at(0.0, 0.0), first_segment)
	leaning = decide(motorcycle_at(0.0, 0.5), first_segment)
	most_accel = VehicleLimits.cruise_acceleration.to_metres_a_step_each_step() + 0.000001
	upright.lean_step.abs() <= LeanSearch.max_lean_change
		and leaning.lean_step.abs() <= LeanSearch.max_lean_change
		and upright.acceleration.to_metres_a_step_each_step() <= most_accel
}

# The throttle is decided for the motorcycle as it will lean.
expect {
	decision = decide(motorcycle_at(0.0, 0.0), first_segment)
	same = Throttle.acceleration(
		motorcycle_at(0.0, 0.0).with_lean(Angle.upright.plus(decision.lean_step)),
		first_segment,
	)
	chosen = decision.acceleration.to_metres_a_step_each_step()
	chosen.to_bits() == same.to_metres_a_step_each_step().to_bits()
}

at_seam : RiderState
at_seam = {
	segment_index: World.SegmentIndex.first,
	motorcycle: {
		along: Along.metres(499.0),
		across: Across.metres(0.5),
		yaw: Angle.Turn.radians(0.1),
		speed: Speed.metres_a_step(1.25),
		lean: Angle.Lean.radians(0.05),
		heading: Angle.Bearing.radians(0.7),
	},
	eyes: { ..RiderState.initial.eyes, look_depth: Fraction.of(0.4) },
}

crossed : RiderState
crossed = rider_on_next_segment(at_seam, first_seam)

expect crossed.motorcycle.speed.to_metres_a_step() == 1.25
expect crossed.motorcycle.lean.to_radians() == 0.05
expect crossed.eyes.look_depth.to_f64() == 0.4
expect crossed.motorcycle.heading.to_radians() - 0.7 == 0.0
expect crossed.motorcycle.yaw.to_radians() - (0.1 - first_segment.exit_turn.to_radians()) == 0.0

expect crossed.segment_index.to_i64() == 1
expect first_segment.ending == Continues({ next: World.SegmentIndex.number(1) })

expect {
	far = rider_on_next_segment(rider_at(100.0, 0.0), first_seam)
	far.motorcycle.across.distance_from_middle() >= Geom.road_half_width
}

## Where `cross_if_on_road` leaves a rider at `along` on the first segment.
crossed_from : F64 -> RiderOnSegment
crossed_from = |along|
	cross_if_on_road(rider_at(along, 0.0), { seam: first_seam, route_segments: first_segments })

# A rider short of the seam stays on the first segment, and one at it crosses,
# each with the segment they end on.
expect crossed_from(100.0).rider.segment_index.to_i64() == 0
expect crossed_from(100.0).segment == first_segment
expect crossed_from(499.0).rider.segment_index.to_i64() == 1
expect crossed_from(499.0).segment == World.route_segment(1)

last_seg : World.Segment
last_seg = World.route_segment(18)

clamped_at_finish : F64, F64 -> Motorcycle
clamped_at_finish = |along, speed|
	stop_at_route_end(
		{
			..Motorcycle.initial,
			along: Along.metres(along),
			speed: Speed.metres_a_step(speed),
		},
		last_seg,
	)

expect clamped_at_finish(300.0, 0.5).along.to_metres() == 300.0
expect clamped_at_finish(300.0, 0.5).speed.to_metres_a_step() == 0.0
expect clamped_at_finish(310.0, 0.5).along.to_metres() == 300.0
expect clamped_at_finish(310.0, 0.5).speed.to_metres_a_step() == 0.0

# Short of the end, however slow, the motorcycle is left where it is.
expect clamped_at_finish(299.99, 0.05).along.to_metres() == 299.99
expect clamped_at_finish(299.99, 0.05).speed.to_metres_a_step() == 0.05
expect clamped_at_finish(290.0, 0.5).along.to_metres() == 290.0
expect clamped_at_finish(290.0, 0.5).speed.to_metres_a_step() == 0.5

## A rider stopped at `along` metres on the last segment.
stopped_on_last : F64 -> RiderState
stopped_on_last = |along| {
	..RiderState.initial,
	motorcycle: { ..motorcycle_at(along, 0.0), speed: Speed.at_rest },
}

expect Rider.is_finished(stopped_on_last(300.0), [last_seg])
expect !Rider.is_finished(stopped_on_last(299.0), [last_seg])
expect last_seg.ending == Terminates
expect !Rider.is_finished(rider_at(499.0, 0.0), first_segments)

one_step_on : RiderState
one_step_on = Rider.rider_state_at_next_step(RiderState.initial, first_segments)

expect one_step_on.motorcycle.along > Along.start
expect one_step_on.motorcycle.speed > Speed.at_rest
expect one_step_on.segment_index == World.SegmentIndex.first
expect one_step_on.motorcycle.across.distance_from_middle() < Geom.road_half_width
expect one_step_on.motorcycle.speed <= VehicleLimits.top_speed
