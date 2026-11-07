## CrossingSighting finds the animals the rider can see crossing the road in a
## frame: a cat waiting on a segment of the road ahead, or a Roc bird perched
## there, each placed where its crossing has got to, if it is in front of the
## camera and tall enough on screen to draw. A segment holds one crossing at
## most, a cat's or a bird's.
import Animation
import BirdFlight
import Cat
import Distance
import RoadAhead
import Geom
import Pipeline
import PosedBird
import PosedCat
import Speed

CrossingSighting :: [].{

	## The cats in view of a rider at `speed`, the nearest segment's first.
	## Only the road ahead is searched, because a cat crosses along its
	## segment, and the segment just behind is one the rider has passed.
	cats_in_view : RoadAhead.CameraView, Speed -> List(Pipeline.Sighted(PosedCat))
	cats_in_view = |view, speed| {
		positions = RoadAhead.Position.positions_in(view.road.segments_ahead)
		positions.keep_oks(|position| segment_cat(view, { position, speed }))
	}

	## The birds in view, the nearest segment's first. Only the road ahead is
	## searched, because a bird flies along its segment, and the segment just
	## behind is one the rider has passed.
	birds_in_view : RoadAhead.CameraView -> List(Pipeline.Sighted(PosedBird))
	birds_in_view = |view| {
		positions = RoadAhead.Position.positions_in(view.road.segments_ahead)
		positions.keep_oks(|position| segment_bird(view, position))
	}

	## The cat waiting on the segment at `position` on the road ahead, if it has
	## one and it is in view.
	segment_cat : RoadAhead.CameraView,
	{
		position : RoadAhead.Position,
		speed : Speed,
	} -> Try(Pipeline.Sighted(PosedCat), [NoCat, BehindCamera, TooSmall])
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
} -> Try(Pipeline.Sighted(PosedCat), [BehindCamera, TooSmall])
cat_in_view = |view, { position, crossing, speed }| {
	gap = RoadAhead.gap_to_segment(view.road, position)
	instant = Cat.instant_at(crossing, { gap: gap.plus(crossing.along.from_start()), speed })
	placed_cat : Geom.Placed(PosedCat)
	placed_cat = Animation.placed_instant(instant)
	animal_in_view(view, { position, animal: placed_cat })
}

## The bird of the segment at `position` on the road ahead, if that segment
## has one and it is in view.
segment_bird : RoadAhead.CameraView,
RoadAhead.Position -> Try(
	Pipeline.Sighted(PosedBird),
	[NoBird, BehindCamera, TooSmall],
)
segment_bird = |view, position|
	match RoadAhead.segment_at(view.road, position).crossing {
		BirdHere(habit) => {
			gap_to_segment = RoadAhead.gap_to_segment(view.road, position)
			gap_to_tree = gap_to_segment.plus(BirdFlight.start_along(habit).from_start())
			instant = BirdFlight.habit_instant_at(habit, { gap: gap_to_tree })
			placed_bird : Geom.Placed(PosedBird)
			placed_bird = Animation.placed_instant(instant)
			animal_in_view(view, { position, animal: placed_bird })
		}
		CatCrosses(_) | QuietRoad => Err(NoBird)
	}

## An animal placed on the segment at `position` on the road ahead, if it is
## in view. Its size is tested through the camera's own lens, as a tree's is.
animal_in_view : RoadAhead.CameraView,
{
	position : RoadAhead.Position,
	animal : Geom.Placed(kind),
} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
	where [kind.scenery_height : kind -> Distance]
animal_in_view = |view, { position, animal }|
	Pipeline.tall_sighting_of(
		animal,
		{
			road: view.road,
			place: Ahead(position),
			size_test: Pipeline.scenery_test(view),
		},
	)
