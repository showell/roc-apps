## A truck's shape: its size, the box it fills on the road, and where a
## point on it lands in the rider's view. TruckBody and TruckLights build
## their polygons from these, and `fill` paints one.
import Across
import Along
import Camera
import Distance
import Chain
import Fraction
import Geom
import Paint
import lib.Trig
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

	## A truck ready to draw: what it is seen from, its segment's position in
	## the chain, and the box it fills.
	TruckInView : {
		view : Chain.Viewpoint,
		position : Chain.Position,
		box : TruckShape.TruckBox,
	}

	## A point on the truck: how far along the road, how far across it, and
	## how high above it.
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

	## Where a point on the truck lands in the rider's view. The ground
	## curves away from the rider, so the point is lowered by how far the
	## ground has dropped beneath it.
	point : TruckShape.TruckInView, TruckShape.TruckPoint -> Geom.RaisedPoint
	point = |truck, { along, across, height }| {
		on_ground = Chain.rider_point_ahead(
			truck.view.road,
			{ position: truck.position, along, across },
		)
		{
			right: on_ground.right,
			forward: on_ground.forward,
			height: (height.to_metres() - Geom.ground_drop(on_ground)),
		}
	}

	## The angles of the corners of a circle drawn as a polygon with `sides`
	## corners, going round from angle 0.
	circle_angles : I64 -> List(F64)
	circle_angles = |sides| List.from_iter(
		I64.until(0, sides),
	).map(|corner| (corner.to_f64() / sides.to_f64()) * Trig.two_pi)

	## A flat-coloured polygon on the truck, cut at the near plane and
	## projected.
	polygon : TruckShape.TruckInView,
	{
		color : I64,
		corners : List(Geom.RaisedPoint),
	} -> List(Shapes.Shape)
	polygon = |truck, { color, corners }| Paint.polygon(
		color,
		Camera.project_all(Geom.clip_near(corners), truck.view.cam_focal),
	)
}

## How far forward of the trailer the cab's flat roof reaches, as a fraction
## of the cab's length.
cab_roof_fraction : Fraction
cab_roof_fraction = Fraction.of(0.3)

centered_box : TruckShape.TruckBox
centered_box = TruckShape.truck_box({ along: Along.metres(0.0), across: Across.metres(0.0) })

offset_box : TruckShape.TruckBox
offset_box = TruckShape.truck_box({ along: Along.metres(40.0), across: Across.metres(2.0) })

expect centered_box.rear.to_metres() == -4.2
expect centered_box.trailer_front.to_metres() == 4.2
expect centered_box.nose.to_metres() == 7.7
expect centered_box.roof_front.to_metres() == 5.25
expect centered_box.left.to_metres() == -1.2
expect centered_box.right.to_metres() == 1.2

expect offset_box.rear.to_metres() == 35.8
expect offset_box.trailer_front.to_metres() == 44.2
expect offset_box.nose.to_metres() == 47.7
expect offset_box.roof_front.to_metres() == 45.25
expect offset_box.left.to_metres() == 0.8
expect offset_box.right.to_metres() == 3.2

expect TruckShape.tire_radius.to_metres() == 0.5
expect TruckShape.trailer_bottom.to_metres() == 1.12
expect TruckShape.cab_bottom.to_metres() == 0.5
expect TruckShape.truck_height.to_metres() == 3.6
expect TruckShape.truck_width.to_metres() == 2.4
expect TruckShape.trailer_length.to_metres() == 8.4
