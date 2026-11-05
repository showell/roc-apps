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
	TreeItem : {
		right : F64,
		forward : F64,
		height : F64,
		color : I64,
	}

	## What the trees are seen from: the world's segments, the chain of them
	## ahead of the rider, the rider's pose, and the camera's focal length.
	View : {
		world : List(World.Segment),
		chain : List(World.SegmentIndex),
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
		positions = Frame.ChainPosition.all_in(view.chain)
		positions.join_map(|position| segment_trees(view, position))
	}

	## The trees in view on the segment at `position` in the chain.
	segment_trees : TreePlan.View, Frame.ChainPosition -> List(TreePlan.TreeItem)
	segment_trees = |view, position| {
		segment = position.index_in(view.chain).segment_in(view.world)
		segment.trees.join_map(|tree| tree_in_view(view, { position, tree }))
	}

	## A tree on the segment at `position` in the chain, if it is in view: one
	## item, or none.
	tree_in_view : TreePlan.View,
	{
		position : Frame.ChainPosition,
		tree : Scenery.Tree,
	} -> List(TreePlan.TreeItem)
	tree_in_view = |view, { position, tree }| {
		seen = Frame.rider_point_ahead(
			{
				world: view.world,
				chain: view.chain,
				pose: view.pose,
			},
			{
				position: position,
				along: tree.along,
				across: (tree.across + (Scenery.lane_width / 2.0)),
			},
		)
		if seen.forward <= Geom.near_plane {
			[]
		} else if ((tree.height / seen.forward) * view.cam_focal) < SceneLimits.min_scenery_px {
			[]
		} else {
			[
				{
					right: seen.right,
					forward: seen.forward,
					height: tree.height,
					color: tree.color,
				},
			]
		}
	}

	## The trees as the depth sort sees them: each one's distance ahead, and
	## its position in `trees`.
	depth_keys : List(TreePlan.TreeItem) -> List(DepthSort.DepthKey)
	depth_keys = |trees| trees.map_with_index(|tree, i| { forward: tree.forward, subject: Tree(i) })
}
