## TreeSighting finds the roadside trees the rider can see in a frame: those
## planted along the chain of segments ahead that stand in front of the
## camera and are tall enough on screen to draw.
import Conifer
import DepthSort
import Distance
import Chain
import Geom
import Detail
import Trees

## A tree to draw: where it stands in the rider's view, and its kind. A tree
## in view is ahead of the rider, so of its lengths only `right` can be
## negative.
TreeSighting := {
	right : Distance,
	forward : Distance,
	conifer : Conifer,
}.{

	## The trees in view, the nearest segment's first, and each segment's in
	## the order it plants them.
	trees_in_view : Chain.Viewpoint -> List(TreeSighting)
	trees_in_view = |view| {
		positions = Chain.Position.all_in(view.road.chain)
		positions.join_map(|position| segment_sightings(view, position))
	}

	## The trees in view on the segment at `position` in the chain.
	segment_sightings : Chain.Viewpoint, Chain.Position -> List(TreeSighting)
	segment_sightings = |view, position| {
		segment = position.index_in(view.road.chain).segment_in(view.road.route)
		segment.trees.join_map(|tree| sighting_of(view, { position, tree }))
	}

	## A tree on the segment at `position` in the chain, if it is in view: one
	## item, or none.
	sighting_of : Chain.Viewpoint,
	{
		position : Chain.Position,
		tree : Trees.Tree,
	} -> List(TreeSighting)
	sighting_of = |view, { position, tree }| {
		rider_point = Chain.rider_point_ahead(
			view.road,
			{ position, along: tree.along, across: tree.across },
		)
		height_px = view.cam_focal.times(tree.conifer.height().ratio_to(rider_point.forward))
		if rider_point.forward <= Geom.near_plane {
			[]
		} else if height_px < Detail.min_scenery_px {
			[]
		} else {
			[
				{
					right: rider_point.right,
					forward: rider_point.forward,
					conifer: tree.conifer,
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
