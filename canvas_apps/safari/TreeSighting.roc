## TreeSighting finds the roadside trees the rider can see in a frame: those
## placed along the road ahead that stand in front of the camera and are tall
## enough on screen to draw.
import Conifer
import RoadAhead
import Pipeline
import Trees

TreeSighting :: [].{

	## The trees in view, the nearest segment's first, and each segment's in
	## the order `Trees` places them. Only the road ahead is searched, because
	## the segment just behind adds the bend the rider has just turned, and a
	## tree stands along its segment, which the rider has passed.
	trees_in_view : RoadAhead.CameraView -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |view| {
		positions = RoadAhead.Position.positions_in(view.road.segments_ahead)
		positions.join_map(|position| segment_sightings(view, position))
	}

	## The trees in view on the segment at `position` on the road ahead.
	segment_sightings : RoadAhead.CameraView, RoadAhead.Position -> List(Pipeline.Sighted(Conifer))
	segment_sightings = |view, position| {
		segment = RoadAhead.segment_at(view.road, position)
		segment.trees.keep_oks(|tree| sighting_of(view, { position, tree }))
	}

	## A tree on the segment at `position` on the road ahead, if it is in view. A
	## tree's size is tested through the camera's own lens, so a tree at the edge
	## of what can be seen comes and goes as the camera widens.
	sighting_of : RoadAhead.CameraView,
	{
		position : RoadAhead.Position,
		tree : Trees.RoadsideTree,
	} -> Try(Pipeline.Sighted(Conifer), [BehindCamera, TooSmall])
	sighting_of = |view, { position, tree }|
		Pipeline.tall_sighting_of(
			tree,
			{
				road: view.road,
				place: Ahead(position),
				size_test: Pipeline.scenery_test(view),
			},
		)
}
