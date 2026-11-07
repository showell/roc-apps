## Gawking is what a pig by the road does to the rider's speed. A rider who
## notices a pig that catches the eye slows for it, and stays slow to the end
## of the segment. The eyes' part, the look, is Gaze's.
import Billboard
import Distance
import Geom
import Motorcycle
import Segment
import Speed
import VehicleLimits

Gawking :: [].{

	## How far short of a pig the rider notices it, measured along the road.
	## The look and the gawking both start here.
	notice_distance : Distance
	notice_distance = Distance.metres(150.0)

	## The pig on `seg` that catches the rider's eye: the standout pig of a herd
	## the rider finds distracting. A herd the rider passes by catches no eye.
	eye_catching_pig : Segment -> [CatchesEye(Geom.Placed(Billboard)), NoPigCatchesEye]
	eye_catching_pig = |seg|
		match seg.segment_standout_pig() {
			Standout({ pig, interest: Distracting }) => CatchesEye(pig)
			Standout({ interest: Unnoticed, .. }) | NoPigs => NoPigCatchesEye
		}

	## The pig the rider is gawking at on this segment, if any. The gawking
	## starts where an eye-catching pig is noticed and asks only where the
	## motorcycle is, so it lasts past the pig to the end of the segment:
	## `gawk_brake` holds the rider down for as long as it lasts, so the rider
	## doesn't open the throttle until the next segment.
	gawked_pig : Motorcycle, Segment -> [GawkingAt(Geom.Placed(Billboard)), NotGawking]
	gawked_pig = |motorcycle, seg|
		match eye_catching_pig(seg) {
			CatchesEye(pig) if is_past_notice(motorcycle, pig) => GawkingAt(pig)
			CatchesEye(_) | NoPigCatchesEye => NotGawking
		}

	## Whether the rider is gawking at this segment's pig.
	is_gawking : Motorcycle, Segment -> Bool
	is_gawking = |motorcycle, seg|
		match gawked_pig(motorcycle, seg) {
			GawkingAt(_) => True
			NotGawking => False
		}

	## The brake for a gawking rider, who aims to be down to `gawk_speed` by
	## the settle distance before the pig.
	gawk_brake : Motorcycle, Segment -> VehicleLimits.Limit
	gawk_brake = |motorcycle, seg|
		match gawked_pig(motorcycle, seg) {
			GawkingAt(pig) => {
				gap = pig.road_point.along.distance_from(motorcycle.route_place.along)
				room = gap.minus(gawk_settle_distance)
				AtMost(
					motorcycle.speed.acceleration_to({
						target: gawk_speed,
						within: room.max(gawk_least_distance),
					}),
				)
			}
			NotGawking => NoLimit
		}
}

## Whether the motorcycle has reached the place where `pig` is noticed.
is_past_notice : Motorcycle, Geom.Placed(Billboard) -> Bool
is_past_notice = |motorcycle, pig|
	motorcycle.route_place.along >= pig.road_point.along.minus(Gawking.notice_distance)

## The speed a gawking rider brakes down to.
gawk_speed : Speed
gawk_speed = Speed.metres_a_step(0.2)

## How far short of the pig a gawking rider aims to reach `gawk_speed`.
gawk_settle_distance : Distance
gawk_settle_distance = Distance.metres(25.0)

## The shortest distance the brake for a pig is worked out over. Past the
## settle distance the rider is still coming down to `gawk_speed`, so the
## brake keeps working at this distance's strength. Throttle's bend limit
## has a different guard, which lets go at its commit point: a rider who
## reaches a bend has no more road to brake on, and a rider who reaches
## the pig has the rest of the segment.
gawk_least_distance : Distance
gawk_least_distance = Distance.metres(1.0)
