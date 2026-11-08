## A truck's shape: its size, the box it fills on the road, and where a
## point on it lands in the rider's view. TruckBody and TruckLights build
## their polygons from these, and `truck_polygon` makes a shape of one.
import Across
import Along
import Camera
import Distance
import RoadAhead
import Fraction
import Geom
import EarthCurve
import Picture
import lib.Shapes

TruckShape :: [].{

	## The box the truck fills: four places along the road, from the back
	## of the trailer to the front of the cab, and its two sides across the
	## road. The cab's flat roof ends at `roof_front`, where its windshield
	## slopes down to the nose.
	TruckBox : {
		rear : Along,
		trailer_front : Along,
		roof_front : Along,
		nose : Along,
		left : Across,
		right : Across,
	}

	## What a truck is drawn from beyond its spot and the camera's lens: the road
	## its points are measured on, the camera's vantage, and the box it fills
	## there.
	TruckOnRoad : {
		road : RoadAhead.RoadView,
		vantage : Geom.Vantage,
		box : TruckShape.TruckBox,
	}

	## A point on the truck: how far along the road, how far across it, and
	## how high above the truck's own bottom.
	TruckPoint : {
		along : Along,
		across : Across,
		height : Distance,
	}

	trailer_length : Distance
	trailer_length = Distance.metres(8.4)

	truck_width : Distance
	truck_width = Distance.metres(2.4)

	truck_height : Distance
	truck_height = Distance.metres(3.6)

	cab_length : Distance
	cab_length = Distance.metres(3.5)

	tire_radius : Distance
	tire_radius = Distance.metres(0.5)

	## The trailer's floor clears the top of its tires by 12 cm.
	trailer_bottom : Distance
	trailer_bottom = tire_radius.times(2.0).plus(Distance.metres(0.12))

	## The cab's floor is level with its axle.
	cab_bottom : Distance
	cab_bottom = tire_radius

	## The box of a truck whose trailer is centred at `along` and `across`;
	## the cab is ahead of the trailer.
	truck_box : { along : Along, across : Across } -> TruckShape.TruckBox
	truck_box = |center| {
		trailer_front = center.along.plus(trailer_length.divided_by(2.0))
		{
			rear: center.along.minus(trailer_length.divided_by(2.0)),
			trailer_front,
			roof_front: trailer_front.plus(cab_length.times(cab_roof_fraction.to_f64())),
			nose: trailer_front.plus(cab_length),
			left: center.across.minus(truck_width.divided_by(2.0)),
			right: center.across.plus(truck_width.divided_by(2.0)),
		}
	}

	## Where a point on the truck lands in the rider's view, raised as far as
	## the truck is off the ground. The ground curves away from the rider, so
	## the point is lowered by how far the ground has dropped beneath it.
	point : Picture.Setting(TruckShape.TruckOnRoad), TruckShape.TruckPoint -> Geom.RaisedPoint
	point = |truck, { along, across, height }| {
		place = truck.spot.place()
		on_ground = RoadAhead.rider_point_at(
			truck.context.road,
			{
				vantage: truck.context.vantage,
				place,
				road_point: { along, across },
			},
		)
		{
			right: on_ground.right,
			forward: on_ground.forward,
			height: truck.spot.lift().plus(height).minus(EarthCurve.ground_drop(on_ground)),
		}
	}

	## The four corners of a strip across the truck from `left` to `right`,
	## between its `near` edge and its `far` edge: near left, near right, far
	## right, far left.
	strip_corners : { left : Across, right : Across },
	{
		near : { along : Along, height : Distance },
		far : { along : Along, height : Distance },
	} -> List(TruckShape.TruckPoint)
	strip_corners = |{ left, right }, { near, far }| [
		{
			along: near.along,
			across: left,
			height: near.height,
		},
		{
			along: near.along,
			across: right,
			height: near.height,
		},
		{
			along: far.along,
			across: right,
			height: far.height,
		},
		{
			along: far.along,
			across: left,
			height: far.height,
		},
	]

	## The angles of the corners of a circle drawn as a polygon with `sides`
	## corners, going round from angle 0.
	circle_angles : I64 -> List(F64)
	circle_angles = |sides| List.from_iter(
		I64.until(0, sides),
	).map(|corner| corner.to_f64() / sides.to_f64() * F64.tau)

	## A flat-coloured polygon on the truck, cut at the near plane and
	## projected, unless it's wholly behind the camera.
	truck_polygon : Picture.Setting(TruckShape.TruckOnRoad),
	Camera.FlatPolygon -> Try(
		Shapes.Shape,
		[BehindCamera],
	)
	truck_polygon = |truck, polygon| Camera.clipped_polygon(polygon, truck.cam_focal)
}

## How far forward of the trailer the cab's flat roof reaches, as a fraction
## of the cab's length, a proportion chosen by eye.
cab_roof_fraction : Fraction
cab_roof_fraction = Fraction.of(0.3)

expect
	TruckShape.strip_corners(
		{ left: Across.metres(-1.0), right: Across.metres(1.0) },
		{
			near: { along: Along.metres(2.0), height: Distance.metres(3.0) },
			far: { along: Along.metres(5.0), height: Distance.metres(7.0) },
		},
	).map(|corner| (corner.along.to_metres(), corner.across.to_metres(), corner.height.to_metres()))
		== [
			(2.0, -1.0, 3.0),
			(2.0, 1.0, 3.0),
			(5.0, 1.0, 7.0),
			(5.0, -1.0, 7.0),
		]
