## A segment is one straight stretch of the route's road, from one bend to the
## next: its length, its trees, its herds, what the rider meets on it, and how
## it ends. It is built once, from choices the route has already made, and this
## module answers the questions asked of one segment: where its herds stand,
## where the rider commits to its bend, whether a tower stands halfway along
## it, and what on it may catch the rider's eye.
import Across
import Along
import Angle
import Billboard
import BirdFlight
import CatCrossing
import CowHerd
import Distance
import Geom
import PigHerd
import Trees
import Wildlife

Segment := {
	length : Distance,
	trees : List(Trees.RoadsideTree),

	## The segment's herd of pigs, if it has one, and how the rider takes it.
	pigs : Segment.Pigs,

	## The segment's herd of cows, led by a bull or not.
	cows : { herd : CowHerd, bull : CowHerd.Bull },

	## What the rider meets on the road here, at most one thing, so that the
	## rider has one experience at a time. Most of the road is quiet, so that an
	## encounter stands out.
	encounter : [CatCrosses(CatCrossing), BirdHere(BirdFlight.Flight), QuietRoad],

	ending : Segment.Ending,
}.{

	## How the rider takes a herd, whatever its shape.
	PigInterest : [Unnoticed, Distracting]

	## A segment's herd of pigs, if it has one, and how the rider takes it.
	Pigs : [NoPigs, Herd({ herd : PigHerd, interest : Segment.PigInterest })]

	## What lives at the bend that ends a segment: nothing, a safari animal and
	## its baby, or a pond with its ducks.
	BendLife : [Quiet, Animal(Wildlife.Animal), DuckPond]

	## How a segment ends: by turning into the next, positive to the right,
	## with what lives at the bend, or by ending the route.
	Ending : [Bends({ turn : Angle.Turn, bend_life : Segment.BendLife }), RouteEnds]

	## How a segment ends, with its bend measured: the segment's `Ending`, its
	## turn joined by the segment's length.
	MeasuredEnding : [Bends({ bend : Geom.Bend, bend_life : Segment.BendLife }), RouteEnds]

	## What the route plans for the rider to meet on a segment, before the
	## segment's trees say where.
	PlannedEncounter : [CatCrosses, BirdHere, QuietRoad]

	## A segment built from the route's choices for it: its trees are planted
	## for its scheme, and what the rider meets on it is placed among them.
	from_choices : {
		length : Distance,
		scheme : Trees.Scheme,
		pigs : Segment.Pigs,
		cows : { herd : CowHerd, bull : CowHerd.Bull },
		encounter : Segment.PlannedEncounter,
		ending : Segment.Ending,
	} -> Segment
	from_choices = |choices| {
		trees = Trees.roadside_trees({ scheme: choices.scheme, length: choices.length })
		{
			length: choices.length,
			trees,
			pigs: choices.pigs,
			cows: choices.cows,
			encounter: match choices.encounter {
				CatCrosses => CatCrosses(
					CatCrossing.by_tree({
						road_half_width: Geom.road_half_width,
						tree: nearest_tree_ahead(trees, cat_along).road_point,
					}),
				)
				BirdHere =>
					match fifth_left_tree(trees) {
						Found(perch) =>
							match BirdFlight.flight_from(trees, perch) {
								Ok(flight) => BirdHere(flight)
								Err(NoTreeToFlyTo) =>
									crash "Segment.from_choices: a segment planned with a bird has a tree to fly to"
							}
						NoTree => crash "Segment.from_choices: a segment planned with a bird has a fifth tree on the left"
					}
				QuietRoad => QuietRoad
			},
			ending: choices.ending,
		}
	}

	## The pigs of `segment`'s herd.
	segment_pigs : Segment -> List(Geom.Placed(Billboard))
	segment_pigs = |segment|
		match segment.pigs {
			Herd({ herd, .. }) => herd.herd_pigs(pig_herd_along(segment.length))
			NoPigs => []
		}

	## The cows of `segment`'s herd, led by its bull if it has one.
	segment_cows : Segment -> List(Geom.Placed(Billboard))
	segment_cows = |segment|
		segment.cows.herd.herd_cows({ herd_along: cow_herd_along, bull: segment.cows.bull })

	## The pig of `segment`'s herd that stands out, and how the rider takes the
	## herd.
	segment_standout_pig : Segment -> [
		Standout({ pig : Geom.Placed(Billboard), interest : Segment.PigInterest }),
		NoPigs,
	]
	segment_standout_pig = |segment|
		match segment.pigs {
			Herd({ herd, interest }) =>
				Standout({ pig: herd.standout_pig(pig_herd_along(segment.length)), interest })
			NoPigs => NoPigs
		}

	## How `segment` ends: at the bend into the next segment, with what lives
	## there, or at the end of the route.
	segment_ending : Segment -> Segment.MeasuredEnding
	segment_ending = |segment|
		match segment.ending {
			Bends({ turn, bend_life }) => {
				bend = { segment_length: segment.length, turn }
				Bends({ bend, bend_life })
			}
			RouteEnds => RouteEnds
		}

	## The bend at the end of `segment`, which some segment follows.
	bend_out_of : Segment -> Geom.Bend
	bend_out_of = |segment|
		match segment.segment_ending() {
			Bends({ bend, .. }) => bend
			RouteEnds => crash "Segment.bend_out_of: nothing follows the route's last segment"
		}

	## How far along `segment` a rider on the middle of the road comes onto the
	## next segment's road, or the end of the route.
	commit_along : Segment -> Along
	commit_along = |segment|
		match segment.segment_ending() {
			Bends({ bend, .. }) => Geom.commit_along(bend)
			RouteEnds => Along.at(segment.length)
		}

	## Whether `segment` has a tower halfway along.
	has_mid_tower : Segment -> Bool
	has_mid_tower = |segment| segment.length > mid_tower_min_length

	## Whether a segment has a cat waiting by the road.
	has_cat : Segment -> Bool
	has_cat = |segment|
		match segment.encounter {
			CatCrosses(_) => True
			BirdHere(_) | QuietRoad => False
		}

	## Whether a segment has a bird in it.
	has_bird : Segment -> Bool
	has_bird = |segment|
		match segment.encounter {
			BirdHere(_) => True
			CatCrosses(_) | QuietRoad => False
		}

	## Whether a segment's pigs draw the rider's eye.
	is_distracting : Segment -> Bool
	is_distracting = |segment|
		match segment.pigs {
			Herd({ interest: Distracting, .. }) => True
			Herd({ interest: Unnoticed, .. }) | NoPigs => False
		}
}

