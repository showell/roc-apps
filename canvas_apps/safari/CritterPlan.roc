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
	Scene : { world : List(World.Segment), chain : List(I64), pose : Frame.Pose }

	## Farm animals are sighted on this many segments of the chain.
	farm_reach : I64
	farm_reach = 3

	## Safari animals and ducks are sighted on this many.
	safari_reach : I64
	safari_reach = 5

	## No more critters than this are drawn in a frame.
	max_vis_critters : I64
	max_vis_critters = 320

	## Every critter ahead, nearest segment first, then those of the segment
	## before `rider_segment`, when there is one.
	sightings : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	sightings = |scene, rider_segment|
		if (rider_segment > 0) {
			List.concat(CritterPlan.sightings_ahead(scene), CritterPlan.sightings_behind(scene, (rider_segment - 1)))
		} else {
			CritterPlan.sightings_ahead(scene)
		}

	## The critters of every segment in the chain, nearest first.
	sightings_ahead : CritterPlan.Scene -> List(Billboards.Sighting)
	sightings_ahead = |scene|
		List.from_iter(I64.until(0, scene.chain.len().to_i64_wrap()))
			.join_map(|position| CritterPlan.sightings_at(scene, position))

	## The critters of the segment at `position` in the chain: its farm
	## animals, its corner's animals, then its pond's ducks.
	sightings_at : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	sightings_at = |scene, position|
		List.join([
			CritterPlan.farm_sightings(scene, position),
			CritterPlan.safari_sightings(scene, position),
			CritterPlan.duck_sightings(scene, position),
		])

	## The cows, then the pigs, of the segment at `position` in the chain.
	farm_sightings : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	farm_sightings = |scene, position|
		if (position >= farm_reach) {
			[]
		} else {
			segment = segment_at(scene, position)
			List.concat(segment.cows, segment.pigs)
				.map(|critter| sight_critter(scene, { mapper: Frame.chain_map(position), critter }))
		}

	## The animals at the corner that ends the segment at `position` in the
	## chain. The road's last segment ends with no corner.
	safari_sightings : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	safari_sightings = |scene, position| {
		segment = segment_at(scene, position)
		match segment.ending {
			Continues(_) =>
				if (position >= safari_reach) {
					[]
				} else {
					corner_sightings(scene, { mapper: Frame.chain_map(position), segment })
				}
			Terminates => []
		}
	}

	## The ducks of the segment at `position` in the chain, if it has a pond.
	duck_sightings : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	duck_sightings = |scene, position|
		if (position >= safari_reach) {
			[]
		} else {
			pond_sightings(scene, { mapper: Frame.chain_map(position), segment: segment_at(scene, position) })
		}

	## The corner's animals and the pond's ducks of the world's segment at
	## `index`, the one before the rider's.
	sightings_behind : CritterPlan.Scene, I64 -> List(Billboards.Sighting)
	sightings_behind = |scene, index| {
		segment = scene.world.get(index.to_u64_wrap()) ?? crash "CritterPlan.sightings_behind: the rider's segment has one before it"
		List.concat(
			corner_sightings(scene, { mapper: Frame.prev_map(segment), segment }),
			CritterPlan.ducks_behind(scene, segment),
		)
	}

	## The ducks of `segment`, the one before the rider's, if it has a pond.
	ducks_behind : CritterPlan.Scene, World.Segment -> List(Billboards.Sighting)
	ducks_behind = |scene, segment| pond_sightings(scene, { mapper: Frame.prev_map(segment), segment })

	## The depth-sort keys of the critters to draw, each naming its billboard
	## by its place in `billboards`.
	cow_items : List(Billboards.Billboard) -> List(DepthSort.DepthKey)
	cow_items = |billboards| billboards.map_with_index(|billboard, i| { fwd: billboard.forward, kind: KCow, i: i.to_i64_wrap() })
}

lane_half_width : F64
lane_half_width = (Scenery.lane_width / 2.0)

segment_at : CritterPlan.Scene, I64 -> World.Segment
segment_at = |scene, position| {
	index = scene.chain.get(position.to_u64_wrap()) ?? crash "CritterPlan.segment_at: a position is in the chain"
	scene.world.get(index.to_u64_wrap()) ?? crash "CritterPlan.segment_at: the chain holds indexes into the world"
}

## A critter, placed through `mapper` on the road's map, as the rider sees it.
sight_critter : CritterPlan.Scene, { mapper : Frame.Mapper, critter : Scenery.Critter } -> Billboards.Sighting
sight_critter = |scene, { mapper, critter }|
	Billboards.sighting({
		at: Frame.map_pt(scene.world, scene.chain, scene.pose, mapper, critter.along, (critter.across + lane_half_width)),
		height: critter.height,
		codepoint: critter.codepoint,
		facing: facing_of(critter.face_right),
	})

corner_sightings : CritterPlan.Scene, { mapper : Frame.Mapper, segment : World.Segment } -> List(Billboards.Sighting)
corner_sightings = |scene, { mapper, segment }|
	SafariCritter.corner_critters({
		creature: segment.exit_creature,
		corner_along: segment.length,
		turn: if segment.exit_right TurnsRight else TurnsLeft,
		lane_half_width,
	})
		.map(|critter| sight_critter(scene, { mapper, critter }))

## The ducks on `segment`'s pond, if it has one. A duck's place is measured
## from the corner at the segment's end.
pond_sightings : CritterPlan.Scene, { mapper : Frame.Mapper, segment : World.Segment } -> List(Billboards.Sighting)
pond_sightings = |scene, { mapper, segment }|
	if Scenery.is_pond(segment.exit_creature) {
		Pond.ducks.map(
			|duck|
				Billboards.sighting({
					at: Frame.map_pt(scene.world, scene.chain, scene.pose, mapper, (segment.length + duck.p.cv), duck.p.cu),
					height: Pond.duck_height,
					codepoint: Pond.duck_codepoint,
					facing: facing_of(duck.face_right),
				}),
		)
	} else {
		[]
	}

facing_of : Bool -> Billboards.Facing
facing_of = |face_right| if face_right FacesRight else FacesLeft
