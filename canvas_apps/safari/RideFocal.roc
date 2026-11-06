## The lens the ride is seen through. The view widens as the rider leans,
## and as the rider's attention is caught, by a crossing on the road or by a
## look to the side.
import Attention
import Bike
import CrossingReaction
import lib.DeviceMath
import Fraction
import Gaze
import Lens
import RiderState
import World

RideFocal :: [].{

	## How strongly the crossing on the rider's segment holds their attention.
	crossing_attention : List(World.Segment), RiderState -> Attention
	crossing_attention = |world, rider|
		CrossingReaction.reaction_to(rider.segment.segment_in(world), rider).eye_pull

	## The camera's focal length for where the rider is and how they ride.
	ride_focal : List(World.Segment), RiderState -> F64
	ride_focal = |world, rider| {
		lean_frac = Fraction.clamp(
			(DeviceMath.real_abs(rider.lean.to_radians()) / Bike.max_lean.to_radians()),
		)
		attention = crossing_attention(world, rider).max(Gaze.gaze_focus(rider.focus))
		Lens.cam_focal({ lean_frac, attention })
	}
}

segs : List(World.Segment)
segs = [World.route_segment(0), cat_segment, World.route_segment(2)]

## The second segment, with a cat crossing it.
cat_segment : World.Segment
cat_segment = { ..World.route_segment(1), crossing: World.route_segment(3).crossing }

## A rider at the start of the first segment, upright and looking ahead.
upright : RiderState
upright = RiderState.initial

## A rider 120 m along a segment: near enough to its cat, if it has one, to
## notice it. RideFocal doesn't import Along or Distance, so the place is made
## from Gaze's distance.
near_cat_on : U32 -> RiderState
near_cat_on = |number| {
	..upright,
	segment: World.SegmentIndex.number(number),
	along: upright.along.plus(Gaze.gaze_look_dist.times(0.8)),
}

expect near_cat_on(1).along.to_metres() == 120.0

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.crossing {
		CatCrosses(_) => True
		BirdFlies(_) | QuietRoad => False
	}

expect !has_cat(World.route_segment(0))
expect has_cat(cat_segment)

expect RideFocal.ride_focal(segs, upright) - Lens.focal == 0.0
expect RideFocal.crossing_attention(segs, upright).to_f64() == 0.0
expect Gaze.gaze_focus(Fraction.zero).to_f64() == 0.0
expect Lens.cam_focal({ lean_frac: Fraction.zero, attention: Attention.none }) - Lens.focal == 0.0

# RideFocal doesn't import Angle, so these leans are made from `Bike.max_lean`.
focal_at_lean = |lean| RideFocal.ride_focal(segs, { ..upright, lean })

expect {
	half = upright.lean.halfway_to(Bike.max_lean)
	focal_at_lean(half) < focal_at_lean(upright.lean)
		and focal_at_lean(Bike.max_lean) < focal_at_lean(half)
		and focal_at_lean(upright.lean.minus(Bike.max_lean)) < focal_at_lean(upright.lean)
		and focal_at_lean(upright.lean) <= Lens.focal
}

# A lean past the greatest one widens the view no further.
expect focal_at_lean(Bike.max_lean) - focal_at_lean(upright.lean.minus(Bike.max_lean)) == 0.0

expect {
	twice = Bike.max_lean.plus(Bike.max_lean)
	ten_times = twice.plus(twice).plus(twice).plus(twice).plus(twice)
	focal_at_lean(twice) - focal_at_lean(Bike.max_lean) == 0.0
		and focal_at_lean(ten_times) - focal_at_lean(Bike.max_lean) == 0.0
}

expect RideFocal.crossing_attention(segs, near_cat_on(1)).to_f64() > 0.0
expect !(
	RideFocal.crossing_attention(
		segs,
		{ ..upright, segment: World.SegmentIndex.number(1) },
	).to_f64() > 0.0
)
expect !(RideFocal.crossing_attention(segs, near_cat_on(0)).to_f64() > 0.0)
expect RideFocal.ride_focal(segs, near_cat_on(1)) < RideFocal.ride_focal(segs, near_cat_on(0))
expect RideFocal.ride_focal(
	segs,
	{ ..upright, focus: Fraction.whole },
) < RideFocal.ride_focal(segs, upright)
expect RideFocal.ride_focal(
	segs,
	{ ..upright, focus: Fraction.whole },
) < RideFocal.ride_focal(segs, { ..upright, focus: Fraction.of(0.5) })
expect Gaze.gaze_focus(Fraction.whole).to_f64() > Gaze.gaze_focus(Fraction.zero).to_f64()

both : F64
both = RideFocal.ride_focal(segs, { ..upright, lean: Bike.max_lean, focus: Fraction.whole })

lean_only : F64
lean_only = RideFocal.ride_focal(segs, { ..upright, lean: Bike.max_lean })

gaze_only : F64
gaze_only = RideFocal.ride_focal(segs, { ..upright, focus: Fraction.whole })

expect both <= lean_only
expect both <= gaze_only
expect F64.to_bits(both) == F64.to_bits(DeviceMath.real_min(lean_only, gaze_only))
expect (lean_only + gaze_only) > both
expect both - DeviceMath.real_min(lean_only, gaze_only) == 0.0
expect Lens.cam_focal({ lean_frac: Fraction.whole, attention: Attention.none }) - lean_only == 0.0
