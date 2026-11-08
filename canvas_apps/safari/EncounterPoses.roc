## EncounterPoses says where each animal on the road in view stands, and how it
## is posed, at one instant of the ride. It reads only the ride's planned
## encounter, never a camera: the encounter on the rider's own segment is where
## its animation has got to, one on a segment ahead hasn't begun, and one on the
## segment behind ended before the rider left it, so it has no pose. A segment
## holds one encounter at most, a cat's or a bird's.
import Animation
import Geom
import Bird
import Cat
import RoadAhead
import SegmentPlace

EncounterPoses :: [].{

	## An animal on a segment in view: where that segment lies from the rider,
	## and where on it the animal stands and how it is posed.
	PlacedAnimal(kind) : { place : SegmentPlace, animal : Geom.Placed(kind) }

	## The cats on `road`, with the encounter on the rider's segment at
	## `encounter_stage`, in the order of `RoadAhead.segments_in_view`.
	cat_poses : RoadAhead.RoadView, Animation.Stage -> List(EncounterPoses.PlacedAnimal(Cat))
	cat_poses = |road, encounter_stage|
		RoadAhead.segments_in_view(road).keep_oks(
			|in_view| segment_cat({ in_view, encounter_stage }),
		)

	## The birds on `road`, with the encounter on the rider's segment at
	## `encounter_stage`, in the order of `RoadAhead.segments_in_view`.
	bird_poses : RoadAhead.RoadView, Animation.Stage -> List(EncounterPoses.PlacedAnimal(Bird))
	bird_poses = |road, encounter_stage|
		RoadAhead.segments_in_view(road).keep_oks(
			|in_view| segment_bird({ in_view, encounter_stage }),
		)
}

## The cat on a segment in view, if it has one that isn't over.
segment_cat : {
	in_view : RoadAhead.SegmentInView,
	encounter_stage : Animation.Stage,
} -> Try(EncounterPoses.PlacedAnimal(Cat), [NoPose])
segment_cat = |{ in_view, encounter_stage }|
	match in_view.segment.encounter {
		CatCrosses(crossing) =>
			posed_in_view(in_view, encounter_stage, |stage| crossing.cat_instant_at(stage))
		BirdHere(_) | QuietRoad => Err(NoPose)
	}

## The bird on a segment in view, if it has one that isn't over.
segment_bird : {
	in_view : RoadAhead.SegmentInView,
	encounter_stage : Animation.Stage,
} -> Try(EncounterPoses.PlacedAnimal(Bird), [NoPose])
segment_bird = |{ in_view, encounter_stage }|
	match in_view.segment.encounter {
		BirdHere(flight) =>
			posed_in_view(in_view, encounter_stage, |stage| flight.bird_instant_at(stage))
		CatCrosses(_) | QuietRoad => Err(NoPose)
	}

## The animal on a segment in view, shown by `animal_instant_at`, with the encounter on
## the rider's own segment at `rider_stage`: one ahead hasn't begun, and one
## behind is over, so it has no pose.
posed_in_view : RoadAhead.SegmentInView,
Animation.Stage,
(Animation.Stage -> Animation.Instant(pose)) -> Try(
	EncounterPoses.PlacedAnimal({ pose : pose }),
	[NoPose],
)
posed_in_view = |in_view, rider_stage, animal_instant_at| {
	posed = |stage|
		Ok({ place: in_view.place, animal: Animation.placed_instant(animal_instant_at(stage)) })
	match in_view.place {
		Ahead(position) =>
			if position == SegmentPlace.Position.first {
				posed(rider_stage)
			} else {
				posed(Waiting)
			}
		JustBehind => Err(NoPose)
	}
}
