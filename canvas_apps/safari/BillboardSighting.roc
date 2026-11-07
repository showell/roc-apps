## BillboardSighting sights every billboard on the road ahead from where the
## rider is: the farm animals of the nearest segments, the safari animal and its
## baby at each bend, and the ducks on each pond. The bend and the pond of the
## segment before the rider's are sighted too, so the bend the rider has just
## turned keeps its animals.
import Along
import Billboard
import RoadAhead
import Geom
import Lens
import Pipeline
import Pixels
import Pond
import Wildlife
import Scenery
import World

BillboardSighting :: [].{

	## Farm animals are sighted on this many segments of the road ahead.
	farm_reach : U32
	farm_reach = 3

	## Safari animals and ducks are sighted on this many.
	wildlife_reach : U32
	wildlife_reach = 5

	## No more critters than this are drawn in a frame.
	max_visible_critters : I64
	max_visible_critters = 320

	## A critter shorter than this many pixels is too small to draw.
	min_critter_px : Pixels
	min_critter_px = Pixels.of(2.0)

	## What became of a critter placed in the rider's view.
	Fate : Try(Pipeline.Sighted(Billboard), [BehindCamera, TooSmall])

	## The critters to draw, of `fates`. The cap comes after the cull, so a
	## critter out of view never takes a place from one in view.
	critters_to_draw : List(BillboardSighting.Fate) -> List(Pipeline.Sighted(Billboard))
	critters_to_draw = |fates|
		fates.keep_oks(|fate| fate).take_first(BillboardSighting.max_visible_critters.to_u64_wrap())

	## Every critter in view, nearest segment first, then those of the segment
	## before the rider's, when there is one.
	critter_fates : RoadAhead.RoadView -> List(BillboardSighting.Fate)
	critter_fates = |road|
		RoadAhead.segments_in_view(road)
			.join_map(|in_view| BillboardSighting.segment_sightings(road, in_view))

	## The critters of a segment in view: its farm animals, its bend's
	## animals, then its pond's ducks.
	segment_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	segment_sightings = |road, in_view|
		[
			BillboardSighting.farm_sightings(road, in_view),
			BillboardSighting.wildlife_sightings(road, in_view),
			BillboardSighting.duck_sightings(road, in_view),
		].join()

	## The cows, then the pigs, of a segment in view. The farm animals stand
	## along their segment, so the segment just behind, which the rider has
	## passed, has none in view.
	farm_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	farm_sightings = |road, { segment, place, index: _ }|
		match place {
			Ahead(position) =>
				if position.is_within_first(farm_reach) {
					segment.cows.concat(segment.pigs)
						.map(|critter| sight_critter(road, { place, critter }))
				} else {
					[]
				}
			JustBehind(_) => []
		}

	## The animals at the bend that ends a segment in view. The road's last
	## segment ends with no bend.
	wildlife_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	wildlife_sightings = |road, { segment, place, index: _ }|
		match segment.ending {
			Continues(_) =>
				if is_within_reach(place, wildlife_reach) {
					bend_sightings(road, { place, segment })
				} else {
					[]
				}
			Terminates => []
		}

	## The ducks of a segment in view, if it has a pond.
	duck_sightings : RoadAhead.RoadView, RoadAhead.SegmentInView -> List(BillboardSighting.Fate)
	duck_sightings = |road, { segment, place, index: _ }|
		if is_within_reach(place, wildlife_reach) {
			pond_sightings(road, { place, segment })
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
		place : RoadAhead.SegmentPlace,
		critter : Geom.Placed(Billboard),
	} -> BillboardSighting.Fate
	sight_critter = |road, { place, critter }|
		Pipeline.tall_sighting_of(
			critter,
			{
				road,
				place,
				size_test: {
					focal: Lens.resting_focal,
					smallest_px: BillboardSighting.min_critter_px,
				},
			},
		)
}

## Whether a segment at `place` is in reach: among the first `reach` of the
## road ahead, or the segment just behind, whose bend the rider has just turned.
is_within_reach : RoadAhead.SegmentPlace, U32 -> Bool
is_within_reach = |place, reach|
	match place {
		Ahead(position) => position.is_within_first(reach)
		JustBehind(_) => True
	}

bend_sightings : RoadAhead.RoadView,
{
	place : RoadAhead.SegmentPlace,
	segment : World.Segment,
} -> List(BillboardSighting.Fate)
bend_sightings = |road, { place, segment }|
	Wildlife.bend_critters({
		bend_life: segment.bend_life,
		bend_along: Along.at(segment.length),
		turn: segment.exit_turn,
		road_half_width: Geom.road_half_width,
	})
		.map(|critter| BillboardSighting.sight_critter(road, { place, critter }))

## The ducks on `segment`'s pond, if it has one. A duck's place is measured
## from the bend at the segment's end.
pond_sightings : RoadAhead.RoadView,
{
	place : RoadAhead.SegmentPlace,
	segment : World.Segment,
} -> List(BillboardSighting.Fate)
pond_sightings = |road, { place, segment }|
	if Scenery.is_pond(segment.bend_life) {
		Pond.placed_ducks(segment.length)
			.map(|critter| BillboardSighting.sight_critter(road, { place, critter }))
	} else {
		[]
	}

expect BillboardSighting.farm_reach.to_i64() == 3
expect BillboardSighting.wildlife_reach.to_i64() == 5
