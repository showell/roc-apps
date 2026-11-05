## A truck's shape: its size, the box it fills on the road, and where a
## point on it lands in the rider's view. TruckBody and TruckLights build
## their polygons from these, and `fill` paints one.
import Camera
import Frame
import Geom
import Paint
import lib.Trig
import lib.Shapes

TruckShape :: [].{

	## The box the truck fills: four distances along the road, from the back
	## of the trailer to the front of the cab, and its two sides across the
	## road. The cab's flat roof ends at `roof_front`, where its windshield
	## slopes down to the nose.
	TruckBox : {
		rear : F64,
		trailer_front : F64,
		roof_front : F64,
		nose : F64,
		left : F64,
		right : F64,
	}

	## A truck ready to draw: what it is seen from, its segment's position in
	## the chain, and the box it fills.
	TruckInView : {
		view : Frame.Viewpoint,
		position : Frame.ChainPosition,
		box : TruckShape.TruckBox,
	}

	## A point on the truck: how far along the road, how far across it, and
	## how high above it.
	RoadPoint : {
		along : F64,
		across : F64,
		height : F64,
	}

	trailer_length : F64
	trailer_length = 8.4

	truck_width : F64
	truck_width = 2.4

	truck_height : F64
	truck_height = 3.6

	cab_length : F64
	cab_length = 3.5

	tire_radius : F64
	tire_radius = 0.5

	## The trailer's floor clears the top of its tyres by 12 cm.
	trailer_bottom : F64
	trailer_bottom = ((2.0 * tire_radius) + 0.12)

	## The cab's floor is level with its axle.
	cab_bottom : F64
	cab_bottom = tire_radius

	## The box of a truck whose trailer is centred at `along` and `across`;
	## the cab is ahead of the trailer.
	truck_box : { along : F64, across : F64 } -> TruckShape.TruckBox
	truck_box = |center| {
		trailer_front = (center.along + (trailer_length / 2.0))
		{
			rear: (center.along - (trailer_length / 2.0)),
			trailer_front,
			roof_front: (trailer_front + (cab_length * cab_roof_fraction)),
			nose: (trailer_front + cab_length),
			left: (center.across - (truck_width / 2.0)),
			right: (center.across + (truck_width / 2.0)),
		}
	}

	## Where a point on the truck lands in the rider's view. The ground
	## curves away from the rider, so the point is lowered by how far the
	## ground has dropped beneath it.
	point : TruckShape.TruckInView, TruckShape.RoadPoint -> Geom.SpacePoint
	point = |
		truck,
		{
			along,
			across,
			height,
		},
	| {
		on_ground = Frame.rider_point_ahead(
			truck.view.road,
			{
				position: truck.position,
				along,
				across,
			},
		)
		{
			right: on_ground.right,
			forward: on_ground.forward,
			height: (height - Geom.ground_drop(on_ground)),
		}
	}

	## The angles of the corners of a circle drawn as a polygon with `sides`
	## corners, going round from angle 0.
	circle_angles : I64 -> List(F64)
	circle_angles = |sides| List.from_iter(
		I64.until(
			0,
			sides,
		),
	).map(|corner| ((corner.to_f64() / sides.to_f64()) * Trig.two_pi))

	## A flat-coloured polygon on the truck, cut at the near plane and
	## projected.
	fill : TruckShape.TruckInView,
	{
		color : I64,
		corners : List(Geom.SpacePoint),
	} -> List(Shapes.Shape)
	fill = |truck, { color, corners }| Paint.push_poly(
		color,
		Camera.project_all(
			Geom.clip_near(corners),
			truck.view.cam_focal,
		),
	)
}

## How far forward of the trailer the cab's flat roof reaches, as a fraction
## of the cab's length.
cab_roof_fraction : F64
cab_roof_fraction = 0.3

centered_box : TruckShape.TruckBox
centered_box = TruckShape.truck_box({ along: 0.0, across: 0.0 })

offset_box : TruckShape.TruckBox
offset_box = TruckShape.truck_box({ along: 40.0, across: 2.0 })

expect centered_box.rear == -4.2
expect centered_box.trailer_front == 4.2
expect centered_box.nose == 7.7
expect centered_box.roof_front == 5.25
expect centered_box.left == -1.2
expect centered_box.right == 1.2

expect offset_box.rear == 35.8
expect offset_box.trailer_front == 44.2
expect offset_box.nose == 47.7
expect offset_box.roof_front == 45.25
expect offset_box.left == 0.8
expect offset_box.right == 3.2

expect TruckShape.tire_radius == 0.5
expect TruckShape.trailer_bottom == 1.12
expect TruckShape.cab_bottom == 0.5
expect TruckShape.truck_height == 3.6
expect TruckShape.truck_width == 2.4
expect TruckShape.trailer_length == 8.4
