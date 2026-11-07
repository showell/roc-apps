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

	## How strongly the crossing on the rider's segment holds their attention.
	crossing_attention : List(World.Segment), RiderState -> Attention
	crossing_attention = |route_segments, rider|
		CrossingReaction.reaction_to(
			rider.segment_index.segment_in(route_segments),
			rider,
		).attention

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : List(World.Segment), RiderState -> Pixels
	ride_focal = |route_segments, rider| {
		lean_fraction = Fraction.clamp(rider.lean.to_radians().abs() / Lens.full_lean.to_radians())
		attention = crossing_attention(
			route_segments,
			rider,
		).max(Gaze.gaze_attention(rider.look_depth))
		Lens.cam_focal({ lean_fraction, attention })
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
	..upright,
	segment_index: World.SegmentIndex.number(number),
	along: Along.metres(120.0),
}

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.crossing {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

expect !has_cat(World.route_segment(0))
expect has_cat(cat_segment)

expect RideFocal.ride_focal(route_segments, upright).minus(Lens.focal) == Pixels.zero
expect RideFocal.crossing_attention(route_segments, upright).to_f64() == 0.0
expect Gaze.gaze_attention(Fraction.zero).to_f64() == 0.0
expect Lens.cam_focal({
	lean_fraction: Fraction.zero,
	attention: Attention.none,
}).minus(Lens.focal) == Pixels.zero

# RideFocal doesn't import Angle, so these leans are made from `Lens.full_lean`.
focal_at_lean = |lean| RideFocal.ride_focal(route_segments, { ..upright, lean })

expect {
	half = upright.lean.halfway_to(Lens.full_lean)
	focal_at_lean(half) < focal_at_lean(upright.lean)
		and focal_at_lean(Lens.full_lean) < focal_at_lean(half)
		and focal_at_lean(upright.lean.minus(Lens.full_lean)) < focal_at_lean(upright.lean)
		and focal_at_lean(upright.lean) <= Lens.focal
}

# A lean past the greatest one widens the view no further.
expect focal_at_lean(Lens.full_lean) == focal_at_lean(upright.lean.minus(Lens.full_lean))

expect {
	twice = Lens.full_lean.plus(Lens.full_lean)
	ten_times = twice.plus(twice).plus(twice).plus(twice).plus(twice)
	focal_at_lean(twice).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
		and focal_at_lean(ten_times).minus(focal_at_lean(Lens.full_lean)) == Pixels.zero
}

expect RideFocal.crossing_attention(route_segments, rider_near_cat_on(1)).to_f64() > 0.0
expect !(
	RideFocal.crossing_attention(
		route_segments,
		{ ..upright, segment_index: World.SegmentIndex.number(1) },
	).to_f64() > 0.0
)
expect !(RideFocal.crossing_attention(route_segments, rider_near_cat_on(0)).to_f64() > 0.0)
expect
	RideFocal.ride_focal(route_segments, rider_near_cat_on(1))
		< RideFocal.ride_focal(route_segments, rider_near_cat_on(0))
expect RideFocal.ride_focal(
	route_segments,
	{ ..upright, look_depth: Fraction.whole },
) < RideFocal.ride_focal(route_segments, upright)
expect RideFocal.ride_focal(
	route_segments,
	{ ..upright, look_depth: Fraction.whole },
) < RideFocal.ride_focal(route_segments, { ..upright, look_depth: Fraction.of(0.5) })
expect Gaze.gaze_attention(Fraction.whole).to_f64() > Gaze.gaze_attention(Fraction.zero).to_f64()

both : Pixels
both = RideFocal.ride_focal(
	route_segments,
	{ ..upright, lean: Lens.full_lean, look_depth: Fraction.whole },
)

lean_only : Pixels
lean_only = RideFocal.ride_focal(route_segments, { ..upright, lean: Lens.full_lean })

gaze_only : Pixels
gaze_only = RideFocal.ride_focal(route_segments, { ..upright, look_depth: Fraction.whole })

expect both <= lean_only
expect both <= gaze_only
expect
	both.to_f64().to_bits()
		== lean_only.to_f64().min(gaze_only.to_f64()).to_bits()
expect lean_only.plus(gaze_only) > both
expect both.to_f64() - lean_only.to_f64().min(gaze_only.to_f64()) == 0.0
expect Lens.cam_focal({
	lean_fraction: Fraction.whole,
	attention: Attention.none,
}).minus(lean_only) == Pixels.zero
