## Trees places a segment's roadside conifers: a tree each side of the road
## every `tree_spacing`, from just past the segment's start to well short of
## its end.
## The pairs alternate between green trees and the segment's accent, which
## is small and green, or red, or gold, and a gold tree stands farther from the
## road.
import Across
import Along
import Conifer
import Distance
import Geom

Trees :: [].{

	## A segment's colour scheme: the accent its trees alternate with green.
	Scheme : [AllGreen, GoldGreen, RedGreen]

	## A tree beside the road: where it stands on its segment, and its kind.
	RoadsideTree : Geom.Placed(Conifer)

	## How far from the middle of the road a conifer stands, either side. The gold
	## tree stands four times as far out from the road's edge as the others, a
	## factor chosen by eye.
	tree_line_distance : Conifer -> Distance
	tree_line_distance = |conifer|
		match conifer {
			Gold => Geom.road_half_width.plus(tree_road_offset.times(4.0))
			Green | SmallGreen | Red => Geom.road_half_width.plus(tree_road_offset)
		}

	## A segment's trees, in pairs from its start, each pair's left tree
	## first.
	roadside_trees : { scheme : Trees.Scheme, length : Distance } -> List(Trees.RoadsideTree)
	roadside_trees = |{ scheme, length }| {
		last_along = Along.at(length.minus(tree_end_inset))
		var $along = Along.at(tree_start_inset)
		var $conifer = Conifer.Green
		var $trees = []
		while $along <= last_along {
			tree_distance = tree_line_distance($conifer)
			left_tree = {
				road_point: { along: $along, across: Across.left_of_middle(tree_distance) },
				lift: Distance.zero,
				kind: $conifer,
			}
			right_tree = {
				..left_tree,
				road_point: { along: $along, across: Across.right_of_middle(tree_distance) },
			}
			$trees = $trees.append(left_tree).append(right_tree)
			$along = $along.plus(tree_spacing)
			$conifer =
				match $conifer {
					Green => accent_conifer(scheme)
					SmallGreen | Red | Gold => Conifer.Green
				}
		}
		$trees
	}
}

tree_spacing : Distance
tree_spacing = Distance.metres(30.0)

## How far from the road's edge a tree stands; a gold one, four times
## as far.
tree_road_offset : Distance
tree_road_offset = Distance.metres(1.5)

## How far into a segment its first pair stands, chosen by eye.
tree_start_inset : Distance
tree_start_inset = Distance.metres(6.0)

## No pair stands closer than this to a segment's end, a distance chosen by
## eye.
tree_end_inset : Distance
tree_end_inset = Distance.metres(85.0)

## The conifer that sets off a scheme's green.
accent_conifer : Trees.Scheme -> Conifer
accent_conifer = |scheme|
	match scheme {
		GoldGreen => Conifer.Gold
		RedGreen => Conifer.Red
		AllGreen => Conifer.SmallGreen
	}

## Seven pairs, alternating green and gold.
gold_green_trees : List(Trees.RoadsideTree)
gold_green_trees = Trees.roadside_trees({ scheme: GoldGreen, length: Distance.metres(300.0) })

expect
	gold_green_trees.map(|tree| tree.road_point.along.to_metres())
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
	gold_green_trees.map(|tree| tree.road_point.across.to_metres())
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
	gold_green_trees.map(|tree| tree.kind)
		== [
			Conifer.Green,
			Conifer.Green,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.Green,
			Conifer.Green,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.Green,
			Conifer.Green,
			Conifer.Gold,
			Conifer.Gold,
			Conifer.Green,
			Conifer.Green,
		]

expect gold_green_trees.len() == 14
expect Trees.roadside_trees({ scheme: AllGreen, length: Distance.metres(100.0) }).len() == 2
expect Trees.roadside_trees({ scheme: AllGreen, length: Distance.metres(50.0) }).len() == 0
