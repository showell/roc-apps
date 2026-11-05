## These are TreePlan's checks: which trees are in view, where they
## stand, and the keys the depth sort reads.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import DepthSort
import Frame
import Grade
import Scenery
import TreePlan
import World

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

origin : Frame.Pose
origin = {
	along: 0.0,
	across: 0.0,
	yaw: Angle.straight_ahead,
	half_width: 2.0,
}

up_road : Frame.Pose
up_road = {
	along: 100.0,
	across: 0.0,
	yaw: Angle.straight_ahead,
	half_width: 2.0,
}

## The first three segments, seen from `pose` through a camera of focal
## length `cam_focal`.
view_from : Frame.Pose, F64 -> TreePlan.View
view_from = |pose, cam_focal| {
	world: segs,
	chain: [0, 1, 2].map(World.SegmentIndex.number),
	pose,
	cam_focal,
}

from_origin : TreePlan.View
from_origin = view_from(origin, 500.0)

## A green tree `along` metres into the first segment, 3.5 m right of the
## road's middle.
green_tree_at : F64 -> { position : Frame.ChainPosition, tree : Scenery.Tree }
green_tree_at = |along| {
	position: Frame.ChainPosition.first,
	tree: {
		along,
		across: 3.5,
		color: 1858082,
		height: 5.85,
	},
}

planted_got : List(I64)
planted_got = List.concat(segs.map(|seg| seg.trees.len().to_i64_wrap()), [TreePlan.max_vis_trees])

planted_want : List(I64)
planted_want = [28, 16, 22, 640]

lone_tree : TreePlan.TreeItem
lone_tree = TreePlan.tree_in_view(
	from_origin,
	green_tree_at(120.0),
).first() ?? crash "TreePlanSpec: a tree 120 m ahead is in view"

one_got : List(F64)
one_got = [
	lone_tree.right,
	lone_tree.forward,
	lone_tree.height,
]

one_want : List(F64)
one_want = [3.5, 120.0, 5.85]

one_colour_got : List(I64)
one_colour_got = [
	TreePlan.tree_in_view(from_origin, green_tree_at(120.0)).len().to_i64_wrap(),
	lone_tree.color,
]

one_colour_want : List(I64)
one_colour_want = [1, 1858082]

cull_got : List(I64)
cull_got = [
	TreePlan.tree_in_view(from_origin, green_tree_at(0.4)),
	TreePlan.tree_in_view(from_origin, green_tree_at(0.5)),
	TreePlan.tree_in_view(view_from(origin, 1.0), green_tree_at(120.0)),
	TreePlan.tree_in_view(from_origin, green_tree_at(2000.0)),
].map(|seen| seen.len().to_i64_wrap())

cull_want : List(I64)
cull_want = [0, 1, 0, 0]

seg0_got : List(I64)
seg0_got = [
	from_origin,
	view_from(up_road, 500.0),
	view_from(origin, 1.0),
].map(|view| TreePlan.segment_trees(view, Frame.ChainPosition.first).len().to_i64_wrap())

seg0_want : List(I64)
seg0_want = [28, 20, 0]

first_segment : List(TreePlan.TreeItem)
first_segment = TreePlan.segment_trees(from_origin, Frame.ChainPosition.first)

## The first segment's tree at `i`, in planting order.
planted_tree : U64 -> TreePlan.TreeItem
planted_tree = |i|
	first_segment.get(i) ?? crash "TreePlanSpec: the first segment has 28 trees in view"

order_got : List(F64)
order_got = [
	planted_tree(0).forward,
	planted_tree(1).forward,
	planted_tree(2).forward,
	planted_tree(0).right,
	planted_tree(1).right,
]

order_want : List(F64)
order_want = [
	6.0,
	6.0,
	36.0,
	(-3.5),
	3.5,
]

height_got : List(F64)
height_got = [planted_tree(0).height, planted_tree(2).height]

height_want : List(F64)
height_want = [5.85, 4.5]

keys : List(DepthSort.DepthKey)
keys = TreePlan.depth_keys(first_segment)

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "TreePlanSpec: the first segment has 28 keys"

## The position in the tree list that the key at `i` names.
tree_place_at : U64 -> I64
tree_place_at = |i|
	match key_at(i).subject {
		Tree(position) => position.to_i64()
		Tower(_) | Critter(_) | Cat(_) | Truck | Rail(_) | Bird(_) =>
			crash "TreePlanSpec: a tree's key names a tree"
	}

items_got : List(I64)
items_got = [
	keys.len().to_i64_wrap(),
	tree_place_at(0),
	tree_place_at(27),
	TreePlan.depth_keys([]).len().to_i64_wrap(),
]

items_want : List(I64)
items_want = [28, 0, 27, 0]

item_fwd_got : List(F64)
item_fwd_got = [key_at(0).forward, key_at(2).forward]

item_fwd_want : List(F64)
item_fwd_want = [6.0, 36.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "te-plant ",
			got: planted_got,
			want: planted_want,
		}),
		Grade.reals({
			name: "te-one   ",
			got: one_got,
			want: one_want,
			tol: 0.0001,
		}),
		Grade.ints({
			name: "te-colour",
			got: one_colour_got,
			want: one_colour_want,
		}),
		Grade.ints({
			name: "te-cull  ",
			got: cull_got,
			want: cull_want,
		}),
		Grade.ints({
			name: "te-seg0  ",
			got: seg0_got,
			want: seg0_want,
		}),
		Grade.reals({
			name: "te-order ",
			got: order_got,
			want: order_want,
			tol: 0.0001,
		}),
		Grade.reals({
			name: "te-height",
			got: height_got,
			want: height_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.ints({
			name: "te-items ",
			got: items_got,
			want: items_want,
		}),
		Grade.reals({
			name: "te-ifwd  ",
			got: item_fwd_got,
			want: item_fwd_want,
			tol: 0.0001,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
