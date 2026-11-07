## EncounterSighting finds the animals the rider can see on the road in a
## frame: a cat waiting on a segment in view, or a Roc bird perched there, each
## placed where its crossing has got to, if it is in front of the camera and
## tall enough on screen to draw. A segment holds one encounter at most, a cat's
## or a bird's.
import Along
import Animation
import BirdFlight
import Cat
import Distance
import RoadAhead
import Geom
import Pipeline
import Pixels
import PosedBird
import PosedCat
import Speed

EncounterSighting :: [].{

	## The cats in view of a rider at `speed`, in the order of
	## `RoadAhead.segments_in_view`.
	cats_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		speed : Speed,
	} -> List(Pipeline.Sighted(PosedCat))
	cats_in_view = |road, { camera, speed }|
		RoadAhead.segments_in_view(road)
			.keep_oks(|in_view| segment_cat(road, { camera, in_view, speed }))

	## The birds in view, in the order of `RoadAhead.segments_in_view`.
	birds_in_view : RoadAhead.RoadView,
	{
		vantage : Geom.Vantage,
		cam_focal : Pixels,
		..,
	} -> List(Pipeline.Sighted(PosedBird))
	birds_in_view = |road, camera|
		RoadAhead.segments_in_view(road)
			.keep_oks(|in_view| segment_bird(road, { camera, in_view }))

	## The cat waiting on a segment in view, if it has one and it is in view.
	segment_cat : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		in_view : RoadAhead.SegmentInView,
		speed : Speed,
	} -> Try(Pipeline.Sighted(PosedCat), [NoCat, BehindCamera, TooSmall])
	segment_cat = |road, { camera, in_view, speed }|
		match in_view.segment.encounter {
			CatCrosses(crossing) => {
				placed_cat : Distance -> Geom.Placed(PosedCat)
				placed_cat = |gap| {
					instant = Cat.instant_at(crossing, { gap, speed })
					Animation.placed_instant(instant)
				}
				encounter_in_view(
					road,
					{
						camera,
						in_view,
						along: crossing.along,
						placed_at: placed_cat,
					},
				)
			}
			BirdHere(_) | QuietRoad => Err(NoCat)
		}
}

## The bird of a segment in view, if that segment has one and it is in view.
segment_bird : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
	in_view : RoadAhead.SegmentInView,
} -> Try(Pipeline.Sighted(PosedBird), [NoBird, BehindCamera, TooSmall])
segment_bird = |road, { camera, in_view }|
	match in_view.segment.encounter {
		BirdHere(habit) => {
			placed_bird : Distance -> Geom.Placed(PosedBird)
			placed_bird = |gap| {
				instant = BirdFlight.habit_instant_at(habit, { gap: gap })
				Animation.placed_instant(instant)
			}
			encounter_in_view(
				road,
				{
					camera,
					in_view,
					along: habit.perch.road_point.along,
					placed_at: placed_bird,
				},
			)
		}
		CatCrosses(_) | QuietRoad => Err(NoBird)
	}

## The animal a segment in view holds, `along` it, placed as `placed_at`
## finds it with the rider that far short of it, if it is in view.
encounter_in_view : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
	in_view : RoadAhead.SegmentInView,
	along : Along,
	placed_at : Distance -> Geom.Placed(kind),
} -> Try(Pipeline.Sighted(kind), [BehindCamera, TooSmall])
	where [kind.scenery_height : kind -> Distance]
encounter_in_view = |road, { camera, in_view, along, placed_at }| {
	gap = RoadAhead.gap_to_segment(
		road,
		{ vantage: camera.vantage, in_view },
	).plus(along.from_start())
	Pipeline.scenery_sighting_of(placed_at(gap), { road, camera, place: in_view.place })
}
