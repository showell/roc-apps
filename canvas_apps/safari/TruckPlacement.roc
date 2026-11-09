## TruckPlacement stands the truck's shape at its spot in the rider's view, as
## one rigid body: where a point on the truck lands, and where a whole face does.
import Angle
import Distance
import Pixels
import Polygon
import RiderView
import Spot
import TruckShape

TruckPlacement :: [].{

	## How a truck is drawn: its spot, which way it heads against the camera,
	## and the camera's lens. A heading of zero runs straight away from the
	## camera, and a positive one turns to the right.
	TruckSetting : {
		spot : Spot,
		heading : Angle.Turn,
		focal_length : Pixels,
	}

	## Where the truck stands and which way it heads against the camera, as
	## in its `TruckSetting`: all that placing a point on it reads.
	TruckStance : { spot : Spot, heading : Angle.Turn }

	## Where a point on the truck stands in the rider's view: turned by the
	## truck's heading about its foot, carried out from the foot, raised as far
	## as the truck is off the ground and lowered by the ground's drop beneath
	## the truck's spot.
	raised_point : TruckPlacement.TruckStance, TruckShape.TruckPoint -> RiderView.RaisedPoint
	raised_point = |{ spot, heading }, { ahead, rightward, height }| {
		foot = spot.foot()
		cos_heading = heading.to_radians().cos()
		sin_heading = heading.to_radians().sin()
		ahead_metres = ahead.to_metres()
		rightward_metres = rightward.to_metres()
		{
			forward: foot.forward().plus(
				Distance.metres(ahead_metres * cos_heading - rightward_metres * sin_heading),
			),
			right: foot.right().plus(
				Distance.metres(ahead_metres * sin_heading + rightward_metres * cos_heading),
			),
			height: spot.lift().plus(height).minus(spot.drop()),
		}
	}

	## A face of the truck in the rider's view, every corner placed.
	placed_face : TruckPlacement.TruckStance, TruckShape.TruckFace -> Polygon.FlatPolygon
	placed_face = |stance, { color, corners }| {
		color,
		corners: corners.map(|corner| TruckPlacement.raised_point(stance, corner)),
	}
}
