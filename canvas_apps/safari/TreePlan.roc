## TreePlan finds the roadside trees the rider can see in a frame: those
## planted along the chain of segments ahead that stand in front of the
## camera and are tall enough on screen to draw.
import DepthSort
import Frame
import Geom
import SceneLimits
import Scenery
import World

TreePlan :: [].{

	## A tree to draw: where it stands in the rider's view, its height and
	## its colour.
	TreeItem : { right : F64, fwd : F64, height : F64, color : I64 }

	## What the trees are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, and the camera's focal length.
	View : {
		world : List(World.Segment),
		chain : List(I64),
		pose : Frame.Pose,
		cam_focal : F64,
	}

	## At most this many trees are drawn in a frame.
	max_vis_trees : I64
	max_vis_trees = 640

	## The trees in view, the nearest segment's first, and each segment's in
	## the order it plants them.
	in_view : TreePlan.View -> List(TreePlan.TreeItem)
	in_view = |view| {
		places = List.from_iter(U64.until(0, view.chain.len()))
		places.join_map(|place| segment_trees(view, U64.to_i64_wrap(place)))
	}

	## The trees in view on the segment at `place` in the chain.
	segment_trees : TreePlan.View, I64 -> List(TreePlan.TreeItem)
	segment_trees = |view, place| {
		seg_index = view.chain.get(I64.to_u64_wrap(place)) ?? crash "TreePlan.segment_trees: no such place in the chain"
		segment = view.world.get(I64.to_u64_wrap(seg_index)) ?? crash "TreePlan.segment_trees: no such segment"
		segment.trees.join_map(|tree| tree_in_view(view, { place, tree }))
	}

	## A tree on the segment at `place` in the chain, if it is in view: one
	## item, or none.
	tree_in_view : TreePlan.View, { place : I64, tree : Scenery.Tree } -> List(TreePlan.TreeItem)
	tree_in_view = |view, { place, tree }| {
		seen = Frame.at(
			view.world,
			view.chain,
			view.pose,
			place,
			tree.along,
			(tree.across + (Scenery.lane_width / 2.0)),
		)
		if (seen.forward <= Geom.near) {
			[]
		} else if (((tree.height / seen.forward) * view.cam_focal) < SceneLimits.min_scenery_px) {
			[]
		} else {
			[{ right: seen.right, fwd: seen.forward, height: tree.height, color: tree.color }]
		}
	}

	## The trees as the depth sort sees them: each one's distance ahead, and
	## its place in `trees`.
	depth_keys : List(TreePlan.TreeItem) -> List(DepthSort.DepthKey)
	depth_keys = |trees| trees.map_with_index(|tree, i| { fwd: tree.fwd, kind: KTree, i: U64.to_i64_wrap(i) })
}
