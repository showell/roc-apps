## Trees plants a segment's roadside conifers: a tree each side of the road
## every 30 m, from just past the segment's start to well short of its end.
## The pairs alternate between big green trees and the segment's accent, which
## is small and green, or red, or gold, and a gold tree stands farther from the
## road.
import Across
import Along
import Conifer
import Distance
import Scenery

Trees :: [].{

	## A planted tree: where it stands on its segment, and its kind.
	Tree : {
		along : Along,
		across : Across,
		conifer : Conifer,
	}

	tree_spacing : Distance
	tree_spacing = Distance.metres(30.0)

	## How far from the road's edge a tree stands; a gold one, four times
	## as far.
	tree_road_offset : Distance
	tree_road_offset = Distance.metres(1.5)

	## How far into a segment its first pair stands.
	tree_start_inset : Distance
	tree_start_inset = Distance.metres(6.0)

	## No pair stands closer than this to a segment's end.
	tree_end_inset : Distance
	tree_end_inset = Distance.metres(85.0)

	## The conifer that sets off a scheme's green.
	accent : Scenery.Scheme -> Conifer
	accent = |scheme|
		match scheme {
			GoldGreen => Conifer.Gold
			RedGreen => Conifer.Red
			AllGreen => Conifer.SmallGreen
		}

	## How far from the middle of the road a conifer stands, either side.
	distance_from_middle : Conifer -> Distance
	distance_from_middle = |conifer|
		match conifer {
			Gold => Scenery.road_half_width.plus(tree_road_offset.times(4.0))
			BigGreen | SmallGreen | Red => Scenery.road_half_width.plus(tree_road_offset)
		}

	## A segment's trees, in pairs from its start, each pair's left tree
	## first.
	plant : { scheme : Scenery.Scheme, length : Distance } -> List(Trees.Tree)
	plant = |{ scheme, length }| plant_onto(
		[],
		{
			scheme,
			length,
			along: Along.at(tree_start_inset),
			conifer: Conifer.BigGreen,
		},
	)
}

## The trees planted so far, and the pairs from `along` on: `conifer`, then
## each pair the scheme's accent after a big green one and a big green one
## after the accent.
plant_onto : List(Trees.Tree),
{
	scheme : Scenery.Scheme,
	length : Distance,
	along : Along,
	conifer : Conifer,
} -> List(Trees.Tree)
plant_onto = |planted, { scheme, length, along, conifer }|
	if along > Along.at(length.minus(Trees.tree_end_inset)) {
		planted
	} else {
		from_middle = Trees.distance_from_middle(conifer)
		left = { along, across: Across.left_of_middle(from_middle), conifer }
		right = { along, across: Across.right_of_middle(from_middle), conifer }
		next_conifer =
			match conifer {
				BigGreen => Trees.accent(scheme)
				SmallGreen | Red | Gold => Conifer.BigGreen
			}
		plant_onto(
			planted.append(left).append(right),
			{
				scheme,
				length,
				along: along.plus(Trees.tree_spacing),
				conifer: next_conifer,
			},
		)
	}

expect Trees.tree_spacing == Distance.metres(30.0)
expect Trees.tree_road_offset == Distance.metres(1.5)
expect Trees.tree_start_inset == Distance.metres(6.0)
expect Trees.tree_end_inset == Distance.metres(85.0)

expect Trees.accent(AllGreen) == Conifer.SmallGreen
expect Trees.accent(GoldGreen) == Conifer.Gold
expect Trees.accent(RedGreen) == Conifer.Red

expect Trees.distance_from_middle(Conifer.BigGreen).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.SmallGreen).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.Red).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.Gold).to_metres() == 8.0

## Seven pairs, alternating big green and gold.
gold_green_trees : List(Trees.Tree)
gold_green_trees = Trees.plant({ scheme: GoldGreen, length: Distance.metres(300.0) })

expect
	gold_green_trees.map(|tree| tree.along.to_metres())
		== [
			6.0,
			6.0,
			36.0,
			36.0,
			66.0,
			66.0,
			96.0,
			96.0,
			126.0,
			126.0,
			156.0,
			156.0,
			186.0,
			186.0,
		]

expect
	gold_green_trees.map(|tree| tree.across.to_metres())
		== [
			-3.5,
			3.5,
			-8.0,
			8.0,
			-3.5,
			3.5,
			-8.0,
			8.0,
			-3.5,
			3.5,
			-8.0,
			8.0,
			-3.5,
			3.5,
		]

expect
	gold_green_trees.map(|tree| tree.conifer)
		== [
			Conifer.BigGreen,
			Conifer.BigGreen,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.BigGreen,
			Conifer.BigGreen,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.BigGreen,
			Conifer.BigGreen,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.BigGreen,
			Conifer.BigGreen,
		]

expect gold_green_trees.len() == 14
expect Trees.plant({ scheme: AllGreen, length: Distance.metres(100.0) }).len() == 2
expect Trees.plant({ scheme: AllGreen, length: Distance.metres(50.0) }).len() == 0
