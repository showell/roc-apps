## BillboardSighting sights every billboard on the segments in view from where
## the rider is: the farm animals of the nearest segments, the safari animal and
## its baby at each bend, and the ducks on each pond.
import Billboard
import RoadAhead
import Segment
import SegmentPlace
import Geom
import Lens
import Pipeline
import Pond
import Wildlife

BillboardSighting :: [].{

	## The billboards in view, in the order of `RoadAhead.segments_in_view`.
	billboards_in_view : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		..,
	} -> List(Pipeline.Sighted(Billboard))
	billboards_in_view = |road, camera|
		billboard_fates(road, camera).keep_oks(|fate| fate)
}

## Farm animals are sighted on this many segments of the road ahead.
farm_reach : U32
farm_reach = 3

## Safari animals and ducks are sighted on this many.
wildlife_reach : U32
wildlife_reach = 5

## What became of a billboard placed in the rider's view.
Fate : Try(Pipeline.Sighted(Billboard), [BehindCamera, TooSmall])

## What became of every billboard on the segments in view, in the order of
## `RoadAhead.segments_in_view`.
billboard_fates : RoadAhead.RoadView, { vantage : Geom.Vantage, .. } -> List(Fate)
billboard_fates = |road, camera|
	RoadAhead.segments_in_view(road)
		.join_map(|in_view| segment_billboards(road, { vantage: camera.vantage, in_view }))

## The billboards of a segment in view: its farm animals, then what lives at
## its end.
segment_billboards : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
} -> List(Fate)
segment_billboards = |road, { vantage, in_view }|
	farm_sightings(road, { vantage, in_view })
		.concat(bend_sightings(road, { vantage, in_view }))

## The cows, then the pigs, of a segment in view.
farm_sightings : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
} -> List(Fate)
farm_sightings = |road, { vantage, in_view }| {
	place = in_view.place
	if is_within_reach(place, farm_reach) {
		in_view.segment.segment_cows()
			.concat(in_view.segment.segment_pigs())
			.map(|billboard| sight_billboard(road, { vantage, place, billboard }))
	} else {
		[]
	}
}

## What lives at the end of a segment in view: the animal and its baby at
## its bend, or the ducks on its pond. The road's last segment ends quiet.
bend_sightings : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
} -> List(Fate)
bend_sightings = |road, { vantage, in_view }| {
	place = in_view.place
	if is_within_reach(place, wildlife_reach) {
		bend_life_billboards(in_view.segment)
			.map(|billboard| sight_billboard(road, { vantage, place, billboard }))
	} else {
		[]
	}
}

## A billboard, placed through `place` on the road's map, as the rider sees it.
## A billboard's size is tested through the lens at rest, where a tree's is
## tested through the camera's own. The camera's focal length is never longer
## than that, so this keeps billboards a tree's test would drop while the view
## is wide. Giving billboards the tree's test would change what the ride draws.
sight_billboard : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	place : SegmentPlace,
	billboard : Geom.Placed(Billboard),
} -> Fate
sight_billboard = |road, { vantage, place, billboard }|
	Pipeline.tall_sighting_of(billboard, { road, vantage, place, size_focal: Lens.resting_focal })

## Whether a segment at `place` is in reach: among the first `reach` of the
## road ahead, or the segment just behind, which meets the rider's own at its
## bend.
is_within_reach : SegmentPlace, U32 -> Bool
is_within_reach = |place, reach|
	match place {
		Ahead(position) => position.is_within_first(reach)
		JustBehind => True
	}

expect is_within_reach(Ahead(SegmentPlace.Position.number(2)), 3)
expect !is_within_reach(Ahead(SegmentPlace.Position.number(3)), 3)
expect is_within_reach(JustBehind, 3)

## The billboards at the end of `segment`, placed on it. A duck's place is
## measured from the bend at the segment's end.
bend_life_billboards : Segment -> List(Geom.Placed(Billboard))
bend_life_billboards = |segment|
	match segment.segment_ending() {
		Bends({ bend, bend_life }) =>
			match bend_life {
				Animal(animal) => Wildlife.bend_billboards({ animal, bend })
				DuckPond => Pond.placed_ducks(bend)
				Quiet => []
			}
		RouteEnds => []
	}
