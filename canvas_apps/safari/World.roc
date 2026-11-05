## The ride's world: the route, a line of road segments, each built once from
## its entry in `route`. A segment holds its scenery (trees, cows, pigs, a cat
## by a tree), how it turns into the next, where the rider commits to that
## turn, and the creature waiting at its end.
import Across
import Along
import Angle
import BirdFlight
import Cat
import Distance
import Herd
import Pigs
import Scenery
import Trees
import lib.Trig

World :: [].{

	## A segment's place in the route, counted from 0. It says where a segment
	## is in the route, where a Frame.ChainPosition says how far ahead of the
	## rider it is.
	SegmentIndex :: U32.{

		number : U32 -> World.SegmentIndex
		number = |n| World.SegmentIndex.(n)

		to_u32 : World.SegmentIndex -> U32
		to_u32 = |World.SegmentIndex.(n)| n

		to_i64 : World.SegmentIndex -> I64
		to_i64 = |World.SegmentIndex.(n)| n.to_i64()

		## The route's first segment.
		first : World.SegmentIndex
		first = World.SegmentIndex.(0)

		next : World.SegmentIndex -> World.SegmentIndex
		next = |World.SegmentIndex.(n)| World.SegmentIndex.(n + 1)

		## The segment before this one, unless this is the first.
		previous : World.SegmentIndex -> [Previous(World.SegmentIndex), AtRouteStart]
		previous = |World.SegmentIndex.(n)|
			if n == 0 {
				AtRouteStart
			} else {
				Previous(World.SegmentIndex.(n - 1))
			}

		## How many segments come before this one.
		count_before : World.SegmentIndex -> U64
		count_before = |World.SegmentIndex.(n)| n.to_u64()

		## The segment of `world` at this index.
		segment_in : World.SegmentIndex, List(World.Segment) -> World.Segment
		segment_in = |index, world|
			world.get(index.count_before())
				?? crash "World.SegmentIndex.segment_in: the world has no segment there"

		is_eq : _
	}

	## One segment of the route as planned: its length and scenery, its turn
	## into the next (right is positive), what lives along it, and
	## the creature at its end.
	SegmentPlan : {
		length : Distance,
		scheme : Scenery.Scheme,
		turn : Angle.Turn,
		crossing : [CatCrosses, BirdCrosses, QuietRoad],
		pigs : Pigs.PigPresence,
		bull : [WithBull, NoBull],
		ending : [Continues, Terminates],
		creature : Scenery.Creature,
	}

	## One segment of road, built from its plan.
	Segment : {
		length : Distance,
		trees : List(Scenery.Tree),
		cows : List(Scenery.Critter),
		pigs : List(Scenery.Critter),
		pig_attention : Pigs.PigAttention,

		## The turn into the next segment: positive to the right, negative to
		## the left.
		exit_turn : Angle.Turn,
		commit_along : Along,
		mid_tower : [MidTower, NoMidTower],

		## What crosses the road here, at most one thing, so that the rider has
		## one experience at a time. Most of the road is quiet, so that a crossing
		## stands out.
		crossing : [
			CatCrosses(Cat.Crossing),
			BirdFlies(BirdFlight.Route),
			QuietRoad,
		],
		ending : [Continues({ next : World.SegmentIndex }), Terminates],
		exit_creature : Scenery.Creature,
	}

	## A segment longer than this has a mast halfway along.
	mid_tower_min_length : Distance
	mid_tower_min_length = Distance.metres(1000.0)

	route : List(World.SegmentPlan)
	route = [
		{
			length: Distance.metres(500.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: BirdCrosses,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(320.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(400.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(20.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: NoBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: YellowGreen,
			turn: Angle.Turn.degrees(20.0),
			crossing: CatCrosses,
			pigs: NoPigs,
			bull: NoBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Giraffe,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: BirdCrosses,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(1200.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(80.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Rhino,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-70.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(800.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: CatCrosses,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(15.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: DuckPond,
		},
		{
			length: Distance.metres(400.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: BirdCrosses,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: NoPigs,
			bull: WithBull,
			ending: Continues,
			creature: Zebra,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: AllGreen,
			turn: Angle.Turn.degrees(-50.0),
			crossing: QuietRoad,
			pigs: WithPigs,
			bull: WithBull,
			ending: Continues,
			creature: Elephant,
		},
		{
			length: Distance.metres(300.0),
			scheme: RedGreen,
			turn: Angle.Turn.degrees(0.0),
			crossing: CatCrosses,
			pigs: WithPigs,
			bull: WithBull,
			ending: Terminates,
			creature: NoCreature,
		},
	]

	## How many of the segments up to and including `index` have pigs.
	pig_segments_through : World.SegmentIndex -> U32
	pig_segments_through = |index|
		route
			.take_first(index.count_before() + 1)
			.count_if(|plan| Pigs.has_pigs(plan.pigs))
			.to_u32_wrap()

	## Segment `number` of the route, counting from 0.
	route_segment : U32 -> World.Segment
	route_segment = |number| {
		index = World.SegmentIndex.number(number)
		plan = route.get(index.count_before())
			?? crash "World.route_segment: the route has no segment there"
		built_segment(plan, index)
	}

	## Every segment of the route, in order.
	segments : List(World.Segment)
	segments = route.map_with_index(
		|plan, at| built_segment(plan, World.SegmentIndex.number(at.to_u32_wrap())),
	)

	## The segments' length, end to end. It is summed from the last segment to
	## the first: a float sum's rounding depends on its order, and another
	## order can move a pixel.
	route_length : List(World.Segment) -> Distance
	route_length = |world| world.fold_rev(Distance.zero, |segment, sum| segment.length.plus(sum))

	## How far along the route the point at `along` on the segment at `index`
	## is.
	distance_along_route : List(World.Segment),
	{
		index : World.SegmentIndex,
		along : Along,
	} -> Distance
	distance_along_route = |world, { index, along }|
		route_length(world.take_first(index.count_before())).plus(along.from_start())
}

## The segment at `index` of the route, built from its plan.
built_segment : World.SegmentPlan, World.SegmentIndex -> World.Segment
built_segment = |plan, index| {
	trees = Trees.plant({ scheme: plan.scheme, length: plan.length })
	pig_attention = Pigs.attention_of({
		presence: plan.pigs,
		pig_segments_so_far: World.pig_segments_through(index),
	})
	{
		length: plan.length,
		trees,
		cows: Herd.fill_cows(plan.bull),
		pigs: Pigs.pigs_along({
			presence: plan.pigs,
			attention: pig_attention,
			length: plan.length,
		}),
		pig_attention,
		exit_turn: plan.turn,
		commit_along: match plan.ending {
			Continues => {
				exit_tan = Trig.r_tan(plan.turn.abs().to_radians())
				Along.at(plan.length.minus(Scenery.lane_half_width.divided_by(exit_tan)))
			}
			Terminates => Along.at(plan.length)
		},
		mid_tower: if plan.length > World.mid_tower_min_length {
			MidTower
		} else {
			NoMidTower
		},
		crossing: match plan.crossing {
			CatCrosses => CatCrosses(
				Cat.crossing({
					lane_half_width: Scenery.lane_half_width,
					tree_offset: Trees.tree_road_offset,
					tree_along: nearest_tree_ahead(trees, Cat.cat_along),
				}),
			)
			BirdCrosses => BirdFlight.crossing_among(trees)
			QuietRoad => QuietRoad
		},
		ending: match plan.ending {
			Continues => Continues({ next: index.next() })
			Terminates => Terminates
		},
		exit_creature: match plan.ending {
			Continues => plan.creature
			Terminates => NoCreature
		},
	}
}

## The nearest tree along the road at or past `along`, on the right; `along`
## itself when there is none. A segment's cat waits by it.
nearest_tree_ahead : List(Scenery.Tree), Along -> Along
nearest_tree_ahead = |trees, along| {
	nearest = trees.fold(
		NoTreeYet,
		|best, tree|
			if tree.across > Across.middle and tree.along >= along {
				match best {
					NearestAlong(nearest_along) =>
						if tree.along < nearest_along {
							NearestAlong(tree.along)
						} else {
							best
						}
					NoTreeYet => NearestAlong(tree.along)
				}
			} else {
				best
			},
	)
	match nearest {
		NearestAlong(nearest_along) => nearest_along
		NoTreeYet => along
	}
}
