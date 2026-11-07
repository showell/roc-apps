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
				Bends(_) =>
					cross_if_on_road(moved, { segment: seg, next: state.segment_index.next() })
				RouteEnds => { ..moved, motorcycle: stop_at_route_end(moved.motorcycle, seg) }
			}
		Gaze.next_rider_gaze(resolved, resolved.segment_index.segment_in(route_segments))
	}

	is_finished : RiderState, List(World.Segment) -> Bool
	is_finished = |s, route_segments| {
		seg = s.segment_index.segment_in(route_segments)
		match seg.ending {
			Bends(_) => False
			RouteEnds => s.motorcycle.along >= Along.at(seg.length)
		}
	}
}

## The end of a segment that continues, and the segment it continues onto.
Seam : { segment : World.Segment, next : World.SegmentIndex }

## A rider this slow near the route's end stops there.
stopping_speed : Speed
stopping_speed = Speed.metres_a_step(0.1)

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
	bend = World.bend_out_of(seg)
	on_next = Geom.point_in_segment_after({ along: m.along, across: m.across }, bend)
	{
		..rs,
		segment_index: next,
		motorcycle: {
			..m,
			along: on_next.along,
			across: on_next.across,
			yaw: m.yaw.minus(bend.turn),
		},
	}
}

stop_at_route_end : Motorcycle, World.Segment -> Motorcycle
stop_at_route_end = |moved, seg| {
	end = Along.at(seg.length)
	in_zone = end.distance_from(moved.along) < VehicleLimits.bend_approach
	if moved.along >= end or (in_zone and moved.speed < stopping_speed) {
		stopped_at(moved, end)
	} else {
		moved
	}
}

## This motorcycle stopped dead at `at`. The book shows it as the plainest
## record update, so it stands alone.
stopped_at : Motorcycle, Along -> Motorcycle
stopped_at = |m, at| { ..m, along: at, speed: Speed.at_rest }

cross_if_on_road : RiderState, Seam -> RiderState
cross_if_on_road = |moved, seam| {
	on_next = rider_on_next_segment(moved, seam)
	if on_next.motorcycle.across.distance_from_middle() < Geom.road_half_width {
		on_next
	} else {
		moved
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
expect {
	exit_turn = World.bend_out_of(first_segment).turn
	crossed.motorcycle.yaw.to_radians() - (0.1 - exit_turn.to_radians()) == 0.0
}

expect crossed.segment_index.to_i64() == 1

expect {
	far = rider_on_next_segment(rider_at(100.0, 0.0), first_seam)
	far.motorcycle.across.distance_from_middle() >= Geom.road_half_width
}

expect cross_if_on_road(rider_at(100.0, 0.0), first_seam).segment_index.to_i64() == 0
expect cross_if_on_road(rider_at(499.0, 0.0), first_seam).segment_index.to_i64() == 1

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
expect clamped_at_finish(290.0, 0.05).along.to_metres() == 300.0
expect clamped_at_finish(290.0, 0.05).speed.to_metres_a_step() == 0.0
expect clamped_at_finish(290.0, 0.5).along.to_metres() == 290.0
expect clamped_at_finish(290.0, 0.5).speed.to_metres_a_step() == 0.5
expect clamped_at_finish(100.0, 0.05).along.to_metres() == 100.0
expect clamped_at_finish(100.0, 0.05).speed.to_metres_a_step() == 0.05

## A rider stopped at `along` metres on the last segment.
stopped_on_last : F64 -> RiderState
stopped_on_last = |along| {
	..RiderState.initial,
	motorcycle: { ..motorcycle_at(along, 0.0), speed: Speed.at_rest },
}

expect Rider.is_finished(stopped_on_last(300.0), [last_seg])
expect !Rider.is_finished(stopped_on_last(299.0), [last_seg])
expect last_seg.ending == RouteEnds
expect !Rider.is_finished(rider_at(499.0, 0.0), first_segments)

one_step_on : RiderState
one_step_on = Rider.rider_state_at_next_step(RiderState.initial, first_segments)

expect one_step_on.motorcycle.along > Along.start
expect one_step_on.motorcycle.speed > Speed.at_rest
expect one_step_on.segment_index == World.SegmentIndex.first
expect one_step_on.motorcycle.across.distance_from_middle() < Geom.road_half_width
expect one_step_on.motorcycle.speed <= VehicleLimits.top_speed
