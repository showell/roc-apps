## A segment is one straight stretch of the route's road, from one bend to the
## next: its length, its trees, its herds, what crosses it, and how it ends. It is
## built once, from choices the route has already made, and this module answers
## the questions asked of one segment: where its herds stand, where the rider
## commits to its bend, and whether a tower stands halfway along it.
import Across
import Along
import Angle
import Billboard
import BirdFlight
import Cat
import CowHerd
import Distance
import Geom
import PigHerd
import Scenery
import Trees

Segment := {
	length : Distance,
	trees : List(Trees.RoadsideTree),

	## The segment's herd of pigs, if it has one, and how the rider takes it.
	pigs : [NoPigs, Herd({ herd : PigHerd, interest : Segment.PigInterest })],

	## The segment's herd of cows, led by a bull or not.
	cows : { herd : CowHerd, bull : [WithBull, NoBull] },

	## What crosses the road here, at most one thing, so that the rider has
	## one experience at a time. Most of the road is quiet, so that a crossing
	## stands out.
	crossing : [CatCrosses(Cat.Crossing), BirdHere(BirdFlight.Habit), QuietRoad],

	## How the segment ends: by turning into the next, positive to the
	## right, with what lives at the bend, or by ending the route.
	ending : [Bends({ turn : Angle.Turn, bend_life : Scenery.BendLife }), RouteEnds],
}.{

	## How the rider takes a herd, whatever its shape.
	PigInterest : [Unnoticed, Distracting]

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

	## A segment built from the route's choices for it: its trees are planted
	## for its scheme, and what crosses it is placed among them.
	from_choices : {
		length : Distance,
		scheme : Scenery.Scheme,
		pigs : [NoPigs, Herd({ herd : PigHerd, interest : Segment.PigInterest })],
		cows : { herd : CowHerd, bull : [WithBull, NoBull] },
		crossing : [CatCrosses, BirdHere, QuietRoad],
		ending : [Bends({ turn : Angle.Turn, bend_life : Scenery.BendLife }), RouteEnds],
	} -> Segment
	from_choices = |choices| {
		trees = Trees.roadside_trees({ scheme: choices.scheme, length: choices.length })
		{
			length: choices.length,
			trees,
			pigs: choices.pigs,
			cows: choices.cows,
			crossing: match choices.crossing {
				CatCrosses => CatCrosses(
					Cat.crossing({
						road_half_width: Geom.road_half_width,
						tree: nearest_tree_ahead(trees, Cat.cat_along),
					}),
				)
				BirdHere => BirdFlight.crossing_among(trees)
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
		segment.cows.herd.herd_cows({ herd_along: Segment.cow_herd_along, bull: segment.cows.bull })

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

	## The bend at the end of `segment`, which some segment follows.
	bend_out_of : Segment -> Geom.Bend
	bend_out_of = |segment|
		match segment.ending {
			Bends({ turn, .. }) => { segment_length: segment.length, turn }
			RouteEnds => crash "Segment.bend_out_of: nothing follows the route's last segment"
		}

	## How far along `segment` a rider on the middle of the road comes onto the
	## next segment's road, or the end of the route.
	commit_along : Segment -> Along
	commit_along = |segment|
		match segment.ending {
			Bends({ turn, .. }) => Geom.commit_along({ segment_length: segment.length, turn })
			RouteEnds => Along.at(segment.length)
		}

	## Whether `segment` has a tower halfway along.
	has_mid_tower : Segment -> Bool
	has_mid_tower = |segment| segment.length > Segment.mid_tower_min_length
}

## The nearest tree on the right at or past `along`, which a segment's cat waits
## by. A segment's trees are planted in order along the road, so the first found
## is the nearest.
nearest_tree_ahead : List(Trees.RoadsideTree), Along -> Trees.RoadsideTree
nearest_tree_ahead = |trees, along|
	trees.find_first(|tree| tree.across > Across.middle and tree.along >= along)
		?? crash "Segment.nearest_tree_ahead: a segment with a cat is long enough to have its tree"

## Where a herd of pigs stands on a segment `length` long.
pig_herd_along : Distance -> Along
pig_herd_along = |length| Along.at(length.minus(Segment.pig_distance_before_end))

## The trees of a gold segment 300 m long, as the route's fourth is.
gold_trees : List(Trees.RoadsideTree)
gold_trees = Trees.roadside_trees({ scheme: GoldGreen, length: Distance.metres(300.0) })

# On a gold segment the pairs differ. The tree found is whichever comes next, near
# the road or far from it, and never one on the left.
expect nearest_tree_ahead(gold_trees, Cat.cat_along).across == Across.metres(3.5)
expect nearest_tree_ahead(gold_trees, Along.metres(90.0)).across == Across.metres(8.0)
expect nearest_tree_ahead(gold_trees, Along.metres(90.0)).along == Along.metres(96.0)
expect nearest_tree_ahead(gold_trees, Along.metres(96.0)).along == Along.metres(96.0)
expect nearest_tree_ahead(gold_trees, Along.metres(96.5)).along == Along.metres(126.0)

expect pig_herd_along(Distance.metres(1000.0)) == Along.metres(940.0)
