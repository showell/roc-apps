## Trees plants a segment's roadside conifers: a tree each side of the road
## every 30 m, from just past the segment's start to well short of its end.
## The pairs alternate between big green trees and smaller ones in the
## segment's accent colour, and a gold tree stands farther from the road.
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

	## A small green tree's height, in metres.
	small_height : F64
	small_height = 4.5

	## How much taller a tree in a big pair is.
	big_scale : F64
	big_scale = 1.3

	tree_spacing : F64
	tree_spacing = 30.0

	## How far from the road's edge a tree stands; a gold one, four times
	## as far.
	tree_road_offset : F64
	tree_road_offset = 1.5

	## How far into a segment its first pair stands.
	tree_start_inset : F64
	tree_start_inset = 6.0

	## No pair stands closer than this to a segment's end.
	tree_end_inset : F64
	tree_end_inset = 85.0

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

	## A conifer's height, in metres.
	height : { conifer : Trees.Conifer, size : Trees.PairSize } -> F64
	height = |{ conifer, size }| {
		base =
			match size {
				Big => (small_height * big_scale)
				Small => small_height
			}
		match conifer {
			Green => base
			Red => (base * 2.0)
			Gold => (base * 3.0)
		}
	}

	## How far from the middle of the road a conifer stands, either side.
	across : Trees.Conifer -> F64
	across = |conifer|
		match conifer {
			Gold => ((Scenery.lane_width / 2.0) + (4.0 * tree_road_offset))
			Green | Red => ((Scenery.lane_width / 2.0) + tree_road_offset)
		}

	## A segment's trees, in pairs from its start, each pair's left tree
	## first.
	plant : { scheme : Scenery.Scheme, length : F64 } -> List(Scenery.Tree)
	plant = |{ scheme, length }| plant_onto(
		[],
		{
			scheme,
			length,
			along: tree_start_inset,
			size: Big,
		},
	)
}

## The trees planted so far, and the pairs from `along` on, each pair the
## other size from the one before.
plant_onto : List(Scenery.Tree),
{
	scheme : Scenery.Scheme,
	length : F64,
	along : F64,
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
	if along > (length - Trees.tree_end_inset) {
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
		from_middle = Trees.across(conifer)
		left = {
			along,
			across: (0.0 - from_middle),
			color: tree_color,
			height: tree_height,
		}
		right = {
			along,
			across: from_middle,
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
				along: (along + Trees.tree_spacing),
				size: next_size,
			},
		)
	}
