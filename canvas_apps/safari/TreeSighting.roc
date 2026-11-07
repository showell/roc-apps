## TreeSighting finds the roadside trees the rider can see in a frame: those
## placed along the segments in view that stand in front of the camera and are
## tall enough on screen to draw.
import Conifer
import RoadAhead
import Pipeline
import Trees

TreeSighting :: [].{

	## The trees in view, segment by segment in the order of
	## `RoadAhead.segments_in_view`, and each segment's in the order `Trees`
	## places them.
	trees_in_view : RoadAhead.CameraView -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |view|
		RoadAhead.segments_in_view(view.road).join_map(|in_view| segment_sightings(view, in_view))

	## The trees in view on a segment in view.
	segment_sightings : RoadAhead.CameraView,
	RoadAhead.SegmentInView -> List(
		Pipeline.Sighted(Conifer),
	)
	segment_sightings = |view, in_view|
		in_view.segment.trees.keep_oks(|tree| sighting_of(view, { place: in_view.place, tree }))

	## A tree on the segment at `place`, if it is in view. A tree's size is
	## tested through the camera's own lens, so a tree at the edge of what can be
	## seen comes and goes as the camera widens.
	sighting_of : RoadAhead.CameraView,
	{
		place : RoadAhead.SegmentPlace,
		tree : Trees.RoadsideTree,
	} -> Try(Pipeline.Sighted(Conifer), [BehindCamera, TooSmall])
	sighting_of = |view, { place, tree }|
		Pipeline.tall_sighting_of(
			tree,
			{
				road: view.road,
				place,
				size_test: Pipeline.scenery_test(view),
			},
		)
}