## A segment longer than this has a tower halfway along.
mid_tower_min_length : Distance
mid_tower_min_length = Distance.metres(1000.0)

## How far before the end of its segment a herd of pigs stands.
pig_distance_before_end : Distance
pig_distance_before_end = Distance.metres(60.0)

## Where the cow herd stands along its segment: the bull's place, with the
## cows behind him.
cow_herd_along : Along
cow_herd_along = Along.metres(24.0)

## Where a segment's cat starts looking for its tree: it waits by the first
## tree on the right from here on.
cat_along : Along
cat_along = Along.metres(105.0)

## The tree a segment's bird starts on, the fifth with a negative `across`.
## Those are on the left, and an unflipped still's beak points toward +x, so
## from there the bird faces the road.
fifth_left_tree : List(Trees.RoadsideTree) -> [Found(Trees.RoadsideTree), NoTree]
fifth_left_tree = |trees|
	match trees.keep_if(|tree| tree.road_point.across < Across.middle).drop_first(4).first() {
		Ok(tree) => Found(tree)
		Err(ListWasEmpty) => NoTree
	}

## The nearest tree on the right at or past `along`, which a segment's cat waits
## by. A segment's trees are planted in order along the road, so the first found
## is the nearest.
nearest_tree_ahead : List(Trees.RoadsideTree), Along -> Trees.RoadsideTree
nearest_tree_ahead = |trees, along|
	trees.find_first(
		|{ road_point, .. }| road_point.across > Across.middle and road_point.along >= along,
	)
		?? crash "Segment.nearest_tree_ahead: a segment with a cat is long enough to have its tree"

## Where a herd of pigs stands on a segment `length` long.
pig_herd_along : Distance -> Along
pig_herd_along = |length| Along.at(length.minus(pig_distance_before_end))

## The trees of a gold segment 300 m long, where each pair on the right has one
## tree near the road and one far from it.
gold_trees : List(Trees.RoadsideTree)
gold_trees = Trees.roadside_trees({ scheme: GoldGreen, length: Distance.metres(300.0) })

# On a gold segment the pairs differ. The tree found is whichever comes next, near
# the road or far from it, and never one on the left.
expect nearest_tree_ahead(gold_trees, cat_along).road_point.across == Across.metres(3.5)
expect nearest_tree_ahead(gold_trees, Along.metres(90.0)).road_point.across == Across.metres(8.0)
expect nearest_tree_ahead(gold_trees, Along.metres(90.0)).road_point.along == Along.metres(96.0)
expect nearest_tree_ahead(gold_trees, Along.metres(96.0)).road_point.along == Along.metres(96.0)
expect nearest_tree_ahead(gold_trees, Along.metres(96.5)).road_point.along == Along.metres(126.0)

## A tree at `along` and `across` metres, of whatever kind a gold segment starts
## with.
tree_at : F64, F64 -> Trees.RoadsideTree
tree_at = |along, across| {
	..(gold_trees.first() ?? crash "Segment.tree_at: a gold segment has trees"),
	road_point: { along: Along.metres(along), across: Across.metres(across) },
}

## A left and a right tree at each of `alongs`.
pairs_at : List(F64) -> List(Trees.RoadsideTree)
pairs_at = |alongs| alongs.join_map(|along| [tree_at(along, -6.0), tree_at(along, 6.0)])

## How far along the fifth left tree of `trees` is, if there is one.
fifth_along : List(Trees.RoadsideTree) -> Try(F64, [NoTree])
fifth_along = |trees|
	match fifth_left_tree(trees) {
		Found(tree) => Ok(tree.road_point.along.to_metres())
		NoTree => Err(NoTree)
	}

# Only trees on the left count toward the fifth, and a segment too short for five
# of them has none.
expect fifth_along([]) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0])) == Err(NoTree)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0])) == Ok(50.0)
expect fifth_along(pairs_at([10.0, 20.0, 30.0, 40.0, 50.0, 60.0])) == Ok(50.0)
expect fifth_along([50.0, 60.0, 70.0, 80.0, 90.0].map(|along| tree_at(along, 6.0))) == Err(NoTree)
expect {
	short_trees = Trees.roadside_trees({ scheme: RedGreen, length: Distance.metres(50.0) })
	fifth_along(short_trees) == Err(NoTree)
}
