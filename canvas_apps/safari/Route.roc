## The route is the line of segments the ride follows, in order. Every segment
## but the last bends into the one after it, and the last ends the route, so a
## route can only be built in that shape. A segment's place in the route is its
## `Route.SegmentIndex`.
import Along
import Angle
import Distance
import Segment

Route :: List(Segment).{

	## A segment's place in the route, counted from 0. It says where a segment
	## is in the route, where a SegmentPlace.Position says how far ahead of the
	## rider it is.
	SegmentIndex :: U32.{

		number : U32 -> Route.SegmentIndex
		number = |n| Route.SegmentIndex.(n)

		to_u32 : Route.SegmentIndex -> U32
		to_u32 = |Route.SegmentIndex.(n)| n

		## The route's first segment.
		first : Route.SegmentIndex
		first = Route.SegmentIndex.(0)

		next : Route.SegmentIndex -> Route.SegmentIndex
		next = |Route.SegmentIndex.(n)| Route.SegmentIndex.(n + 1)

		## The segment before this one, unless this is the first.
		previous : Route.SegmentIndex -> [Previous(Route.SegmentIndex), AtRouteStart]
		previous = |Route.SegmentIndex.(n)|
			if n == 0 {
				AtRouteStart
			} else {
				Previous(Route.SegmentIndex.(n - 1))
			}

		## How many segments come before this one.
		count_before : Route.SegmentIndex -> U64
		count_before = |Route.SegmentIndex.(n)| n.to_u64()

		is_eq : _
	}

	## The route along `route_segments`, which must have the route's shape:
	## every segment but the last bends into the next, and the last ends the
	## route.
	from_segments : List(Segment) -> Route
	from_segments = |route_segments| {
		count = route_segments.len()
		is_in_place = |segment, at|
			match segment.ending {
				Bends(_) => at + 1 < count
				RouteEnds => at + 1 == count
			}
		is_route_shaped = route_segments.map_with_index(is_in_place).all(|is_ok| is_ok)
		if !route_segments.is_empty() and is_route_shaped {
			Route.(route_segments)
		} else {
			crash "Route.from_segments: every segment but the last bends, and the last ends the route"
		}
	}

	## The route's segments, in order.
	route_segments : Route -> List(Segment)
	route_segments = |Route.(segments)| segments

	## How many segments the route has.
	segment_count : Route -> U64
	segment_count = |Route.(segments)| segments.len()

	## The segment at `index`.
	segment_at : Route, Route.SegmentIndex -> Segment
	segment_at = |Route.(segments), index|
		segments.get(index.count_before())
			?? crash "Route.segment_at: the route has no segment there"

	## The route's length, end to end: where its last segment ends.
	route_length : Route -> Distance
	route_length = |route|
		match route.segments_with_ends().last() {
			Ok(last) => last.end
			Err(_) => crash "Route.route_length: a route has a segment"
		}

	## How far along the route the point at `along` on the segment at `index`
	## is: where the segment before it ends, plus `along`.
	distance_along_route : Route, { index : Route.SegmentIndex, along : Along } -> Distance
	distance_along_route = |route, { index, along }| {
		start =
			match index.previous() {
				AtRouteStart => Distance.zero
				Previous(before) =>
					match route.segments_with_ends().get(before.count_before()) {
						Ok(stretch) => stretch.end
						Err(_) => crash "Route.distance_along_route: the route has no segment there"
					}
			}
		start.plus(along.from_start())
	}

	## Each of the route's segments, in order, with how far along the route it
	## ends. It is the one sum of the route's lengths, which every other
	## distance along the route reads. The lengths are added from the first
	## segment on: a float sum's rounding depends on its order, and another order
	## can move a pixel.
	segments_with_ends : Route -> List({ segment : Segment, end : Distance })
	segments_with_ends = |Route.(segments)|
		segments
			.fold(
				{ reached: Distance.zero, stretches: [] },
				|{ reached, stretches }, segment| {
					end = reached.plus(segment.length)
					{ reached: end, stretches: stretches.append({ segment, end }) }
				},
			)
			.stretches

	## The bearing the segment at `index` sets off on: north, turned by the bend
	## out of each segment before it. The turns are added from the first segment
	## on: a float sum's rounding depends on its order, and another order can
	## move a pixel of the sky.
	bearing_of : Route, Route.SegmentIndex -> Angle.Bearing
	bearing_of = |Route.(segments), index|
		segments
			.take_first(index.count_before())
			.fold(Angle.north, |bearing, segment| bearing.plus(segment.bend_out_of().turn))
}
