## Trees plants a segment's roadside conifers: a tree each side of the road
## every 30 m, from just past the segment's start to well short of its end.
## The pairs alternate between big green trees and smaller ones in the
## segment's accent colour, and a gold tree stands farther from the road.
import Across
import Along
import Distance
import Scenery

Trees :: [].{

	## A conifer's kind, which sets its colour, its height and how far from
	## the road it stands.
	Conifer : [Green, Gold, Red]

	## The size of a pair of trees.
	PairSize : [Big, Small]

	conifer_green : I64
	conifer_green = 1858082

	conifer_gold : I64
	conifer_gold = 13605400

	conifer_red : I64
	conifer_red = 11680298

	## A small green tree's height.
	small_height : Distance
	small_height = Distance.metres(4.5)

	## How much taller a tree in a big pair is.
	big_scale : F64
	big_scale = 1.3

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

	## At most this many trees stand on a segment.
	max_trees : I64
	max_trees = 96

	## The conifer that sets off a scheme's green.
	accent : Scenery.Scheme -> Trees.Conifer
	accent = |scheme|
		match scheme {
			YellowGreen => Gold
			RedGreen => Red
			AllGreen => Green
		}

	color : Trees.Conifer -> I64
	color = |conifer|
		match conifer {
			Green => conifer_green
			Gold => conifer_gold
			Red => conifer_red
		}

	## A conifer's height.
	height : { conifer : Trees.Conifer, size : Trees.PairSize } -> Distance
	height = |{ conifer, size }| {
		base =
			match size {
				Big => small_height.times(big_scale)
				Small => small_height
			}
		match conifer {
			Green => base
			Red => base.times(2.0)
			Gold => base.times(3.0)
		}
	}

	## How far from the middle of the road a conifer stands, either side.
	distance_from_middle : Trees.Conifer -> Distance
	distance_from_middle = |conifer|
		match conifer {
			Gold => Scenery.lane_half_width.plus(tree_road_offset.times(4.0))
			Green | Red => Scenery.lane_half_width.plus(tree_road_offset)
		}

	## A segment's trees, in pairs from its start, each pair's left tree
	## first.
	plant : { scheme : Scenery.Scheme, length : Distance } -> List(Scenery.Tree)
	plant = |{ scheme, length }| plant_onto(
		[],
		{
			scheme,
			length,
			along: Along.at(tree_start_inset),
			size: Big,
		},
	)
}

## The trees planted so far, and the pairs from `along` on, each pair the
## other size from the one before.
plant_onto : List(Scenery.Tree),
{
	scheme : Scenery.Scheme,
	length : Distance,
	along : Along,
	size : Trees.PairSize,
} -> List(Scenery.Tree)
plant_onto = |
	planted,
	{
		scheme,
		length,
		along,
		size,
	},
|
	if along > Along.at(length.minus(Trees.tree_end_inset)) {
		planted
	} else if (planted.len().to_i64_wrap() + 2) > Trees.max_trees {
		planted
	} else {
		conifer =
			match size {
				Big => Green
				Small => Trees.accent(scheme)
			}
		tree_color = Trees.color(conifer)
		tree_height = Trees.height({ conifer, size })
		from_middle = Trees.distance_from_middle(conifer)
		left = {
			along,
			across: Across.left_of_middle(from_middle),
			color: tree_color,
			height: tree_height,
		}
		right = {
			along,
			across: Across.right_of_middle(from_middle),
			color: tree_color,
			height: tree_height,
		}
		next_size =
			match size {
				Big => Small
				Small => Big
			}
		plant_onto(
			planted.append(left).append(right),
			{
				scheme,
				length,
				along: along.plus(Trees.tree_spacing),
				size: next_size,
			},
		)
	}
