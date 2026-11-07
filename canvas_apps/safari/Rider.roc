## The rider's decisions and one step of the ride: how far to lean and how
## hard to accelerate, then the move, the crossing onto the next segment, the
## stop at the route's end, and where the rider looks.
import Across
import Along
import Angle
import EncountersAhead
import Gaze
import Geom
import LeanSearch
import Motorcycle
import RiderState
import Route
import Segment
import Speed
import Throttle
import World

Rider :: [].{
	rider_state_at_next_step : RiderState, Route -> RiderState
	rider_state_at_next_step = |state, route| {
		seg = route.segment_at(state.segment_index)
		encounters = EncountersAhead.encounters_ahead(route, state)
		controls = decide(state.motorcycle, { segment: seg, encounters })
		moved = { ..state, motorcycle: state.motorcycle.motorcycle_at_next_step(controls) }
		resolved =
			match seg.ending {
				Bends(_) => cross_if_on_road(moved, route)
				RouteEnds => { ..moved, motorcycle: stop_at_route_end(moved.motorcycle, seg) }
			}
		resolved_seg =
			if resolved.segment_index == state.segment_index {
				seg
			} else {
				route.segment_at(resolved.segment_index)
			}
		{
			..resolved,
			eyes: Gaze.eyes_at_next_step(
				resolved.eyes,
				{ motorcycle: resolved.motorcycle, segment: resolved_seg },
			),
		}
	}

	is_finished : RiderState, Route -> Bool
	is_finished = |s, route| {
		seg = route.segment_at(s.segment_index)
		match seg.ending {
			Bends(_) => False
			RouteEnds => s.motorcycle.along >= Along.at(seg.length)
		}
	}
}

## The lean toward the best line, and the speed the throttle gives the
## motorcycle once it leans so, on `segment` with the animals ahead where
## `encounters` has them. The animals move first and the rider reacts.
decide : Motorcycle, { segment : Segment, encounters : EncountersAhead } -> Motorcycle.Controls
decide = |motorcycle, on_road| {
	lean = LeanSearch.best_lean(motorcycle)
	{ lean, speed: Throttle.next_speed(motorcycle.with_lean(lean), on_road) }
}

## The rider carried over the bend at the end of their segment: placed on the
## next segment, and turned to its axis. Nothing here asks whether that puts
## them on its road; `cross_if_on_road` does.
rider_on_next_segment : RiderState, Route -> RiderState
rider_on_next_segment = |rs, route| {
	m = rs.motorcycle
	bend = route.segment_at(rs.segment_index).bend_out_of()
	on_next = Geom.point_in_segment_after({ along: m.along, across: m.across }, bend)
	{
		..rs,
		segment_index: rs.segment_index.next(),
		motorcycle: {
			..m,
			along: on_next.along,
			across: on_next.across,
			yaw: m.yaw.minus(bend.turn),
		},
	}
}

## The motorcycle held at the route's end once it reaches it. The throttle
## brakes it to rest there, and this catches the last step's overrun.
stop_at_route_end : Motorcycle, Segment -> Motorcycle
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
## they were.
cross_if_on_road : RiderState, Route -> RiderState
cross_if_on_road = |moved, route| {
	on_next = rider_on_next_segment(moved, route)
	if on_next.motorcycle.across.distance_from_middle() < Geom.road_half_width {
		on_next
	} else {
		moved
	}
}

first_segment : Segment
first_segment = World.route.segment_at(Route.SegmentIndex.number(0))

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

# The throttle is decided for the motorcycle as it will lean.
expect {
	on_road = {
		segment: first_segment,
		encounters: EncountersAhead.encounters_ahead(World.route, rider_at(0.0, 0.0)),
	}
	controls = decide(motorcycle_at(0.0, 0.0), on_road)
	same = Throttle.next_speed(motorcycle_at(0.0, 0.0).with_lean(controls.lean), on_road)
	controls.speed.to_metres_a_step().to_bits() == same.to_metres_a_step().to_bits()
}

at_seam : RiderState
at_seam = {
	segment_index: Route.SegmentIndex.first,
	motorcycle: {
		along: Along.metres(499.0),
		across: Across.metres(0.5),
		yaw: Angle.Turn.radians(0.1),
		speed: Speed.metres_a_step(1.25),
		lean: Angle.Lean.radians(0.05),
	},
	eyes: RiderState.initial.eyes,
}

crossed : RiderState
crossed = rider_on_next_segment(at_seam, World.route)

## The motorcycle's bearing in the world: its segment's bearing, turned by its
## yaw.
bearing_in_world : RiderState -> Angle.Bearing
bearing_in_world = |rider| World.route.bearing_of(rider.segment_index).plus(rider.motorcycle.yaw)

# The crossing keeps the motorcycle's bearing in the world: the yaw turns back
# by the bend that turns the next segment's bearing. The two sums round apart,
# by no more than a float's last bits.
expect {
	turned = bearing_in_world(crossed).turn_from(bearing_in_world(at_seam))
	turned.abs() < Angle.Turn.radians(0.000000000001)
}
expect {
	exit_turn = first_segment.bend_out_of().turn
	crossed.motorcycle.yaw.to_radians() - (0.1 - exit_turn.to_radians()) == 0.0
}

expect crossed.segment_index.to_i64() == 1

expect {
	far = rider_on_next_segment(rider_at(100.0, 0.0), World.route)
	far.motorcycle.across.distance_from_middle() >= Geom.road_half_width
}

## Where `cross_if_on_road` leaves a rider at `along` on the first segment.
crossed_from : F64 -> RiderState
crossed_from = |along| cross_if_on_road(rider_at(along, 0.0), World.route)

# A rider short of the seam stays on the first segment, and one at it crosses.
expect crossed_from(100.0).segment_index.to_i64() == 0
expect crossed_from(499.0).segment_index.to_i64() == 1

last_seg : Segment
last_seg = World.route.segment_at(Route.SegmentIndex.number(18))

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
	segment_index: Route.SegmentIndex.number(18),
	motorcycle: { ..motorcycle_at(along, 0.0), speed: Speed.at_rest },
}

expect Rider.is_finished(stopped_on_last(300.0), World.route)
expect !Rider.is_finished(stopped_on_last(299.0), World.route)
expect last_seg.ending == RouteEnds
expect !Rider.is_finished(rider_at(499.0, 0.0), World.route)

one_step_on : RiderState
one_step_on = Rider.rider_state_at_next_step(RiderState.initial, World.route)

expect one_step_on.motorcycle.along > Along.start
expect one_step_on.motorcycle.speed > Speed.at_rest
