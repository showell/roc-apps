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
import Pixels
import Pond
import Wildlife

BillboardSighting :: [].{

	## Farm animals are sighted on this many segments of the road ahead.
	farm_reach : U32
	farm_reach = 3

	## Safari animals and ducks are sighted on this many.
	wildlife_reach : U32
	wildlife_reach = 5

	## A critter shorter than this many pixels is too small to draw.
	min_critter_px : Pixels
	min_critter_px = Pixels.of(2.0)

	## What became of a critter placed in the rider's view.
	Fate : Try(Pipeline.Sighted(Billboard), [BehindCamera, TooSmall])

	## The billboards in view, in the order of `RoadAhead.segments_in_view`.
	billboards_in_view : RoadAhead.RoadView -> List(Pipeline.Sighted(Billboard))
	billboards_in_view = |road| BillboardSighting.billboard_fates(road).keep_oks(|fate| fate)

	## What became of every billboard on the segments in view, in the order of
	## `RoadAhead.segments_in_view`.
	billboard_fates : RoadAhead.RoadView -> List(BillboardSighting.Fate)
	billboard_fates = |road|
		RoadAhead.segments_in_view(road)
			.join_map(|in_view| BillboardSighting.segment_sightings(road, in_view))

	## The critters of a segment in view: its farm animals, then what lives at
	## its end.
	segment_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	segment_sightings = |road, in_view|
		BillboardSighting.farm_sightings(road, in_view)
			.concat(BillboardSighting.bend_sightings(road, in_view))

	## The cows, then the pigs, of a segment in view.
	farm_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	farm_sightings = |road, { segment, place, index: _ }|
		if is_within_reach(place, farm_reach) {
			segment.segment_cows()
				.concat(segment.segment_pigs())
				.map(|critter| sight_critter(road, { place, critter }))
		} else {
			[]
		}

	## What lives at the end of a segment in view: the animal and its baby at
	## its bend, or the ducks on its pond. The road's last segment ends quiet.
	bend_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	bend_sightings = |road, { segment, place, index: _ }|
		if is_within_reach(place, wildlife_reach) {
			bend_life_critters(segment).map(|critter| sight_critter(road, { place, critter }))
		} else {
			[]
		}

	## A critter, placed through `place` on the road's map, as the rider sees it.
	## A critter's size is tested through the lens at rest, where a tree's is
	## tested through the camera's own. The camera's focal length is never longer
	## than that, so this keeps critters a tree's test would drop while the view
	## is wide. Giving critters the tree's test would change what the ride draws.
	sight_critter : RoadAhead.RoadView,
	{
		place : SegmentPlace,
		critter : Geom.Placed(Billboard),
	} -> BillboardSighting.Fate
	sight_critter = |road, { place, critter }|
		Pipeline.tall_sighting_of(
			critter,
			{
				road,
				place,
				size_test: {
					focal_length: Lens.resting_focal,
					smallest_height_on_screen: BillboardSighting.min_critter_px,
				},
			},
		)
}

## Whether a segment at `place` is in reach: among the first `reach` of the
## road ahead, or the segment just behind, which meets the rider's own at its
## bend.
is_within_reach : SegmentPlace, U32 -> Bool
is_within_reach = |place, reach|
	match place {
		Ahead(position) => position.is_within_first(reach)
		JustBehind(_) => True
	}

## The critters at the end of `segment`, placed on it. A duck's place is
## measured from the bend at the segment's end.
bend_life_critters : Segment -> List(Geom.Placed(Billboard))
bend_life_critters = |segment|
	match segment.ending {
		Bends({ bend_life, .. }) =>
			match bend_life {
				Animal(animal) =>
					Wildlife.bend_critters({ animal, bend: segment.bend_out_of() })
				DuckPond => Pond.placed_ducks(segment.length)
				Quiet => []
			}
		RouteEnds => []
	}

expect BillboardSighting.farm_reach.to_i64() == 3
expect BillboardSighting.wildlife_reach.to_i64() == 5
