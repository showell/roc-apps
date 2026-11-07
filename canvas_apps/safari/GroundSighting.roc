## GroundSighting finds the ground under everything else in a frame, as
## patches: the road, in chunks along each segment in view; the paved corner
## where one segment bends into the next; and the pond beside a segment that
## ends at one. It is never depth sorted, because the ground is painted first,
## under everything.
import Along
import Distance
import RoadAhead
import Segment
import SegmentPlace
import Geom
import Ground
import BendView
import Pond
import lib.RgbColor

GroundSighting :: [].{

	## The ground in view, in paint order: each segment in view in the order of
	## `RoadAhead.segments_in_view`.
	patches_in_view : RoadAhead.RoadView -> List(Ground.Patch)
	patches_in_view = |road|
		RoadAhead.segments_in_view(road).join_map(|in_view| ground_patches(road, in_view))

	## How many chunks the edges of the road along a segment `length` long
	## are laid in: at least one.
	chunks_along : Distance -> U32
	chunks_along = |length| {
		chunks =
			length.portion(road_chunk_length).ceiling_to_i64_try()
				?? crash "GroundSighting.chunks_along: a segment's length is finite"
		chunks.max(1).to_u32_wrap()
	}

	## The road along a segment in view, as one patch: across its start, up its
	## right edge to the end of each chunk, then back down its left edge. It is
	## one patch, not a patch a chunk, because a canvas smooths each patch's
	## edges on its own, and where two patches meet the grass under them shows
	## through as a pale seam.
	road_along : RoadAhead.RoadView, RoadAhead.SegmentInView -> Ground.Patch
	road_along = |road, in_view| {
		place = in_view.place
		segment_length = in_view.segment.length
		chunk_count = GroundSighting.chunks_along(segment_length)
		corner = |chunk_number, across| {
			along = chunk_end(segment_length, chunk_number)
			RoadAhead.rider_point_at(road, { place, along, across })
		}
		up_right_edge =
			List.from_iter(U32.until(0, chunk_count + 1))
				.map(|number| corner(number, Geom.right_edge))
		down_left_edge =
			List.from_iter(U32.until(0, chunk_count))
				.map(|k| corner(chunk_count - k, Geom.left_edge))
		road_patch([corner(0, Geom.left_edge)].concat(up_right_edge).concat(down_left_edge))
	}
}

road_color : RgbColor
road_color = RgbColor.of(0x34353C)

## The road's edges are laid in chunks no longer than this. Chunks at most
## 25 m long keep the chord cut at the horizon below a pixel.
road_chunk_length : Distance
road_chunk_length = Distance.metres(25.0)

## A bend's paving starts this far before the end of the segment that
## bends.
lead_in_length : Distance
lead_in_length = Distance.metres(40.0)

## Where chunk `chunk_number` of the road along a segment `segment_length` long
## ends, the chunks counted from 1. Chunk 0 ends where the segment starts.
chunk_end : Distance, U32 -> Along
chunk_end = |segment_length, chunk_number| {
	chunk_count = GroundSighting.chunks_along(segment_length)
	Along.at(segment_length.times(chunk_number.to_f64()).divided_by(chunk_count.to_f64()))
}

## How long the segment after a bend is.
length_after : RoadAhead.RoadView, BendView -> Distance
length_after = |road, bend_view|
	match BendView.place_after(bend_view) {
		Ahead(position) => RoadAhead.segment_at(road, position).length
		JustBehind(_) => crash "GroundSighting.length_after: the segment after a bend is never behind the rider"
	}

## A patch of road with these corners.
road_patch : List(Geom.RiderPoint) -> Ground.Patch
road_patch = |corners| { corners, color: road_color }

## The ground of a segment in view: its road, the bend into the next segment
## if the road in view goes on, and its pond if it ends at one. The segment
## just behind lays no road along it, and its bend's paving stands for it,
## because that paving lays the last `lead_in_length` of its road. The cut at the
## near plane does not make this rule: just past a bend, the end of the road
## behind reaches in front of the camera and would draw. Road further back on
## it would show at a bend sharper than a right angle, and the route has none.
ground_patches : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(Ground.Patch)
ground_patches = |road, in_view| {
	segment = in_view.segment
	place = in_view.place
	along_segment =
		match place {
			Ahead(_) => [GroundSighting.road_along(road, in_view)]
			JustBehind(_) => []
		}
	bend =
		match BendView.bend_after(road, in_view) {
			Ok(bend_view) => [bend_paving(road, bend_view)]
			Err(RoadEndsInView) => []
		}
	[
		along_segment,
		bend,
		pond_patches(road, { segment, place }),
	].join()
}

## A bend's paving, as one patch: the last `lead_in_length` of the road before
## the bend, the corner it cuts out to where the two outer edges meet, and the
## first chunk of the road after it. It runs up the left edge and back down the
## right, and the outer edge takes in the apex.
##
## The road along each segment ends inside the paving, so where they meet is
## road over road, and no seam shows. The paving takes in the first chunk after
## the bend for that reason, though that road is laid anyway, and it ends where
## that chunk ends, so its edges there are the road's own.
bend_paving : RoadAhead.RoadView, BendView -> Ground.Patch
bend_paving = |road, bend_view| {
	length_before = bend_view.bend.segment_length
	before = |along, across| RoadAhead.rider_point_at(
		road,
		{ place: bend_view.before, along, across },
	)
	after = |along, across| RoadAhead.rider_point_at(
		road,
		{ place: BendView.place_after(bend_view), along, across },
	)
	lead_start = Along.at(length_before.minus(lead_in_length))
	end = Along.at(length_before)
	lead_end = chunk_end(length_after(road, bend_view), 1)
	apex = BendView.apex(road, bend_view)
	left = Geom.left_edge
	right = Geom.right_edge
	corners =
		if bend_view.turn().is_right() {
			[
				before(lead_start, left),
				before(end, left),
				apex,
				after(Along.start, left),
				after(lead_end, left),
				after(lead_end, right),
				before(end, right),
				before(lead_start, right),
			]
		} else {
			[
				before(lead_start, left),
				before(end, left),
				after(lead_end, left),
				after(lead_end, right),
				after(Along.start, right),
				apex,
				before(end, right),
				before(lead_start, right),
			]
		}
	road_patch(corners)
}

## The pond past the end of `segment`, which lies at `place`: its bank, then
## its water. A segment that ends at no pond has none.
pond_patches : RoadAhead.RoadView, { segment : Segment, place : SegmentPlace } -> List(Ground.Patch)
pond_patches = |road, { segment, place }| {
	is_at_pond =
		match segment.ending {
			Bends({ bend_life, .. }) =>
				match bend_life {
					DuckPond => True
					Animal(_) | Quiet => False
				}
			RouteEnds => False
		}
	if is_at_pond {
		rider_point = |road_point|
			RoadAhead.rider_point_at(
				road,
				{ place, along: road_point.along, across: road_point.across },
			)
		Pond.pond_outlines(segment.bend_out_of()).map(
			|outline| { corners: outline.corners.map(rider_point), color: outline.color },
		)
	} else {
		[]
	}
}

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
