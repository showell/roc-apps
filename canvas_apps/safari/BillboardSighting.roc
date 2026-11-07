## BillboardSighting sights every billboard on the road ahead from where the
## rider is: the farm animals of the nearest segments, the safari animal and its
## baby at each bend, and the ducks on each pond. The critters of the segment
## before the rider's are sighted too, so the bend the rider has just turned
## keeps its animals.
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

	## Every critter ahead, nearest segment first, then those of the segment
	## before the rider's, when there is one.
	critter_fates : RoadAhead.RoadView -> List(BillboardSighting.Fate)
	critter_fates = |road|
		match RoadAhead.segment_behind(road) {
			Previous(segment_behind) =>
				BillboardSighting.sightings_ahead(road).concat(
					BillboardSighting.sightings_behind(road, segment_behind),
				)
			AtRouteStart => BillboardSighting.sightings_ahead(road)
		}

	## The critters of every segment on the road ahead, nearest first.
	sightings_ahead : RoadAhead.RoadView -> List(BillboardSighting.Fate)
	sightings_ahead = |road|
		RoadAhead.Position.positions_in(road.segments_ahead)
			.join_map(|position| BillboardSighting.sightings_at(road, position))

	## The critters of the segment at `position` on the road ahead: its
	## farm animals, its bend's animals, then its pond's ducks.
	sightings_at : RoadAhead.RoadView, RoadAhead.Position -> List(BillboardSighting.Fate)
	sightings_at = |road, position|
		[
			BillboardSighting.farm_sightings(road, position),
			BillboardSighting.wildlife_sightings(road, position),
			BillboardSighting.duck_sightings(road, position),
		].join()

	## The cows, then the pigs, of the segment at `position` on the road ahead.
	farm_sightings : RoadAhead.RoadView, RoadAhead.Position -> List(BillboardSighting.Fate)
	farm_sightings = |road, position|
		if position.is_within_first(farm_reach) {
			segment = RoadAhead.segment_at(road, position)
			segment.cows.concat(segment.pigs)
				.map(|critter| sight_critter(road, { place: Ahead(position), critter }))
		} else {
			[]
		}

	## The animals at the bend that ends the segment at `position` on the
	## road ahead. The road's last segment ends with no bend.
	wildlife_sightings : RoadAhead.RoadView, RoadAhead.Position -> List(BillboardSighting.Fate)
	wildlife_sightings = |road, position| {
		segment = RoadAhead.segment_at(road, position)
		match segment.ending {
			Continues(_) =>
				if position.is_within_first(wildlife_reach) {
					bend_sightings(road, { place: Ahead(position), segment })
				} else {
					[]
				}
			Terminates => []
		}
	}

	## The ducks of the segment at `position` on the road ahead, if it has a
	## pond.
	duck_sightings : RoadAhead.RoadView, RoadAhead.Position -> List(BillboardSighting.Fate)
	duck_sightings = |road, position|
		if position.is_within_first(wildlife_reach) {
			pond_sightings(
				road,
				{ place: Ahead(position), segment: RoadAhead.segment_at(road, position) },
			)
		} else {
			[]
		}

	## The bend's animals and the pond's ducks of the world's segment at
	## `index`, the one before the rider's.
	sightings_behind : RoadAhead.RoadView, World.SegmentIndex -> List(BillboardSighting.Fate)
	sightings_behind = |road, index| {
		segment = index.segment_in(road.route_segments)
		bend_sightings(
			road,
			{ place: RoadAhead.place_behind(segment), segment },
		).concat(BillboardSighting.ducks_behind(road, segment))
	}

	## The ducks of `segment`, the one before the rider's, if it has a pond.
	ducks_behind : RoadAhead.RoadView, World.Segment -> List(BillboardSighting.Fate)
	ducks_behind = |road, segment| pond_sightings(
		road,
		{ place: RoadAhead.place_behind(segment), segment },
	)

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
