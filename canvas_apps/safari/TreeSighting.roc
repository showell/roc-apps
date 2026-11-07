## TreeSighting finds the roadside trees the rider can see in a frame: those
## planted along the chain of segments ahead that stand in front of the
## camera and are tall enough on screen to draw.
import Conifer
import Chain
import Pipeline
import Trees

TreeSighting :: [].{

	## The trees in view, the nearest segment's first, and each segment's in
	## the order it plants them.
	trees_in_view : Chain.CameraView -> List(Pipeline.Sighted(Conifer))
	trees_in_view = |view| {
		positions = Chain.Position.positions_in(view.road.chain_indices)
		positions.join_map(|position| segment_sightings(view, position))
	}

	## The trees in view on the segment at `position` in the chain.
	segment_sightings : Chain.CameraView, Chain.Position -> List(Pipeline.Sighted(Conifer))
	segment_sightings = |view, position| {
		segment = Chain.segment_at(view.road, position)
		segment.trees.keep_oks(|tree| sighting_of(view, { position, tree }))
	}

	## A tree on the segment at `position` in the chain, if it is in view. A
	## tree's size is tested through the camera's own lens, so a tree at the edge
	## of what can be seen comes and goes as the camera widens.
	sighting_of : Chain.CameraView,
	{
		position : Chain.Position,
		tree : Trees.RoadsideTree,
	} -> Try(Pipeline.Sighted(Conifer), [BehindCamera, TooSmall])
	sighting_of = |view, { position, tree }|
		Pipeline.tall_sighting_of(
			tree,
			{
				road: view.road,
				place: InChain(position),
				size_test: Pipeline.scenery_test(view),
			},
		)
}
