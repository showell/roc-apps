## CatSighting finds the cats the rider can see in a frame: each one waiting
## on a segment of the road ahead, placed where its crossing has got to,
## if it is in front of the camera and tall enough on screen to draw.
import Animation
import Cat
import CatShapes
import RoadAhead
import Geom
import Pipeline
import Speed

CatSighting :: [].{

	## The cats in view of a rider at `speed`, the nearest segment's first.
	cats_in_view : RoadAhead.CameraView, Speed -> List(Pipeline.Sighted(CatShapes.PosedCat))
	cats_in_view = |view, speed| {
		positions = RoadAhead.Position.positions_in(view.road.segments_ahead)
		positions.keep_oks(|position| segment_cat(view, { position, speed }))
	}

	## The cat waiting on the segment at `position` on the road ahead, if it has
	## one and it is in view.
	segment_cat : RoadAhead.CameraView,
	{
		position : RoadAhead.Position,
		speed : Speed,
	} -> Try(Pipeline.Sighted(CatShapes.PosedCat), [NoCat, BehindCamera, TooSmall])
	segment_cat = |view, { position, speed }| {
		segment = RoadAhead.segment_at(view.road, position)
		match segment.crossing {
			CatCrosses(crossing) =>
				cat_in_view(view, { position, crossing, speed })
			BirdHere(_) | QuietRoad => Err(NoCat)
		}
	}
}

## The cat crossing the segment at `position` on the road ahead, as far
## through its crossing as the rider's approach has brought it, if it is in view.
cat_in_view : RoadAhead.CameraView,
{
	position : RoadAhead.Position,
	crossing : Cat.Crossing,
	speed : Speed,
} -> Try(Pipeline.Sighted(CatShapes.PosedCat), [BehindCamera, TooSmall])
cat_in_view = |view, { position, crossing, speed }| {
	gap = RoadAhead.gap_to_segment(view.road, position)
	instant = Cat.instant_at(crossing, { gap: gap.plus(crossing.along.from_start()), speed })
	placed_cat : Geom.Placed(CatShapes.PosedCat)
	placed_cat = Animation.placed_instant(instant)
	Pipeline.tall_sighting_of(
		placed_cat,
		{
			road: view.road,
			place: Ahead(position),
			size_test: Pipeline.scenery_test(view),
		},
	)
}
