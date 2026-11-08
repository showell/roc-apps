## TruckPlacement stands the truck's shape at its spot in the rider's view:
## where a point on the truck lands, and where a whole face does.
import Geom
import Picture
import Polygon
import RoadAhead
import RiderView
import TruckShape

TruckPlacement :: [].{

	## What a truck is drawn from beyond its spot and the camera's lens: the road
	## its points are measured on, and the camera's vantage.
	TruckOnRoad : { road : RoadAhead.RoadView, vantage : Geom.Vantage }

	## How a truck is drawn: its spot, the camera's lens, and the road and
	## vantage its points are seen from.
	TruckSetting : Picture.Setting(TruckPlacement.TruckOnRoad)

	## Where a point on the truck stands in the rider's view: carried from the
	## truck's frame onto the road at the truck's spot, which can lie across a
	## bend, then raised as far as the truck is off the ground and lowered by
	## the ground's drop beneath the truck's spot.
	raised_point : TruckPlacement.TruckSetting, TruckShape.TruckPoint -> RiderView.RaisedPoint
	raised_point = |truck, { ahead, rightward, height }| {
		spot = truck.spot
		center = spot.road_point()
		road_point = { along: center.along.plus(ahead), across: center.across.plus(rightward) }
		on_level = RoadAhead.rider_point_at(
			truck.context.road,
			{ vantage: truck.context.vantage, place: spot.place(), road_point },
		)
		{
			right: on_level.right,
			forward: on_level.forward,
			height: spot.lift().plus(height).minus(spot.drop()),
		}
	}

	## A face of the truck in the rider's view, every corner placed.
	placed_face : TruckPlacement.TruckSetting, TruckShape.TruckFace -> Polygon.FlatPolygon
	placed_face = |truck, { color, corners }| {
		color,
		corners: corners.map(|corner| TruckPlacement.raised_point(truck, corner)),
	}
}
