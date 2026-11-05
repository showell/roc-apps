## These are ItemDraw's checks: how many trees are nearer than a distance,
## how a crown's shade falls off, where a mast's corners stand, and that
## masts and trees draw at all, a near tree in more detail than a far one.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Frame
import Grade
import ItemDraw
import Paint
import SceneLimits
import TowerPlan
import TreePlan
import World

fixed_got : List(F64)
fixed_got = [SceneLimits.crown_shade_dist, SceneLimits.detail_dist]

fixed_want : List(F64)
fixed_want = [80.0, 200.0]

tree_at : F64 -> TreePlan.TreeItem
tree_at = |forward| {
	right: 0.0,
	forward: forward,
	height: 5.85,
	color: 1858082,
}

spread : List(TreePlan.TreeItem)
spread = [10.0, 20.0, 30.0, 40.0, 50.0].map(tree_at)

nearer_count : List(TreePlan.TreeItem), F64 -> I64
nearer_count = |trees, forward| ItemDraw.nearer_tree_count(trees, forward).to_i64()

count_got : List(I64)
count_got = [
	nearer_count(spread, 10.0),
	nearer_count(spread, 30.0),
	nearer_count(spread, 50.0),
	nearer_count(spread, 60.0),
	nearer_count(spread, 5.0),
	nearer_count([], 10.0),
]

count_want : List(I64)
count_want = [0, 2, 4, 5, 0, 0]

tied : List(TreePlan.TreeItem)
tied = List.repeat(tree_at(20.0), 4)

tie_got : List(I64)
tie_got = [20.0, 20.1, 19.9].map(|forward| nearer_count(tied, forward))

tie_want : List(I64)
tie_want = [0, 4, 0]

shade_got : List(F64)
shade_got = [0.0, 20.0, 40.0, 80.0, 200.0, -50.0].map(ItemDraw.crown_shade)

shade_want : List(F64)
shade_want = [1.0, 0.75, 0.5, 0.0, 0.0, 1.0]

segs : List(World.Segment)
segs = [0, 1, 2].map(World.route_segment)

# The rider at the start of the route, at the ride's first step.
context : ItemDraw.Context
context = {
	road: {
		world: segs,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		pose: {
			along: 0.0,
			across: 0.0,
			yaw: Angle.straight_ahead,
			half_width: 2.0,
		},
	},
	cam_focal: 500.0,
	clock: 0.0,
	brake_lights: Off,
}

## A mast `along` metres down the first segment, 22 m across.
tower_along : F64 -> TowerPlan.TowerItem
tower_along = |along| {
	place: InChain(Frame.ChainPosition.first),
	along,
	across: 22.0,
	yaw: 0.0,
	forward: along,
	beacon_offset: 0.0,
}

corner_got : List(F64)
corner_got = {
	footprint = ItemDraw.tower_footprint(context, tower_along(200.0))
	[
		footprint.back_left.forward,
		footprint.front_right.forward,
		footprint.back_left.right,
		footprint.back_right.right,
	]
}

corner_want : List(F64)
corner_want = [194.0, 206.0, 14.0, 26.0]

tower_command_count : F64 -> U64
tower_command_count = |along| ItemDraw.draw_tower(context, tower_along(along)).len()

tower_got : List(Bool)
tower_got = [
	(tower_command_count(200.0) > 0),
	(tower_command_count(1000.0) > 0),
	(tower_command_count(-100.0) == 0),
]

tower_want : List(Bool)
tower_want = [True, True, True]

cluster : List(TreePlan.TreeItem)
cluster = [10.0, 11.0, 12.0, 13.0, 14.0].map(tree_at)

second_command_points : List(Paint.DrawCmd) -> U64
second_command_points = |commands| {
	second = commands.get(1) ?? crash "ItemDrawSpec: a tree in view draws a trunk and tiers"
	second.pts.len()
}

tree_got : List(Bool)
tree_got = {
	near = ItemDraw.draw_tree(tree_at(10.0), { trees: cluster, cam_focal: 500.0 })
	far = ItemDraw.draw_tree(tree_at(14.0), { trees: cluster, cam_focal: 500.0 })
	[
		(near.len() > 0),
		(far.len() > 0),
		(second_command_points(near) > second_command_points(far)),
		(second_command_points(far) >= 6),
	]
}

tree_want : List(Bool)
tree_want = [True, True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "id-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "id-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.ints({
			name: "id-tie   ",
			got: tie_got,
			want: tie_want,
		}),
		Grade.reals({
			name: "id-shade ",
			got: shade_got,
			want: shade_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "id-corner",
			got: corner_got,
			want: corner_want,
			tol: 0.0001,
		}),
		Grade.bools({
			name: "id-tower ",
			got: tower_got,
			want: tower_want,
		}),
		Grade.bools({
			name: "id-tree  ",
			got: tree_got,
			want: tree_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
