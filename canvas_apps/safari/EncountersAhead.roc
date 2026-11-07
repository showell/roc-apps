## EncountersAhead is where the animals on the road have got to at one instant
## of the ride, worked out from the rider alone before any camera looks: a cat
## crossing and a bird flying as the rider closes on them. The animal moves
## first and the rider reacts to where it has got to, so EncounterReaction reads
## this, and the sightings only find where the camera sees each animal.
import Along
import Animation
import BirdFlight
import Cat
import Geom
import PosedBird
import PosedCat
import RoadAhead
import Route
import SegmentPlace
import Speed

EncountersAhead := {
	cats : List(EncountersAhead.AnimalAhead(PosedCat)),
	birds : List(EncountersAhead.AnimalAhead(PosedBird)),
}.{

	## An animal on a segment in view of the rider: where that segment lies from
	## the rider, how the rider comes on the animal, and where the animal stands
	## and how it is posed.
	AnimalAhead(pose) : {
		place : SegmentPlace,
		approach : Animation.Approach,
		placed : Geom.Placed(pose),
	}

	## The animals on the segments in view of `rider` on `route`, in the order of
	## `RoadAhead.segments_in_view`.
	encounters_ahead : Route,
	{
		segment_index : Route.SegmentIndex,
		motorcycle : { along : Along, speed : Speed, .. },
		..,
	} -> EncountersAhead
	encounters_ahead = |route, rider| {
		road = RoadAhead.RoadView.ahead_of(route, rider.segment_index)
		segments_in_view = RoadAhead.segments_in_view(road)
		approach_at : RoadAhead.SegmentInView, Along -> Animation.Approach
		approach_at = |in_view, along| {
			gap: RoadAhead.gap_to_segment(road, { rider: rider.motorcycle, in_view })
				.plus(along.from_start()),
			speed: rider.motorcycle.speed,
		}
		{
			cats: segments_in_view.join_map(
				|in_view|
					match in_view.segment.encounter {
						CatCrosses(crossing) => {
							approach = approach_at(in_view, crossing.along)
							instant = Cat.instant_at(crossing, approach)
							[
								{
									place: in_view.place,
									approach,
									placed: Animation.placed_instant(instant),
								},
							]
						}
						BirdHere(_) | QuietRoad => []
					},
			),
			birds: segments_in_view.join_map(
				|in_view|
					match in_view.segment.encounter {
						BirdHere(habit) => {
							approach = approach_at(in_view, habit.perch.road_point.along)
							instant = BirdFlight.habit_instant_at(habit, approach)
							[
								{
									place: in_view.place,
									approach,
									placed: Animation.placed_instant(instant),
								},
							]
						}
						CatCrosses(_) | QuietRoad => []
					},
			),
		}
	}

	## How the rider comes on the cat on their own segment, if it has one.
	rider_cat_approach : EncountersAhead -> Try(Animation.Approach, [NoCat])
	rider_cat_approach = |encounters|
		match encounters.cats.find_first(|cat| cat.place == Ahead(SegmentPlace.Position.first)) {
			Ok(cat) => Ok(cat.approach)
			Err(NotFound) => Err(NoCat)
		}
}
