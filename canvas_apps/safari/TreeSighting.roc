## TreeSighting finds the roadside trees the rider can see in a frame: those
## planted along the chain of segments ahead that stand in front of the
## camera and are tall enough on screen to draw.
import DepthSort
import Distance
import Chain
import Geom
import Detail
import Scenery

## A tree to draw: where it stands in the rider's view, its height and
## its colour.
TreeSighting := {
	right : F64,
	forward : F64,
	height : Distance,
	color : I64,
}.{

	## At most this many trees are drawn in a frame.
	max_vis_trees : I64
	max_vis_trees = 640

	## The trees in view, the nearest segment's first, and each segment's in
	## the order it plants them.
	in_view : Chain.Viewpoint -> List(TreeSighting)
	in_view = |view| {
		positions = Chain.Position.all_in(view.road.chain)
		positions.join_map(|position| segment_trees(view, position))
	}

	## The trees in view on the segment at `position` in the chain.
	segment_trees : Chain.Viewpoint, Chain.Position -> List(TreeSighting)
	segment_trees = |view, position| {
		segment = position.index_in(view.road.chain).segment_in(view.road.world)
		segment.trees.join_map(|tree| tree_in_view(view, { position, tree }))
	}

	## A tree on the segment at `position` in the chain, if it is in view: one
	## item, or none.
	tree_in_view : Chain.Viewpoint,
	{
		position : Chain.Position,
		tree : Scenery.Tree,
	} -> List(TreeSighting)
	tree_in_view = |view, { position, tree }| {
		seen = Chain.rider_point_ahead(
			view.road,
			{
				position: position,
				along: tree.along,
				across: tree.across,
			},
		)
		height_px = (tree.height.to_metres() / seen.forward) * view.cam_focal
		if seen.forward <= Geom.near_plane {
			[]
		} else if height_px < Detail.min_scenery_px {
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
	depth_keys : List(TreeSighting) -> List(DepthSort.DepthKey)
	depth_keys = |trees| trees.map_with_index(
		|tree, i| { forward: tree.forward, subject: Tree(i.to_u32_wrap()) },
	)
}
