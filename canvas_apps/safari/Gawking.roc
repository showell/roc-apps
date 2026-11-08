## Gawking is what a pig by the road does to the rider's speed. A rider who
## notices a pig that catches the eye slows for it, and stays slow to the end
## of the segment. The noticing and the look are the eyes', and Gaze's.
import Distance
import Gaze
import Motorcycle
import Segment
import Speed
import ThrottleLimit
import VehicleLimits

Gawking :: [].{

	## Whether the rider is gawking: whether they have noticed this segment's
	## pig.
	is_gawking : Motorcycle, Segment -> Bool
	is_gawking = |motorcycle, segment|
		match Gaze.noticed_pig(motorcycle, segment) {
			Noticed(_) => True
			NothingNoticed => False
		}

	## The brake for a gawking rider, who aims to be down to `gawk_speed` by
	## the settle distance before the pig. The noticing lasts to the end of
	## the segment, so the brake holds the rider down until the next one.
	gawk_brake : Motorcycle, Segment -> ThrottleLimit
	gawk_brake = |motorcycle, segment|
		match Gaze.noticed_pig(motorcycle, segment) {
			Noticed(pig) => {
				gap = pig.road_point.along.distance_from(motorcycle.route_place.along)
				room = gap.minus(gawk_settle_distance)
				AtMost(
					VehicleLimits.braking_to(
						motorcycle.speed,
						{ target: gawk_speed, within: room.max(gawk_least_distance) },
					),
				)
			}
			NothingNoticed => NoLimit
		}
}

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
