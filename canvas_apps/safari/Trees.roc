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
	conifer_green = 0x1C5A22

	conifer_gold : I64
	conifer_gold = 0xCF9A18

	conifer_red : I64
	conifer_red = 0xB23A2A

	## A small green tree's height.
	small_height : Distance
	small_height = Distance.metres(4.5)

	## A big green tree's height.
	big_height : Distance
	big_height = small_height.times(1.3)

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
				Big => big_height
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
			Gold => Scenery.road_half_width.plus(tree_road_offset.times(4.0))
			Green | Red => Scenery.road_half_width.plus(tree_road_offset)
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
plant_onto = |planted, { scheme, length, along, size }|
	if along > Along.at(length.minus(Trees.tree_end_inset)) {
		planted
	} else if planted.len().to_i64_wrap() + 2 > Trees.max_trees {
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

expect Trees.conifer_green == 0x1C5A22
expect Trees.conifer_gold == 0xCF9A18
expect Trees.conifer_red == 0xB23A2A
expect Trees.max_trees == 96

expect Trees.small_height == Distance.metres(4.5)
expect Trees.big_height == Distance.metres(5.8500000000000005)
expect Trees.tree_spacing == Distance.metres(30.0)
expect Trees.tree_road_offset == Distance.metres(1.5)
expect Trees.tree_start_inset == Distance.metres(6.0)
expect Trees.tree_end_inset == Distance.metres(85.0)

expect Trees.color(Trees.accent(AllGreen)) == 0x1C5A22
expect Trees.color(Trees.accent(YellowGreen)) == 0xCF9A18
expect Trees.color(Trees.accent(RedGreen)) == 0xB23A2A

expect Trees.height({ conifer: Green, size: Big }).to_metres() == 5.8500000000000005
expect Trees.height({ conifer: Green, size: Small }).to_metres() == 4.5
expect Trees.height({ conifer: Red, size: Big }).to_metres() == 11.700000000000001
expect Trees.height({ conifer: Red, size: Small }).to_metres() == 9.0
expect Trees.height({ conifer: Gold, size: Big }).to_metres() == 17.55
expect Trees.height({ conifer: Gold, size: Small }).to_metres() == 13.5

expect Trees.distance_from_middle(Green).to_metres() == 3.5
expect Trees.distance_from_middle(Red).to_metres() == 3.5
expect Trees.distance_from_middle(Gold).to_metres() == 8.0

## Seven pairs, alternating big green and small gold.
yellow_green_trees : List(Scenery.Tree)
yellow_green_trees = Trees.plant({ scheme: YellowGreen, length: Distance.metres(300.0) })

expect
	yellow_green_trees.map(|tree| tree.along.to_metres())
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
	yellow_green_trees.map(|tree| tree.across.to_metres())
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
	yellow_green_trees.map(|tree| tree.color)
		== [
			0x1C5A22,
			0x1C5A22,
			0xCF9A18,
			0xCF9A18,
			0x1C5A22,
			0x1C5A22,
			0xCF9A18,
			0xCF9A18,
			0x1C5A22,
			0x1C5A22,
			0xCF9A18,
			0xCF9A18,
			0x1C5A22,
			0x1C5A22,
		]

expect
	yellow_green_trees.map(|tree| tree.height.to_metres())
		== [
			5.8500000000000005,
			5.8500000000000005,
			13.5,
			13.5,
			5.8500000000000005,
			5.8500000000000005,
			13.5,
			13.5,
			5.8500000000000005,
			5.8500000000000005,
			13.5,
			13.5,
			5.8500000000000005,
			5.8500000000000005,
		]

expect yellow_green_trees.len() == 14
expect Trees.plant({ scheme: AllGreen, length: Distance.metres(100.0) }).len() == 2
expect Trees.plant({ scheme: AllGreen, length: Distance.metres(5000.0) }).len() == 96
expect Trees.plant({ scheme: AllGreen, length: Distance.metres(50.0) }).len() == 0
