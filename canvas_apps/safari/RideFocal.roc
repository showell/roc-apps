## The lens the ride is seen through. The view widens as the rider leans,
## and as the rider's attention is caught, by a crossing on the road or by a
## look to the side.
import Pixels
import Along
import Attention
import CrossingReaction
import Fraction
import Gaze
import Lens
import RiderState
import World

RideFocal :: [].{

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : RiderState, List(World.Segment) -> Pixels
	ride_focal = |rider, route_segments| {
		seg = rider.segment_index.segment_in(route_segments)
		attention =
			CrossingReaction.crossing_attention(seg, rider.motorcycle)
				.max(Gaze.gaze_attention(rider.eyes.look_depth))
		Lens.cam_focal({ lean: rider.motorcycle.lean, attention })
	}
}

route_segments : List(World.Segment)
route_segments = [World.route_segment(0), cat_segment, World.route_segment(2)]

## The second segment, with a cat crossing it.
cat_segment : World.Segment
cat_segment = { ..World.route_segment(1), crossing: World.route_segment(3).crossing }

## A rider at the start of the first segment, upright and looking ahead.
upright : RiderState
upright = RiderState.initial

## A rider 120 m along a segment: near enough to its cat, if it has one, to
## notice it.
rider_near_cat_on : U32 -> RiderState
rider_near_cat_on = |number| {
	segment_index: World.SegmentIndex.number(number),
	motorcycle: { ..upright.motorcycle, along: Along.metres(120.0) },
	eyes: upright.eyes,
}

## The same rider leaning `lean`.
leaning = |rider, lean| { ..rider, motorcycle: { ..rider.motorcycle, lean } }

## The same rider as deep into a look as a rider goes.
looking_hard : RiderState -> RiderState
looking_hard = |rider| { ..rider, eyes: { ..rider.eyes, look_depth: Fraction.whole } }

## How strongly the crossing on this rider's segment holds their attention.
crossing_attention_of : RiderState -> F64
crossing_attention_of = |rider|
	CrossingReaction.crossing_attention(
		rider.segment_index.segment_in(route_segments),
		rider.motorcycle,
	).to_f64()

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.crossing {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

expect !has_cat(World.route_segment(0))
expect has_cat(cat_segment)

expect RideFocal.ride_focal(upright, route_segments).minus(Lens.resting_focal) == Pixels.zero
expect crossing_attention_of(upright) == 0.0
expect Gaze.gaze_attention(Fraction.zero).to_f64() == 0.0
expect Lens.cam_focal({
	lean: upright.motorcycle.lean,
	attention: Attention.none,
}).minus(Lens.resting_focal) == Pixels.zero

# RideFocal doesn't import Angle, so these leans are made from `Lens.full_lean`.
focal_at_lean = |lean| RideFocal.ride_focal(leaning(upright, lean), route_segments)

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

expect crossing_attention_of(rider_near_cat_on(1)) > 0.0
expect !(crossing_attention_of({ ..upright, segment_index: World.SegmentIndex.number(1) }) > 0.0)
expect !(crossing_attention_of(rider_near_cat_on(0)) > 0.0)
expect
	RideFocal.ride_focal(rider_near_cat_on(1), route_segments)
		< RideFocal.ride_focal(rider_near_cat_on(0), route_segments)
expect
	RideFocal.ride_focal(looking_hard(upright), route_segments)
		< RideFocal.ride_focal(upright, route_segments)
expect {
	half_look = { ..upright, eyes: { ..upright.eyes, look_depth: Fraction.of(0.5) } }
	RideFocal.ride_focal(looking_hard(upright), route_segments)
		< RideFocal.ride_focal(half_look, route_segments)
}
expect Gaze.gaze_attention(Fraction.whole).to_f64() > Gaze.gaze_attention(Fraction.zero).to_f64()

both : Pixels
both = RideFocal.ride_focal(looking_hard(leaning(upright, Lens.full_lean)), route_segments)

lean_only : Pixels
lean_only = RideFocal.ride_focal(leaning(upright, Lens.full_lean), route_segments)

gaze_only : Pixels
gaze_only = RideFocal.ride_focal(looking_hard(upright), route_segments)

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
