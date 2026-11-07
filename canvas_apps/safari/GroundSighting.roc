## GroundSighting finds the ground under everything else in a frame, as patches
## for `Ground` to paint: the road, in chunks along each segment in view; the
## paved corner where one segment bends into the next; and the pond beside a
## segment that ends at one. It is never depth sorted, because the ground is
## painted first, under everything.
import Along
import Distance
import RoadAhead
import SegmentPlace
import Geom
import Ground
import BendView
import Pond
import Scenery
import World
import lib.RgbColor

GroundSighting :: [].{

	## One chunk of the road along the segment at `place`, which is
	## `segment_length` long and laid in `chunk_count` chunks.
	RoadChunk : {
		place : SegmentPlace,
		segment_length : Distance,
		chunk_count : U32,
		chunk_number : U32,
	}

	road_color : RgbColor
	road_color = RgbColor.of(0x34353C)

	## The road is laid in chunks no longer than this.
	road_chunk_length : Distance
	road_chunk_length = Distance.metres(25.0)

	## A bend's paving starts this far before the end of the segment that
	## bends.
	lead_in_length : Distance
	lead_in_length = Distance.metres(40.0)

	## The ground in view, in paint order: each segment in view in the order of
	## `RoadAhead.segments_in_view`.
	patches_in_view : RoadAhead.RoadView -> List(Ground.Patch)
	patches_in_view = |road|
		RoadAhead.segments_in_view(road).join_map(|in_view| ground_patches(road, in_view))

	## How many chunks the road along a segment `length` long is laid in:
	## at least one.
	chunks_along : Distance -> U32
	chunks_along = |length| {
		chunks =
			length.ratio_to(GroundSighting.road_chunk_length).ceiling_to_i64_try()
				?? crash "GroundSighting.chunks_along: a segment's length is finite"
		chunks.max(1).to_u32_wrap()
	}

	## The road along a segment in view, chunk by chunk.
	road_patches : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(Ground.Patch)
	road_patches = |road, in_view| {
		place = in_view.place
		segment_length = in_view.segment.length
		chunk_count = GroundSighting.chunks_along(segment_length)
		List.from_iter(U32.until(0, chunk_count)).map(
			|chunk_number| road_patch(
				GroundSighting.chunk_corners(
					road,
					{ place, segment_length, chunk_count, chunk_number },
				),
			),
		)
	}

	## A chunk's corners: across its near end, then back across its far end.
	chunk_corners : RoadAhead.RoadView, GroundSighting.RoadChunk -> List(Geom.RiderPoint)
	chunk_corners = |road, { place, segment_length, chunk_count, chunk_number }| {
		end_of_chunk = |number|
			Along.at(segment_length.times(number.to_f64()).divided_by(chunk_count.to_f64()))
		near_end = end_of_chunk(chunk_number)
		far_end = end_of_chunk(chunk_number + 1)
		corner = |along, across| RoadAhead.rider_point_at(road, { place, along, across })
		[
			corner(near_end, Geom.left_edge),
			corner(near_end, Geom.right_edge),
			corner(far_end, Geom.right_edge),
			corner(far_end, Geom.left_edge),
		]
	}
}

## A patch of road with these corners.
road_patch : List(Geom.RiderPoint) -> Ground.Patch
road_patch = |corners| { corners, color: GroundSighting.road_color }

## The ground of a segment in view: its road, the bend into the next segment
## if the road in view goes on, and its pond if it ends at one. The segment
## just behind lays no road along it, and its bend's paving stands for it,
## because that paving lays the last `lead_in_length` of its road. The cut at the
## near plane does not make this rule: just past a bend, the last chunk of road
## behind reaches in front of the camera and would draw. Road further back on
## it would show at a bend sharper than a right angle, and the route has none.
ground_patches : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(Ground.Patch)
ground_patches = |road, in_view| {
	segment = in_view.segment
	place = in_view.place
	road_along =
		match place {
			Ahead(_) => GroundSighting.road_patches(road, in_view)
			JustBehind(_) => []
		}
	bend =
		if RoadAhead.has_bend_in_view(road, in_view) {
			bend_patches(road, BendView.of_segment(segment, place))
		} else {
			[]
		}
	[
		road_along,
		bend,
		pond_patches(road, { segment, place }),
	].join()
}

## A bend's paving: the road just before it, then the corner it cuts.
bend_patches : RoadAhead.RoadView, BendView -> List(Ground.Patch)
bend_patches = |road, bend| [
	road_patch(lead_points(road, bend)),
	road_patch(bend_corners(road, bend)),
]

## The last `lead_in_length` of the road before a bend.
lead_points : RoadAhead.RoadView, BendView -> List(Geom.RiderPoint)
lead_points = |road, bend| {
	corner = |along, across| RoadAhead.rider_point_at(road, { place: bend.before, along, across })
	end = Along.at(bend.length_before)
	start = Along.at(bend.length_before.minus(GroundSighting.lead_in_length))
	[
		corner(end, Geom.left_edge),
		corner(end, Geom.right_edge),
		corner(start, Geom.right_edge),
		corner(start, Geom.left_edge),
	]
}

## The corner a bend cuts: from the inner edge where the segment before
## ends, to its outer edge there, out to where the two outer edges meet,
## and back to the outer edge where the segment after starts.
bend_corners : RoadAhead.RoadView, BendView -> List(Geom.RiderPoint)
bend_corners = |road, bend| {
	inner_edge = if bend.turn.is_right() {
		Geom.right_edge
	} else {
		Geom.left_edge
	}
	outer_edge = BendView.outer_edge(bend.turn)
	end_at = |across| RoadAhead.rider_point_at(
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
		RoadAhead.rider_point_at(
			road,
			{
				place: BendView.place_after(bend),
				along: Along.start,
				across: outer_edge,
			},
		),
	]
}

## The pond past the end of `segment`, which lies at `place`: its water, then
## its bank. A segment that ends at no pond has none.
pond_patches : RoadAhead.RoadView,
{
	segment : World.Segment,
	place : SegmentPlace,
} -> List(Ground.Patch)
pond_patches = |road, { segment, place }|
	if Scenery.is_pond(segment.bend_life) {
		on_map = |outline|
			outline.map(
				|point| {
					on_segment = Pond.segment_point(point, segment.length)
					RoadAhead.rider_point_at(
						road,
						{ place, along: on_segment.along, across: on_segment.across },
					)
				},
			)
		[
			{ corners: on_map(Pond.water_points), color: Pond.water_color },
			{ corners: on_map(Pond.bank_points), color: Pond.bank_color },
		]
	} else {
		[]
	}

expect GroundSighting.road_chunk_length.to_metres() == 25.0
expect GroundSighting.lead_in_length.to_metres() == 40.0
expect GroundSighting.road_color == RgbColor.of(0x34353C)
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
