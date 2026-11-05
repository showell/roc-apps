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

	## The road as the rider sees it: every segment of the world, the chain of
	## segments ahead (indexes into `world`, the rider's own first), and where
	## the rider is.
	Scene : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
		pose : Frame.Pose,
	}

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
	## before `rider_segment`, when there is one.
	sightings : CritterPlan.Scene, World.SegmentIndex -> List(Billboards.Sighting)
	sightings = |scene, rider_segment|
		match rider_segment.previous() {
			Previous(segment_behind) =>
				List.concat(
					CritterPlan.sightings_ahead(scene),
					CritterPlan.sightings_behind(scene, segment_behind),
				)
			AtRouteStart => CritterPlan.sightings_ahead(scene)
		}

	## The critters of every segment in the chain, nearest first.
	sightings_ahead : CritterPlan.Scene -> List(Billboards.Sighting)
	sightings_ahead = |scene|
		Frame.ChainPosition.all_in(scene.chain)
			.join_map(|position| CritterPlan.sightings_at(scene, position))

	## The critters of the segment at `position` in the chain: its farm
	## animals, its corner's animals, then its pond's ducks.
	sightings_at : CritterPlan.Scene, Frame.ChainPosition -> List(Billboards.Sighting)
	sightings_at = |scene, position|
		List.join([
			CritterPlan.farm_sightings(scene, position),
			CritterPlan.safari_sightings(scene, position),
			CritterPlan.duck_sightings(scene, position),
		])

	## The cows, then the pigs, of the segment at `position` in the chain.
	farm_sightings : CritterPlan.Scene, Frame.ChainPosition -> List(Billboards.Sighting)
	farm_sightings = |scene, position|
		if position.is_within_first(farm_reach) {
			segment = segment_at(scene, position)
			List.concat(segment.cows, segment.pigs)
				.map(|critter| sight_critter(scene, { place: InChain(position), critter }))
		} else {
			[]
		}

	## The animals at the corner that ends the segment at `position` in the
	## chain. The road's last segment ends with no corner.
	safari_sightings : CritterPlan.Scene, Frame.ChainPosition -> List(Billboards.Sighting)
	safari_sightings = |scene, position| {
		segment = segment_at(scene, position)
		match segment.ending {
			Continues(_) =>
				if position.is_within_first(safari_reach) {
					corner_sightings(scene, { place: InChain(position), segment })
				} else {
					[]
				}
			Terminates => []
		}
	}

	## The ducks of the segment at `position` in the chain, if it has a pond.
	duck_sightings : CritterPlan.Scene, Frame.ChainPosition -> List(Billboards.Sighting)
	duck_sightings = |scene, position|
		if position.is_within_first(safari_reach) {
			pond_sightings(
				scene,
				{ place: InChain(position), segment: segment_at(scene, position) },
			)
		} else {
			[]
		}

	## The corner's animals and the pond's ducks of the world's segment at
	## `index`, the one before the rider's.
	sightings_behind : CritterPlan.Scene, World.SegmentIndex -> List(Billboards.Sighting)
	sightings_behind = |scene, index| {
		segment = index.segment_in(scene.world)
		List.concat(
			corner_sightings(scene, { place: Frame.place_behind(segment), segment }),
			CritterPlan.ducks_behind(scene, segment),
		)
	}

	## The ducks of `segment`, the one before the rider's, if it has a pond.
	ducks_behind : CritterPlan.Scene, World.Segment -> List(Billboards.Sighting)
	ducks_behind = |scene, segment| pond_sightings(
		scene,
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

segment_at : CritterPlan.Scene, Frame.ChainPosition -> World.Segment
segment_at = |scene, position| position.index_in(scene.chain).segment_in(scene.world)

## A critter, placed through `place` on the road's map, as the rider sees it.
sight_critter : CritterPlan.Scene,
{
	place : Frame.SegmentPlace,
	critter : Scenery.Critter,
} -> Billboards.Sighting
sight_critter = |scene, { place, critter }|
	Billboards.sighting({
		at: Frame.rider_point_at(
			{
				world: scene.world,
				chain: scene.chain,
				pose: scene.pose,
			},
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

corner_sightings : CritterPlan.Scene,
{
	place : Frame.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
corner_sightings = |scene, { place, segment }|
	SafariCritter.corner_critters({
		creature: segment.exit_creature,
		corner_along: segment.length,
		turn: segment.exit_turn,
		lane_half_width,
	})
		.map(|critter| sight_critter(scene, { place, critter }))

## The ducks on `segment`'s pond, if it has one. A duck's place is measured
## from the corner at the segment's end.
pond_sightings : CritterPlan.Scene,
{
	place : Frame.SegmentPlace,
	segment : World.Segment,
} -> List(Billboards.Sighting)
pond_sightings = |scene, { place, segment }|
	if Scenery.is_pond(segment.exit_creature) {
		Pond.ducks.map(
			|duck|
				Billboards.sighting({
					at: Frame.rider_point_at(
						{
							world: scene.world,
							chain: scene.chain,
							pose: scene.pose,
						},
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
