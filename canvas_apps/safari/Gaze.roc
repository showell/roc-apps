## Where the rider looks. A pig by the road catches the rider's eye: the gaze
## swivels toward it. The pig passes out of sight to the side while it is still
## ahead, and the gaze turns back to the road.
##
## Two words keep the eyes and the throttle apart. A look is what the eyes do,
## and it ends once the pig is too far round. Gawking is what the speed does,
## and it lasts to the end of the segment; it is Gawking's.
import Angle
import Attention
import Billboard
import Easing
import Fraction
import Gawking
import Geom
import Motorcycle
import Segment

Gaze :: [].{

	## Where the rider wants to look: at the pig in sight, this far from the
	## way the motorcycle points, or at the road.
	GazeTarget : [OnPig(Angle.Turn), OnRoad]

	## How far from the way the motorcycle points the rider will look. A pig
	## this far round, or further, is out of sight.
	look_release_angle : Angle.Turn
	look_release_angle = Angle.Turn.degrees(35.0)

	## How strongly a look of this depth holds the rider's eye. The easing keeps
	## a shallow look from widening the view much.
	gaze_attention : Fraction -> Attention
	gaze_attention = |look_depth| Attention.from_fraction(Easing.smoothstep(look_depth))

	## Where the rider wants to look: at a distracting pig that is near enough
	## to notice and less than the release angle from the way the motorcycle
	## points, or else at the road.
	desired_gaze : Motorcycle, Segment -> Gaze.GazeTarget
	desired_gaze = |motorcycle, segment|
		match Gawking.gawked_pig(motorcycle, segment) {
			GawkingAt(pig) => {
				turn = turn_to(motorcycle, pig)
				if turn.abs() < look_release_angle {
					OnPig(turn)
				} else {
					OnRoad
				}
			}
			NotGawking => OnRoad
		}
}

## How far `pig` stands from the way the motorcycle points.
turn_to : Motorcycle, Geom.Placed(Billboard) -> Angle.Turn
turn_to = |motorcycle, pig| Angle.Turn.radians(
	F64.atan2({
		x: pig.road_point.along.distance_from(motorcycle.route_place.along).to_metres(),
		y: pig.road_point.across.distance_from(motorcycle.route_place.across).to_metres(),
	}),
).minus(motorcycle.yaw)

expect Gaze.gaze_attention(Fraction.of(0.25)).to_f64() == 0.15625
