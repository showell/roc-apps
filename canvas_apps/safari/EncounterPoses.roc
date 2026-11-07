## EncounterPoses says where each animal on the road in view stands, and how it
## is posed, at one instant of the ride. It reads only the ride's planned
## encounter, never a camera: the encounter on the rider's own segment is where
## its animation has got to, one on a segment ahead hasn't begun, and one on the
## segment behind ended before the rider left it, so it has no pose. A segment
## holds one encounter at most, a cat's or a bird's.
import Animation
import BirdFlight
import Cat
import Geom
import PosedBird
import PosedCat
import RoadAhead
import SegmentPlace

EncounterPoses :: [].{

	## An animal on a segment in view: where that segment lies from the rider,
	## and where on it the animal stands and how it is posed.
	PosedAnimal(pose) : { place : SegmentPlace, placed : Geom.Placed(pose) }

	## The cats on `road`, with the encounter on the rider's segment at
	## `encounter_timing`, in the order of `RoadAhead.segments_in_view`.
	cat_poses : RoadAhead.RoadView, Animation.Timing -> List(EncounterPoses.PosedAnimal(PosedCat))
	cat_poses = |road, encounter_timing|
		RoadAhead.segments_in_view(road).keep_oks(
			|in_view| segment_cat({ in_view, encounter_timing }),
		)

	## The birds on `road`, with the encounter on the rider's segment at
	## `encounter_timing`, in the order of `RoadAhead.segments_in_view`.
	bird_poses : RoadAhead.RoadView, Animation.Timing -> List(EncounterPoses.PosedAnimal(PosedBird))
	bird_poses = |road, encounter_timing|
		RoadAhead.segments_in_view(road).keep_oks(
			|in_view| segment_bird({ in_view, encounter_timing }),
		)
}

## The cat on a segment in view, if it has one that isn't over.
segment_cat : {
	in_view : RoadAhead.SegmentInView,
	encounter_timing : Animation.Timing,
} -> Try(EncounterPoses.PosedAnimal(PosedCat), [NoCat, Over])
segment_cat = |{ in_view, encounter_timing }|
	match in_view.segment.encounter {
		CatCrosses(crossing) => {
			stage = segment_stage(in_view, Cat.crossing_stage(encounter_timing))?
			Ok({
				place: in_view.place,
				placed: Animation.placed_instant(Cat.instant_at(crossing, stage)),
			})
		}
		BirdHere(_) | QuietRoad => Err(NoCat)
	}

## The bird on a segment in view, if it has one that isn't over.
segment_bird : {
	in_view : RoadAhead.SegmentInView,
	encounter_timing : Animation.Timing,
} -> Try(EncounterPoses.PosedAnimal(PosedBird), [NoBird, Over])
segment_bird = |{ in_view, encounter_timing }|
	match in_view.segment.encounter {
		BirdHere(flight) => {
			stage = segment_stage(in_view, BirdFlight.flight_stage(encounter_timing))?
			Ok({
				place: in_view.place,
				placed: Animation.placed_instant(BirdFlight.instant_at(flight, stage)),
			})
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
