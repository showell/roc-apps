## GroundSighting finds the ground under everything else in a frame, as patches
## for `Ground` to paint: the road, in chunks along each segment in view; the
## paved corner where one segment bends into the next; and the pond beside a
## segment that ends at one. It has no `depth_keys`: the ground is painted first,
## under everything, so nothing sorts it.
import Along
import Distance
import Chain
import Geom
import Ground
import BendView
import Pond
import Scenery
import World

GroundSighting :: [].{

	## One chunk of the road along the segment at `position` in the chain,
	## which is `segment_length` long and laid in `chunk_count` chunks.
	RoadChunk : {
		position : Chain.Position,
		segment_length : Distance,
		chunk_count : U32,
		chunk_number : U32,
	}

	road_color : I64
	road_color = 0x34353C

	## The road is laid in chunks no longer than this.
	road_chunk_length : Distance
	road_chunk_length = Distance.metres(25.0)

	## A bend's paving starts this far before the end of the segment that
	## bends.
	lead_in_length : Distance
	lead_in_length = Distance.metres(40.0)

	## The ground in view, in paint order: each segment of the chain ahead in
	## turn, then the bend from the segment behind.
	in_view : Chain.RoadView -> List(Ground.Patch)
	in_view = |road| {
		positions = Chain.Position.all_in(road.chain)
		ahead = positions.join_map(|position| segment_ground(road, position))
		match Chain.segment_behind(road) {
			Previous(segment_behind) => ahead.concat(ground_behind(road, segment_behind))
			AtRouteStart => ahead
		}
	}

	## How many chunks the road along a segment `length` long is laid in:
	## at least one.
	chunks_along : Distance -> U32
	chunks_along = |length| {
		chunks =
			length.ratio_to(GroundSighting.road_chunk_length).ceiling_to_i64_try()
				?? crash "GroundSighting.chunks_along: a segment's length is finite"
		chunks.max(1).to_u32_wrap()
	}

	## The road along the segment at `position` in the chain, chunk by chunk.
	segment_road : Chain.RoadView, Chain.Position -> List(Ground.Patch)
	segment_road = |road, position| {
		segment_length = segment_in_chain(road, position).length
		chunk_count = GroundSighting.chunks_along(segment_length)
		List.from_iter(U32.until(0, chunk_count)).map(
			|chunk_number| road_patch(
				GroundSighting.chunk_corners(
					road,
					{ position, segment_length, chunk_count, chunk_number },
				),
			),
		)
	}

	## A chunk's corners: across its near end, then back across its far end.
	chunk_corners : Chain.RoadView, GroundSighting.RoadChunk -> List(Geom.RiderPoint)
	chunk_corners = |road, { position, segment_length, chunk_count, chunk_number }| {
		end_of_chunk = |number|
			Along.at(segment_length.times(number.to_f64()).divided_by(chunk_count.to_f64()))
		near_end = end_of_chunk(chunk_number)
		far_end = end_of_chunk(chunk_number + 1)
		corner = |along, across| Chain.rider_point_ahead(road, { position, along, across })
		[
			corner(near_end, Scenery.left_edge),
			corner(near_end, Scenery.right_edge),
			corner(far_end, Scenery.right_edge),
			corner(far_end, Scenery.left_edge),
		]
	}
}

## A patch of road with these corners.
road_patch : List(Geom.RiderPoint) -> Ground.Patch
road_patch = |corners| { corners, color: GroundSighting.road_color }

## The segment at `position` in the chain.
segment_in_chain : Chain.RoadView, Chain.Position -> World.Segment
segment_in_chain = |road, position|
	position.index_in(road.chain).segment_in(road.route)

