## BillboardSighting sights every billboard on the segments in view from where
## the rider is: the farm animals of the nearest segments, the safari animal and
## its baby at each bend, and the ducks on each pond.
import Billboard
import RoadAhead
import SegmentFromRider
import Pipeline

BillboardSighting :: [].{

	## The billboards in view, in the order of `RoadAhead.segments_in_view`.
	billboards_in_view :
		RoadAhead.RoadView, Pipeline.SightingCamera -> List(Pipeline.Sighted(Billboard))
	billboards_in_view = |road, camera|
		RoadAhead.segments_in_view(road)
			.join_map(|in_view| segment_billboards(road, { camera, in_view }))
}

## Farm animals are sighted on this many segments of the road ahead, chosen by
## eye.
farm_reach : U32
farm_reach = 3

## Safari animals and ducks are sighted on this many, chosen by eye.
wildlife_reach : U32
wildlife_reach = 5

## The billboards of a segment in view: its farm animals, then what lives at
## its end.
segment_billboards : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
} -> List(Pipeline.Sighted(Billboard))
segment_billboards = |road, { camera, in_view }|
	farm_sightings(road, { camera, in_view })
		.concat(bend_sightings(road, { camera, in_view }))

## The cows, then the pigs, of a segment in view.
farm_sightings : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
} -> List(Pipeline.Sighted(Billboard))
farm_sightings = |road, { camera, in_view }| {
	place = in_view.place
	if is_within_reach(place, farm_reach) {
		in_view.segment.segment_cows()
			.concat(in_view.segment.segment_pigs())
			.keep_oks(|billboard| Pipeline.scenery_sighting_of(billboard, { road, camera, place }))
	} else {
		[]
	}
}

## What lives at the end of a segment in view: the animal and its baby at
## its bend, or the ducks on its pond. The road's last segment ends quiet.
bend_sightings : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
} -> List(Pipeline.Sighted(Billboard))
bend_sightings = |road, { camera, in_view }| {
	place = in_view.place
	if is_within_reach(place, wildlife_reach) {
		in_view.segment.segment_bend_billboards()
			.keep_oks(|billboard| Pipeline.scenery_sighting_of(billboard, { road, camera, place }))
	} else {
		[]
	}
}

## Whether a segment at `place` is in reach: among the first `reach` of the
## road ahead, or the segment just behind, which meets the rider's own at its
## bend.
is_within_reach : SegmentFromRider, U32 -> Bool
is_within_reach = |place, reach|
	match place {
		Ahead(position) => position.is_within_first(reach)
		JustBehind => True
	}

## The third segment of the road ahead, the rider's own first.
third_position : SegmentFromRider.Position
third_position = SegmentFromRider.Position.first.next().next()

expect is_within_reach(Ahead(third_position), 3)
expect !is_within_reach(Ahead(third_position.next()), 3)
expect is_within_reach(JustBehind, 3)
