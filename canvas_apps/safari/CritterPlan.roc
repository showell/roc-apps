## CritterPlan sights every critter on the road ahead from where the rider
## is: the farm animals of the nearest segments, the safari animal and its
## baby at each corner, and the ducks on each pond. The critters of the
## segment before the rider's are sighted too, so the corner the rider has
## just turned keeps its animals.
import Billboards
import DepthSort
import Frame
import Pond
import SafariCritter
import Scenery
import World

CritterPlan :: [].{

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
	sightings : Frame.RoadView -> List(Billboards.Sighting)
	sightings = |road|
		match Frame.segment_behind(road) {
			Previous(segment_behind) =>
				CritterPlan.sightings_ahead(road).concat(
					CritterPlan.sightings_behind(
						road,
						segment_behind,
					),
				)
			AtRouteStart => CritterPlan.sightings_ahead(road)
		}

	## The critters of every segment in the chain, nearest first.
	sightings_ahead : Frame.RoadView -> List(Billboards.Sighting)
	sightings_ahead = |road|
		Frame.ChainPosition.all_in(road.chain)
			.join_map(|position| CritterPlan.sightings_at(road, position))

	## The critters of the segment at `position` in the chain: its farm
	## animals, its corner's animals, then its pond's ducks.
	sightings_at : Frame.RoadView, Frame.ChainPosition -> List(Billboards.Sighting)
	sightings_at = |road, position|
		[
			CritterPlan.farm_sightings(road, position),
			CritterPlan.safari_sightings(road, position),
			CritterPlan.duck_sightings(road, position),
		].join()

	## The cows, then the pigs, of the segment at `position` in the chain.
	farm_sightings : Frame.RoadView, Frame.ChainPosition -> List(Billboards.Sighting)
	farm_sightings = |road, position|
		if position.is_within_first(farm_reach) {
			segment = segment_at(road, position)
			segment.cows.concat(segment.pigs)
				.map(|critter| sight_critter(road, { place: InChain(position), critter }))
		} else {
			[]
		}

	## The animals at the corner that ends the segment at `position` in the
	## chain. The road's last segment ends with no corner.
	safari_sightings : Frame.RoadView, Frame.ChainPosition -> List(Billboards.Sighting)
	safari_sightings = |road, position| {
		segment = segment_at(road, position)
		match segment.ending {
			Continues(_) =>
				if position.is_within_first(safari_reach) {
					corner_sightings(road, { place: InChain(position), segment })
				} else {
					[]
				}
			Terminates => []
		}
	}

	## The ducks of the segment at `position` in the chain, if it has a pond.
	duck_sightings : Frame.RoadView, Frame.ChainPosition -> List(Billboards.Sighting)
	duck_sightings = |road, position|
		if position.is_within_first(safari_reach) {
			pond_sightings(
				road,
				{ place: InChain(position), segment: segment_at(road, position) },
			)
		} else {
			[]
		}

	## The corner's animals and the pond's ducks of the world's segment at
	## `index`, the one before the rider's.
	sightings_behind : Frame.RoadView, World.SegmentIndex -> List(Billboards.Sighting)
	sightings_behind = |road, index| {
		segment = index.segment_in(road.world)
		corner_sightings(
			road,
			{ place: Frame.place_behind(segment), segment },
		).concat(CritterPlan.ducks_behind(road, segment))
	}

	## The ducks of `segment`, the one before the rider's, if it has a pond.
	ducks_behind : Frame.RoadView, World.Segment -> List(Billboards.Sighting)
	ducks_behind = |road, segment| pond_sightings(
		road,
		{ place: Frame.place_behind(segment), segment },
	)

	## The depth-sort keys of the critters to draw, each naming its billboard
	## by its place in `billboards`.
	cow_items : List(Billboards.Billboard) -> List(DepthSort.DepthKey)
	cow_items = |billboards|
		billboards.map_with_index(
			|billboard, i| {
				forward: billboard.forward,
				subject: Critter(i.to_u32_wrap()),
			},
		)
}

lane_half_width : F64
lane_half_width = (Scenery.lane_width / 2.0)

segment_at : Frame.RoadView, Frame.ChainPosition -> World.Segment
segment_at = |road, position| position.index_in(road.chain).segment_in(road.world)

## A critter, placed through `place` on the road's map, as the rider sees it.
sight_critter : Frame.RoadView,
{
	place : Frame.SegmentPlace,
	critter : Scenery.Critter,
} -> Billboards.Sighting
sight_critter = |road, { place, critter }|
	Billboards.sighting({
		at: Frame.rider_point_at(
			road,
			{
				place,
				along: critter.along,
				across: (critter.across + lane_half_width),
			},
		),
		height: critter.height,
		codepoint: critter.codepoint,
		facing: if (critter.face_right) FacesRight else FacesLeft,
	})

corner_sightings : Frame.RoadView,
{
	place : Frame.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
corner_sightings = |road, { place, segment }|
	SafariCritter.corner_critters({
		creature: segment.exit_creature,
		corner_along: segment.length,
		turn: segment.exit_turn,
		lane_half_width,
	})
		.map(|critter| sight_critter(road, { place, critter }))

## The ducks on `segment`'s pond, if it has one. A duck's place is measured
## from the corner at the segment's end.
pond_sightings : Frame.RoadView,
{
	place : Frame.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
pond_sightings = |road, { place, segment }|
	if Scenery.is_pond(segment.exit_creature) {
		Pond.ducks.map(
			|duck|
				Billboards.sighting({
					at: Frame.rider_point_at(
						road,
						{
							place,
							along: (segment.length + duck.at.along),
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