## The ground along the segment at `position` in the chain: its road, the
## bend into the next segment if the chain goes on, and its pond if it
## ends at one.
segment_ground : Chain.RoadView, Chain.Position -> List(Ground.Patch)
segment_ground = |road, position| {
	segment = segment_in_chain(road, position)
	place = InChain(position)
	bend =
		if position.is_last_in(road.chain) {
			[]
		} else {
			bend_ground(
				road,
				BendView.of_segment(segment, { before: place, after: InChain(position.next()) }),
			)
		}
	[
		GroundSighting.segment_road(road, position),
		bend,
		pond_ground(road, { segment, place }),
	].join()
}

## The bend into the rider's segment from the segment at `index`, and the
## pond that segment ends at, if it has one.
ground_behind : Chain.RoadView, World.SegmentIndex -> List(Ground.Patch)
ground_behind = |road, index| {
	segment = index.segment_in(road.route)
	before = Chain.place_behind(segment)
	after = InChain(Chain.Position.first)
	bend_ground(
		road,
		BendView.of_segment(segment, { before, after }),
	).concat(pond_ground(road, { segment, place: before }))
}

## A bend's paving: the road just before it, then the corner it cuts.
bend_ground : Chain.RoadView, BendView -> List(Ground.Patch)
bend_ground = |road, bend| [road_patch(lead_in(road, bend)), road_patch(bend_corner(road, bend))]

## The last `lead_in_length` of the road before a bend.
lead_in : Chain.RoadView, BendView -> List(Geom.RiderPoint)
lead_in = |road, bend| {
	corner = |along, across| Chain.rider_point_at(road, { place: bend.before, along, across })
	end = Along.at(bend.length_before)
	start = Along.at(bend.length_before.minus(GroundSighting.lead_in_length))
	[
		corner(end, Scenery.left_edge),
		corner(end, Scenery.right_edge),
		corner(start, Scenery.right_edge),
		corner(start, Scenery.left_edge),
	]
}

## The corner a bend cuts: from the inner edge where the segment before
## ends, to its outer edge there, out to where the two outer edges meet,
## and back to the outer edge where the segment after starts.
bend_corner : Chain.RoadView, BendView -> List(Geom.RiderPoint)
bend_corner = |road, bend| {
	inner_edge = if bend.turn.is_right() {
		Scenery.right_edge
	} else {
		Scenery.left_edge
	}
	outer_edge = BendView.outer_edge(bend.turn)
	end_at = |across| Chain.rider_point_at(
		road,
		{
			place: bend.before,
			along: Along.at(bend.length_before),
			across,
		},
	)
	[
		end_at(inner_edge),
		end_at(outer_edge),
		BendView.apex(road, bend),
		Chain.rider_point_at(
			road,
			{
				place: bend.after,
				along: Along.start,
				across: outer_edge,
			},
		),
	]
}

## The pond past the end of `segment`, which lies at `place`: its water, then
## its bank. A segment that ends at no pond has none.
pond_ground : Chain.RoadView,
{
	segment : World.Segment,
	place : Chain.SegmentPlace,
} -> List(Ground.Patch)
pond_ground = |road, { segment, place }|
	if Scenery.is_pond(segment.bend_life) {
		on_map = |outline|
			outline.map(
				|point| Chain.rider_point_at(
					road,
					{
						place,
						along: Along.at(segment.length).plus(point.along.from_start()),
						across: point.across,
					},
				),
			)
		[
			{ corners: on_map(Pond.water_outline), color: Pond.water_color },
			{ corners: on_map(Pond.bank), color: Pond.bank_color },
		]
	} else {
		[]
	}

expect GroundSighting.road_chunk_length.to_metres() == 25.0
expect GroundSighting.lead_in_length.to_metres() == 40.0
expect GroundSighting.road_color == 0x34353C
expect
	[
		(25.0, 1),
		(25.1, 2),
		(50.0, 2),
		(49.9, 2),
		(1.0, 1),
		(0.0, 1),
		(500.0, 20),
		(320.0, 13),
		(1200.0, 48),
	].all(|(length, want)| GroundSighting.chunks_along(Distance.metres(length)).to_i64() == want)
