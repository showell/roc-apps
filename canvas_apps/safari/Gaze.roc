## What the rider notices, and where the rider looks. A pig by the road catches
## the rider's eye, and once the rider is near enough to notice it the gaze
## swivels toward it. The pig passes out of sight to the side while it is still
## ahead, and the gaze turns back to the road.
##
## Two words keep the eyes and the throttle apart. A look is what the eyes do,
## and it ends once the pig is too far round. Gawking is what the speed does,
## and it lasts to the end of the segment; it is Gawking's, which reads the
## noticing from here.
import Angle
import Billboard
import Distance
import Geom
import Motorcycle
import Segment

Gaze :: [].{

	## How far short of a pig the rider notices it, measured along the road.
	## The look and the gawking both start here.
	notice_distance : Distance
	notice_distance = Distance.metres(150.0)

	## The pig on `segment` that catches the rider's eye: the standout pig of a herd
	## the rider finds distracting. A herd the rider passes by catches no eye.
	eye_catching_pig : Segment -> [CatchesEye(Geom.Placed(Billboard)), NoPigCatchesEye]
	eye_catching_pig = |segment|
		match segment.segment_standout_pig() {
			Standout({ pig, interest: Distracting }) => CatchesEye(pig)
			Standout({ interest: Unnoticed, .. }) | NoPigs => NoPigCatchesEye
		}

	## The pig the rider has noticed on this segment, if any. The noticing
	## starts where an eye-catching pig is `notice_distance` ahead and asks only
	## where the motorcycle is, so it lasts past the pig to the end of the
	## segment.
	noticed_pig : Motorcycle, Segment -> [Noticed(Geom.Placed(Billboard)), NothingNoticed]
	noticed_pig = |motorcycle, segment|
		match eye_catching_pig(segment) {
			CatchesEye(pig) if is_past_notice(motorcycle, pig) => Noticed(pig)
			CatchesEye(_) | NoPigCatchesEye => NothingNoticed
		}

	## Where the rider wants to look: at the pig in sight, this far from the
	## way the motorcycle points, or at the road.
	GazeTarget : [OnPig(Angle.Turn), OnRoad]

	## How far from the way the motorcycle points the rider will look. A pig
	## this far round, or further, is out of sight.
	look_release_angle : Angle.Turn
	look_release_angle = Angle.Turn.degrees(35.0)

	## Where the rider wants to look: at a distracting pig that is near enough
	## to notice and less than the release angle from the way the motorcycle
	## points, or else at the road.
	desired_gaze : Motorcycle, Segment -> Gaze.GazeTarget
	desired_gaze = |motorcycle, segment|
		match Gaze.noticed_pig(motorcycle, segment) {
			Noticed(pig) => {
				turn = turn_to(motorcycle, pig)
				if turn.abs() < look_release_angle {
					OnPig(turn)
				} else {
					OnRoad
				}
			}
			NothingNoticed => OnRoad
		}
}

## Whether the motorcycle has reached the place where `pig` is noticed.
is_past_notice : Motorcycle, Geom.Placed(Billboard) -> Bool
is_past_notice = |motorcycle, pig|
	motorcycle.route_place.along >= pig.road_point.along.minus(Gaze.notice_distance)

## How far `pig` stands from the way the motorcycle points.
turn_to : Motorcycle, Geom.Placed(Billboard) -> Angle.Turn
turn_to = |motorcycle, pig| Angle.Turn.radians(
	F64.atan2({
		x: pig.road_point.along.distance_from(motorcycle.route_place.along).to_metres(),
		y: pig.road_point.across.distance_from(motorcycle.route_place.across).to_metres(),
	}),
).minus(motorcycle.yaw)
