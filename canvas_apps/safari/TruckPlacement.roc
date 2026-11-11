## TruckPlacement stands the truck's shape at its spot. The truck is a solid
## thing that faces along the road, so each of its points stands through
## `Spot.standing_point`, turned by nothing beyond the road's own heading.
import Angle
import Camera
import lib.Fraction
import lib.Pixels
import RiderView
import Spot
import TruckShape

TruckPlacement :: [].{

	## How a truck is drawn: where it stands, the camera's lens, and how dark
	## the sky is, which dims its body but never its lights.
	TruckSetting : {
		spot : Spot,
		focal_length : Pixels,
		darkness : Fraction,
	}

	## Where a point on the truck stands in the rider's view, for a truck at
	## `spot` facing along the road.
	point_at_height : Spot, TruckShape.TruckPoint -> RiderView.PointAtHeight
	point_at_height = |spot, point|
		spot.standing_point({ facing: Angle.straight_ahead, offset: point })

	## A face of the truck in the rider's view, every corner placed.
	placed_face : Spot, TruckShape.TruckFace -> Camera.FlatPolygon
	placed_face = |spot, { color, corners }| {
		color,
		corners: corners.map(|corner| TruckPlacement.point_at_height(spot, corner)),
	}
}
