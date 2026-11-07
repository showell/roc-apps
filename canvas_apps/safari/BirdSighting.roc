## BirdSighting finds the Roc birds the rider can see in a frame: each one on a
## segment of the road ahead, placed where its flight has got to, if it is in
## front of the camera and tall enough on screen to draw.
import Animation
import BirdFlight
import BirdShapes
import RoadAhead
import Geom
import Pipeline

BirdSighting :: [].{

	## The birds in view, the nearest segment's first.
	birds_in_view : RoadAhead.CameraView -> List(Pipeline.Sighted(BirdShapes.PosedBird))
	birds_in_view = |view| {
		positions = RoadAhead.Position.positions_in(view.road.segments_ahead)
		positions.keep_oks(|position| segment_bird(view, position))
	}
}

## The bird of the segment at `position` on the road ahead, if that segment
## has one and it is in view.
segment_bird : RoadAhead.CameraView,
RoadAhead.Position -> Try(
	Pipeline.Sighted(BirdShapes.PosedBird),
	[NoBird, BehindCamera, TooSmall],
)
segment_bird = |view, position|
	match RoadAhead.segment_at(view.road, position).crossing {
		BirdHere(habit) => {
			gap_to_segment = RoadAhead.gap_to_segment(view.road, position)
			gap_to_tree = gap_to_segment.plus(BirdFlight.start_along(habit).from_start())
			instant = BirdFlight.habit_instant_at(habit, { gap: gap_to_tree })
			bird_in_view(view, { position, instant })
		}
		CatCrosses(_) | QuietRoad => Err(NoBird)
	}

## The bird at `instant` on the segment at `position` on the road ahead, if it
## is in view.
bird_in_view : RoadAhead.CameraView,
{
	position : RoadAhead.Position,
	instant : BirdFlight.Bird,
} -> Try(Pipeline.Sighted(BirdShapes.PosedBird), [BehindCamera, TooSmall])
bird_in_view = |view, { position, instant }| {
	placed_bird : Geom.Placed(BirdShapes.PosedBird)
	placed_bird = Animation.placed_instant(instant)
	Pipeline.tall_sighting_of(
		placed_bird,
		{
			road: view.road,
			place: Ahead(position),
			size_test: Pipeline.scenery_test(view),
		},
	)
}
