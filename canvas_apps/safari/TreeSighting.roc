## TreeSighting finds the roadside trees the rider can see in a frame: those
## placed along the segments in view that stand in front of the camera and are
## tall enough on screen to draw.
import Conifer
import Distance
import RoadAhead
import Pipeline
import Pixels
import Rendered
import TreeShapes

TreeSighting :: [].{

	## The trees in view, segment by segment in the order of
	## `RoadAhead.segments_in_view`, and each segment's in the order `Trees`
	## places them.
	trees_in_view : RoadAhead.RoadView, Pipeline.SightingCamera -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |road, camera|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_trees(road, { camera, in_view }),
		)

	## Each of `trees` rendered, told how many of the others are nearer, which is
	## all a tree needs of them. It is public for FramePartsBench, which times
	## the trees alone.
	tree_renderings : List(Pipeline.Sighted(Conifer)), Pixels -> List(Rendered)
	tree_renderings = |trees, focal_length| {
		forwards = trees.map(|tree| tree.spot.foot().forward())
		trees.map(
			|tree| {
				nearer_count = nearer_tree_count(forwards, tree.spot.foot().forward())
				detail : TreeShapes.Detail
				detail = { nearer_tree_count: nearer_count }
				Pipeline.rendering_of(tree, { focal_length, context: detail })
			},
		)
	}
}

## The trees in view on a segment in view.
segment_trees : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
} -> List(Pipeline.Sighted(Conifer))
segment_trees = |road, { camera, in_view }|
	in_view.segment.trees.keep_oks(
		|tree| Pipeline.scenery_sighting_of(tree, { road, camera, place: in_view.place }),
	)

## How many of the trees at `forwards` are nearer than `forward`.
nearer_tree_count : List(Distance), Distance -> U64
nearer_tree_count = |forwards, forward| forwards.count_if(|other| other < forward)

spread_forwards : List(Distance)
spread_forwards = [10.0, 20.0, 30.0, 40.0, 50.0].map(Distance.metres)

expect nearer_tree_count(spread_forwards, Distance.metres(10.0)) == 0
expect nearer_tree_count(spread_forwards, Distance.metres(30.0)) == 2
expect nearer_tree_count(spread_forwards, Distance.metres(50.0)) == 4
expect nearer_tree_count(spread_forwards, Distance.metres(60.0)) == 5
expect nearer_tree_count(spread_forwards, Distance.metres(5.0)) == 0
expect nearer_tree_count([], Distance.metres(10.0)) == 0

tied_forwards : List(Distance)
tied_forwards = List.repeat(Distance.metres(20.0), 4)

expect nearer_tree_count(tied_forwards, Distance.metres(20.0)) == 0
expect nearer_tree_count(tied_forwards, Distance.metres(20.1)) == 4
expect nearer_tree_count(tied_forwards, Distance.metres(19.9)) == 0
