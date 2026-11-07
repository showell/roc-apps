## EncounterSighting finds the animals the rider can see on the road in a
## frame: a cat on a segment in view, or a Roc bird there, each placed where its
## animation has got to, if it is in front of the camera and tall enough on
## screen to draw. A segment holds one encounter at most, a cat's or a bird's.
## Only the encounter on the rider's own segment plays; one on a segment ahead
## hasn't begun, and one on the segment behind ended before the rider left it,
## so it isn't looked for.
import Animation
import BirdFlight
import Cat
import RoadAhead
import Geom
import Pipeline
import Pixels
import PosedBird
import PosedCat
import SegmentPlace

EncounterSighting :: [].{

	## The cats in view, with the encounter on the rider's segment at
	## `encounter`, in the order of `RoadAhead.segments_in_view`.
	cats_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		encounter : Animation.Timing,
	} -> List(Pipeline.Sighted(PosedCat))
	cats_in_view = |road, { camera, encounter }|
		RoadAhead.segments_in_view(road)
			.keep_oks(|in_view| segment_cat(road, { camera, in_view, encounter }))

	## The birds in view, with the encounter on the rider's segment at
	## `encounter`, in the order of `RoadAhead.segments_in_view`.
	birds_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		encounter : Animation.Timing,
	} -> List(Pipeline.Sighted(PosedBird))
	birds_in_view = |road, { camera, encounter }|
		RoadAhead.segments_in_view(road)
			.keep_oks(|in_view| segment_bird(road, { camera, in_view, encounter }))

	## The cat on a segment in view, if it has one and it is in view.
	segment_cat : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
		in_view : RoadAhead.SegmentInView,
		encounter : Animation.Timing,
	} -> Try(Pipeline.Sighted(PosedCat), [NoCat, Over, BehindCamera, TooSmall])
	segment_cat = |road, { camera, in_view, encounter }|
		match in_view.segment.encounter {
			CatCrosses(crossing) => {
				stage = segment_stage(in_view, Cat.crossing_stage(encounter))?
				placed_cat : Geom.Placed(PosedCat)
				placed_cat = Animation.placed_instant(Cat.instant_at(crossing, stage))
				Pipeline.scenery_sighting_of(placed_cat, { road, camera, place: in_view.place })
			}
			BirdHere(_) | QuietRoad => Err(NoCat)
		}
}

## The bird of a segment in view, if that segment has one and it is in view.
segment_bird : RoadAhead.RoadView,
{
	camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
	in_view : RoadAhead.SegmentInView,
	encounter : Animation.Timing,
} -> Try(Pipeline.Sighted(PosedBird), [NoBird, Over, BehindCamera, TooSmall])
segment_bird = |road, { camera, in_view, encounter }|
	match in_view.segment.encounter {
		BirdHere(flight) => {
			stage = segment_stage(in_view, BirdFlight.flight_stage(encounter))?
			placed_bird : Geom.Placed(PosedBird)
			placed_bird = Animation.placed_instant(BirdFlight.instant_at(flight, stage))
			Pipeline.scenery_sighting_of(placed_bird, { road, camera, place: in_view.place })
		}
		CatCrosses(_) | QuietRoad => Err(NoBird)
	}

## Where the encounter on a segment in view has got to, with the one on the
## rider's own segment at `rider_stage`: one ahead hasn't begun, and one behind
## is over.
segment_stage : RoadAhead.SegmentInView, Animation.Stage -> Try(Animation.Stage, [Over])
segment_stage = |in_view, rider_stage|
	match in_view.place {
		Ahead(position) =>
			if position == SegmentPlace.Position.first {
				Ok(rider_stage)
			} else {
				Ok(Waiting)
			}
		JustBehind => Err(Over)
	}
