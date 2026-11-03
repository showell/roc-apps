## The ride's world: the route, nineteen segments of road, each built once
## from its line in `route`. A segment holds its scenery (trees, cows, pigs,
## a cat by a tree), how it turns into the next, where the rider commits to
## that turn, and the creature waiting at its end.
import Cat
import lib.DeviceMath
import Herd
import Pigs
import Scenery
import Trees
import lib.Trig

World :: [].{

	## One segment of the route as planned: its length and scenery, its turn
	## into the next in degrees (right is positive), what lives along it, and
	## the creature at its end.
	SegmentPlan : {
		length : F64,
		scheme : Scenery.Scheme,
		turn_deg : F64,
		cat : [WithCat, NoCat],
		pigs : [WithPigs, NoPigs],
		bull : [WithBull, NoBull],
		ending : [Continues, Terminates],
		creature : Scenery.Creature,
	}

	## One segment of road, built from its plan.
	Segment : {
		length : F64,
		width : F64,
		trees : List(Scenery.Tree),
		cows : List(Scenery.Critter),
		pigs : List(Scenery.Critter),
		pig_attention : [Distracting, Unnoticed],
		exit_angle : F64,
		exit_right : Bool,
		exit_to : I64,
		commit_along : F64,
		mid_tower : [MidTower, NoMidTower],
		cat : [Waits(Cat.Crossing), NoCat],
		ending : [Continues, Terminates],
		exit_creature : Scenery.Creature,
	}

	## A segment longer than this has a mast halfway along.
	mid_tower_min_length : F64
	mid_tower_min_length = 1000.0

	route : List(World.SegmentPlan)
	route = [
		{ length: 500.0, scheme: AllGreen, turn_deg: 50.0, cat: NoCat, pigs: NoPigs, bull: NoBull, ending: Continues, creature: Elephant },
		{ length: 320.0, scheme: AllGreen, turn_deg: -70.0, cat: WithCat, pigs: NoPigs, bull: NoBull, ending: Continues, creature: Elephant },
		{ length: 400.0, scheme: AllGreen, turn_deg: 20.0, cat: NoCat, pigs: WithPigs, bull: NoBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: YellowGreen, turn_deg: 20.0, cat: NoCat, pigs: NoPigs, bull: NoBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: -70.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Giraffe },
		{ length: 300.0, scheme: AllGreen, turn_deg: -70.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 1200.0, scheme: RedGreen, turn_deg: 80.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Rhino },
		{ length: 300.0, scheme: AllGreen, turn_deg: 15.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: -70.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 800.0, scheme: AllGreen, turn_deg: 15.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: 15.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: 15.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: RedGreen, turn_deg: 15.0, cat: WithCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: DuckPond },
		{ length: 400.0, scheme: AllGreen, turn_deg: -50.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: 50.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: RedGreen, turn_deg: -50.0, cat: NoCat, pigs: NoPigs, bull: WithBull, ending: Continues, creature: Zebra },
		{ length: 300.0, scheme: AllGreen, turn_deg: 50.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: AllGreen, turn_deg: -50.0, cat: NoCat, pigs: WithPigs, bull: WithBull, ending: Continues, creature: Elephant },
		{ length: 300.0, scheme: RedGreen, turn_deg: 0.0, cat: WithCat, pigs: WithPigs, bull: WithBull, ending: Terminates, creature: NoCreature },
	]

	## How many of the segments before `index` have pigs.
	pig_segments_before : I64 -> I64
	pig_segments_before = |index| route.take_first(I64.to_u64_wrap(index)).keep_if(has_pigs).len().to_i64_wrap()

	## Segment `index` of the route.
	segment_at : I64 -> World.Segment
	segment_at = |index| segment(route.get(I64.to_u64_wrap(index)) ?? crash "World.segment_at: the route has no segment there", index)

	build_world : List(World.Segment)
	build_world = route.map_with_index(|plan, index| segment(plan, U64.to_i64_wrap(index)))

	## The segments' length, end to end. It is summed from the last segment to
	## the first: a float sum's rounding depends on its order, and another
	## order can move a pixel.
	course_length : List(World.Segment) -> F64
	course_length = |segments| segments.fold_rev(0.0, |seg, sum| (seg.length + sum))

	## How far along the route a point `along` into segment `index` is.
	route_distance : List(World.Segment), I64, F64 -> F64
	route_distance = |segments, index, along| (course_length(segments.take_first(I64.to_u64_wrap(index))) + along)
}

## Whether a segment's plan has pigs along it.
has_pigs : World.SegmentPlan -> Bool
has_pigs = |plan|
	match plan.pigs {
		WithPigs => True
		NoPigs => False
	}

## A segment built from its plan, the route's `index`th.
segment : World.SegmentPlan, I64 -> World.Segment
segment = |plan, index| {
	angle = (DeviceMath.real_abs(plan.turn_deg) * Trig.deg)
	trees = Trees.fill_trees(plan.scheme, plan.length, Trees.tree_start_inset, 0, 0)
	# The first few segments with pigs show them as a herd, which draws the
	# rider's eye; after that they are a row.
	pig_attention =
		if has_pigs(plan) and (World.pig_segments_before((index + 1)) <= Pigs.pig_novelty_count) {
			Distracting
		} else {
			Unnoticed
		}
	{
		length: plan.length,
		width: Scenery.lane_width,
		trees,
		cows: Herd.fill_cows(plan.bull),
		pigs: match (plan.pigs, pig_attention) {
			(WithPigs, Distracting) => Pigs.fill_pig_herd(plan.length)
			(WithPigs, Unnoticed) => Pigs.fill_pig_row(plan.length)
			(NoPigs, Distracting) | (NoPigs, Unnoticed) => []
		},
		pig_attention,
		exit_angle: angle,
		exit_right: (plan.turn_deg >= 0.0),
		exit_to: match plan.ending {
			Continues => (index + 1)
			Terminates => index
		},
		commit_along: match plan.ending {
			Continues => (plan.length - ((Scenery.lane_width / 2.0) / Trig.r_tan(angle)))
			Terminates => plan.length
		},
		mid_tower: if (plan.length > World.mid_tower_min_length) MidTower else NoMidTower,
		cat: match plan.cat {
			WithCat => Waits(Cat.crossing({ lane_half_width: (Scenery.lane_width / 2.0), tree_offset: Trees.tree_road_offset, tree_along: nearest_tree_ahead(trees, Cat.cat_along) }))
			NoCat => NoCat
		},
		ending: plan.ending,
		exit_creature: match plan.ending {
			Continues => plan.creature
			Terminates => NoCreature
		},
	}
}

## The nearest tree along the road at or past `along`, on the right; `along`
## itself when there is none. A segment's cat waits by it.
nearest_tree_ahead : List(Scenery.Tree), F64 -> F64
nearest_tree_ahead = |trees, along| {
	nearest = trees.fold(
		NoTreeYet,
		|best, tree|
			if (tree.across > 0.0 and tree.along >= along) {
				match best {
					NearestAlong(nearest_along) => if (tree.along < nearest_along) NearestAlong(tree.along) else best
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
