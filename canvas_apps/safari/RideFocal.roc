## The lens the ride is seen through. The view widens as the rider leans,
## and as the rider's attention is caught, by an encounter on the road or by a
## look to the side.
import Pixels
import Along
import Attention
import EncounterReaction
import Fraction
import Gaze
import Lens
import RiderState
import Route
import Segment
import World

RideFocal :: [].{

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : RiderState, Route -> Pixels
	ride_focal = |rider, route| {
		seg = route.segment_at(rider.segment_index)
		attention =
			EncounterReaction.encounter_attention(seg, rider.motorcycle)
				.max(Gaze.gaze_attention(rider.eyes.look_depth))
		Lens.cam_focal({ lean: rider.motorcycle.lean, attention })
	}
}

## The route's first three segments, a route of their own, with a cat crossing
## the second.
cat_route : Route
cat_route = Route.from_segments([
	World.route.segment_at(Route.SegmentIndex.first),
	cat_segment,
	{ ..World.route.segment_at(Route.SegmentIndex.number(2)), ending: RouteEnds },
])

## The second segment, with a cat crossing it.
cat_segment : Segment
cat_segment = {
	..World.route.segment_at(Route.SegmentIndex.number(1)),
	encounter: World.route.segment_at(Route.SegmentIndex.number(3)).encounter,
}

## A rider at the start of the first segment, upright and looking ahead.
upright : RiderState
upright = RiderState.initial

## A rider 120 m along a segment: near enough to its cat, if it has one, to
## notice it.
rider_near_cat_on : U32 -> RiderState
rider_near_cat_on = |number| {
	segment_index: Route.SegmentIndex.number(number),
	motorcycle: { ..upright.motorcycle, along: Along.metres(120.0) },
	eyes: upright.eyes,
}

## The same rider leaning `lean`.
leaning = |rider, lean| { ..rider, motorcycle: { ..rider.motorcycle, lean } }

## The same rider as deep into a look as a rider goes.
looking_hard : RiderState -> RiderState
looking_hard = |rider| { ..rider, eyes: { ..rider.eyes, look_depth: Fraction.whole } }

## How strongly the encounter on this rider's segment holds their attention.
encounter_attention_of : RiderState -> F64
encounter_attention_of = |rider|
	EncounterReaction.encounter_attention(
		cat_route.segment_at(rider.segment_index),
		rider.motorcycle,
	).to_f64()

## Whether a segment has a cat waiting by the road.
has_cat : Segment -> Bool
has_cat = |seg|
	match seg.encounter {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

expect !has_cat(World.route.segment_at(Route.SegmentIndex.number(0)))
expect has_cat(cat_segment)

expect RideFocal.ride_focal(upright, cat_route).minus(Lens.resting_focal) == Pixels.zero
expect encounter_attention_of(upright) == 0.0
expect Gaze.gaze_attention(Fraction.zero).to_f64() == 0.0
expect Lens.cam_focal({
	lean: upright.motorcycle.lean,
	attention: Attention.none,
}).minus(Lens.resting_focal) == Pixels.zero

# RideFocal doesn't import Angle, so these leans are made from `Lens.full_lean`.
focal_at_lean = |lean| RideFocal.ride_focal(leaning(upright, lean), cat_route)

no_lean = upright.motorcycle.lean

## The change from upright to the full lean.
full_change = Lens.full_lean.change_from(no_lean)

## The full lean, to the left.
full_left = no_lean.minus(full_change)

expect {
	half = no_lean.halfway_to(Lens.full_lean)
	focal_at_lean(half) < focal_at_lean(no_lean)
		and focal_at_lean(Lens.full_lean) < focal_at_lean(half)
		and focal_at_lean(full_left) < focal_at_lean(no_lean)
		and focal_at_lean(no_lean) <= Lens.resting_focal
}

# A lean past the greatest one widens the view no further.
expect focal_at_lean(Lens.full_lean) == focal_at_lean(full_left)

expect {
	twice = Lens.full_lean.plus(full_change)
	twice_change = twice.change_from(no_lean)
	ten_times = twice.plus(twice_change).plus(twice_change).plus(twice_change).plus(twice_change)
	focal_at_lean(twice).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
		and focal_at_lean(ten_times).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
}

expect encounter_attention_of(rider_near_cat_on(1)) > 0.0
expect !(encounter_attention_of({ ..upright, segment_index: Route.SegmentIndex.number(1) }) > 0.0)
expect !(encounter_attention_of(rider_near_cat_on(0)) > 0.0)
expect
	RideFocal.ride_focal(rider_near_cat_on(1), cat_route)
		< RideFocal.ride_focal(rider_near_cat_on(0), cat_route)
expect
	RideFocal.ride_focal(looking_hard(upright), cat_route)
		< RideFocal.ride_focal(upright, cat_route)
expect {
	half_look = { ..upright, eyes: { ..upright.eyes, look_depth: Fraction.of(0.5) } }
	RideFocal.ride_focal(looking_hard(upright), cat_route)
		< RideFocal.ride_focal(half_look, cat_route)
}
expect Gaze.gaze_attention(Fraction.whole).to_f64() > Gaze.gaze_attention(Fraction.zero).to_f64()

both : Pixels
both = RideFocal.ride_focal(looking_hard(leaning(upright, Lens.full_lean)), cat_route)

lean_only : Pixels
lean_only = RideFocal.ride_focal(leaning(upright, Lens.full_lean), cat_route)

gaze_only : Pixels
gaze_only = RideFocal.ride_focal(looking_hard(upright), cat_route)

expect both <= lean_only
expect both <= gaze_only
expect
	both.to_f64().to_bits()
		== lean_only.to_f64().min(gaze_only.to_f64()).to_bits()
expect lean_only.plus(gaze_only) > both
expect both.to_f64() - lean_only.to_f64().min(gaze_only.to_f64()) == 0.0
expect Lens.cam_focal({
	lean: Lens.full_lean,
	attention: Attention.none,
}).minus(lean_only) == Pixels.zero
