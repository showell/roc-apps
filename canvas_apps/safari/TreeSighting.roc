## TreeSighting finds the roadside trees the rider can see in a frame: those
## placed along the segments in view that stand in front of the camera and are
## tall enough on screen to draw.
import Conifer
import RoadAhead
import Pipeline

TreeSighting :: [].{

	## The trees in view, segment by segment in the order of
	## `RoadAhead.segments_in_view`, and each segment's in the order `Trees`
	## places them.
	trees_in_view : RoadAhead.RoadView, Pipeline.SightingCamera -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |road, camera|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_trees(road, { camera, in_view }),
		)
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
