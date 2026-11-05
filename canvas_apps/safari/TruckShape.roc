## A truck's shape: its size, the box it fills on the road, and where a
## point on it lands in the rider's view. TruckBody and TruckLights build
## their polygons from these, and `fill` paints one.
import Across
import Along
import Camera
import Distance
import Frame
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
		view : Frame.Viewpoint,
		position : Frame.ChainPosition,
		box : TruckShape.TruckBox,
	}

	## A point on the truck: how far along the road, how far across it, and
	## how high above it.
	RoadPoint : {
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

	## The trailer's floor clears the top of its tyres by 12 cm.
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
			roof_front: trailer_front.plus(cab_length.times(cab_roof_fraction)),
			nose: trailer_front.plus(cab_length),
			left: center.across.minus(truck_width.divided_by(2.0)),
			right: center.across.plus(truck_width.divided_by(2.0)),
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
			height: (height.to_metres() - Geom.ground_drop(on_ground)),
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
