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
	accent_conifer : Scenery.Scheme -> Conifer
	accent_conifer = |scheme|
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
	planted_trees : { scheme : Scenery.Scheme, length : Distance } -> List(Trees.Tree)
	planted_trees = |{ scheme, length }| {
		last_along = Along.at(length.minus(tree_end_inset))
		var $along = Along.at(tree_start_inset)
		var $conifer = Conifer.BigGreen
		var $trees = []
		while $along <= last_along {
			tree_distance = distance_from_middle($conifer)
			left_tree = {
				along: $along,
				across: Across.left_of_middle(tree_distance),
				conifer: $conifer,
			}
			right_tree = { ..left_tree, across: Across.right_of_middle(tree_distance) }
			$trees = $trees.append(left_tree).append(right_tree)
			$along = $along.plus(tree_spacing)
			$conifer =
				match $conifer {
					BigGreen => accent_conifer(scheme)
					SmallGreen | Red | Gold => Conifer.BigGreen
				}
		}
		$trees
	}
}

expect Trees.tree_spacing == Distance.metres(30.0)
expect Trees.tree_road_offset == Distance.metres(1.5)
expect Trees.tree_start_inset == Distance.metres(6.0)
expect Trees.tree_end_inset == Distance.metres(85.0)

expect Trees.accent_conifer(AllGreen) == Conifer.SmallGreen
expect Trees.accent_conifer(GoldGreen) == Conifer.Gold
expect Trees.accent_conifer(RedGreen) == Conifer.Red

expect Trees.distance_from_middle(Conifer.BigGreen).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.SmallGreen).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.Red).to_metres() == 3.5
expect Trees.distance_from_middle(Conifer.Gold).to_metres() == 8.0

## Seven pairs, alternating big green and gold.
gold_green_trees : List(Trees.Tree)
gold_green_trees = Trees.planted_trees({ scheme: GoldGreen, length: Distance.metres(300.0) })

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
expect Trees.planted_trees({ scheme: AllGreen, length: Distance.metres(100.0) }).len() == 2
expect Trees.planted_trees({ scheme: AllGreen, length: Distance.metres(50.0) }).len() == 0
