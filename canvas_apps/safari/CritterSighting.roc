## CritterSighting sights every critter on the road ahead from where the rider
## is: the farm animals of the nearest segments, the safari animal and its
## baby at each bend, and the ducks on each pond. The critters of the
## segment before the rider's are sighted too, so the bend the rider has
## just turned keeps its animals.
import Along
import Billboards
import DepthSort
import Chain
import Pond
import SafariCritter
import Scenery
import World

CritterSighting :: [].{

	## Farm animals are sighted on this many segments of the chain.
	farm_reach : U32
	farm_reach = 3

	## Safari animals and ducks are sighted on this many.
	safari_reach : U32
	safari_reach = 5

	## No more critters than this are drawn in a frame.
	max_vis_critters : I64
	max_vis_critters = 320

	## Every critter ahead, nearest segment first, then those of the segment
	## before the rider's, when there is one.
	in_view : Chain.RoadView -> List(Billboards.Sighting)
	in_view = |road|
		match Chain.segment_behind(road) {
			Previous(segment_behind) =>
				CritterSighting.sightings_ahead(road).concat(
					CritterSighting.sightings_behind(road, segment_behind),
				)
			AtRouteStart => CritterSighting.sightings_ahead(road)
		}

	## The critters of every segment in the chain, nearest first.
	sightings_ahead : Chain.RoadView -> List(Billboards.Sighting)
	sightings_ahead = |road|
		Chain.Position.all_in(road.chain)
			.join_map(|position| CritterSighting.sightings_at(road, position))

	## The critters of the segment at `position` in the chain: its farm
	## animals, its bend's animals, then its pond's ducks.
	sightings_at : Chain.RoadView, Chain.Position -> List(Billboards.Sighting)
	sightings_at = |road, position|
		[
			CritterSighting.farm_sightings(road, position),
			CritterSighting.safari_sightings(road, position),
			CritterSighting.duck_sightings(road, position),
		].join()

	## The cows, then the pigs, of the segment at `position` in the chain.
	farm_sightings : Chain.RoadView, Chain.Position -> List(Billboards.Sighting)
	farm_sightings = |road, position|
		if position.is_within_first(farm_reach) {
			segment = segment_at(road, position)
			segment.cows.concat(segment.pigs)
				.map(|critter| sight_critter(road, { place: InChain(position), critter }))
		} else {
			[]
		}

	## The animals at the bend that ends the segment at `position` in the
	## chain. The road's last segment ends with no bend.
	safari_sightings : Chain.RoadView, Chain.Position -> List(Billboards.Sighting)
	safari_sightings = |road, position| {
		segment = segment_at(road, position)
		match segment.ending {
			Continues(_) =>
				if position.is_within_first(safari_reach) {
					bend_sightings(road, { place: InChain(position), segment })
				} else {
					[]
				}
			Terminates => []
		}
	}

	## The ducks of the segment at `position` in the chain, if it has a pond.
	duck_sightings : Chain.RoadView, Chain.Position -> List(Billboards.Sighting)
	duck_sightings = |road, position|
		if position.is_within_first(safari_reach) {
			pond_sightings(road, { place: InChain(position), segment: segment_at(road, position) })
		} else {
			[]
		}

	## The bend's animals and the pond's ducks of the world's segment at
	## `index`, the one before the rider's.
	sightings_behind : Chain.RoadView, World.SegmentIndex -> List(Billboards.Sighting)
	sightings_behind = |road, index| {
		segment = index.segment_in(road.world)
		bend_sightings(
			road,
			{ place: Chain.place_behind(segment), segment },
		).concat(CritterSighting.ducks_behind(road, segment))
	}

	## The ducks of `segment`, the one before the rider's, if it has a pond.
	ducks_behind : Chain.RoadView, World.Segment -> List(Billboards.Sighting)
	ducks_behind = |road, segment| pond_sightings(
		road,
		{ place: Chain.place_behind(segment), segment },
	)

	## The depth-sort keys of the critters to draw, each naming its billboard
	## by its place in `billboards`.
	depth_keys : List(Billboards.Billboard) -> List(DepthSort.DepthKey)
	depth_keys = |billboards|
		billboards.map_with_index(
			|billboard, i| { forward: billboard.forward, subject: Critter(i.to_u32_wrap()) },
		)
}

segment_at : Chain.RoadView, Chain.Position -> World.Segment
segment_at = |road, position| position.index_in(road.chain).segment_in(road.world)

## A critter, placed through `place` on the road's map, as the rider sees it.
sight_critter : Chain.RoadView,
{
	place : Chain.SegmentPlace,
	critter : Scenery.Critter,
} -> Billboards.Sighting
sight_critter = |road, { place, critter }|
	Billboards.sighting({
		at: Chain.rider_point_at(road, { place, along: critter.along, across: critter.across }),
		height: critter.height,
		codepoint: critter.codepoint,
		facing: if critter.face_right {
			FacesRight
		} else {
			FacesLeft
		},
	})

bend_sightings : Chain.RoadView,
{
	place : Chain.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
bend_sightings = |road, { place, segment }|
	SafariCritter.bend_critters({
		creature: segment.exit_creature,
		bend_along: Along.at(segment.length),
		turn: segment.exit_turn,
		lane_half_width: Scenery.lane_half_width,
	})
		.map(|critter| sight_critter(road, { place, critter }))

## The ducks on `segment`'s pond, if it has one. A duck's place is measured
## from the bend at the segment's end.
pond_sightings : Chain.RoadView,
{
	place : Chain.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
pond_sightings = |road, { place, segment }|
	if Scenery.is_pond(segment.exit_creature) {
		Pond.ducks.map(
			|duck|
				Billboards.sighting({
					at: Chain.rider_point_at(
						road,
						{
							place,
							along: Along.at(segment.length).plus(duck.at.along.from_start()),
							across: duck.at.across,
						},
					),
					height: Pond.duck_height,
					codepoint: Pond.duck_codepoint,
					facing: duck.facing,
				}),
		)
	} else {
		[]
	}

expect CritterSighting.farm_reach.to_i64() == 3
expect CritterSighting.safari_reach.to_i64() == 5
