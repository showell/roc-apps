## A truck's shape: its size, the box it fills on the road, and where a
## point on it lands in the rider's view. TruckBody and TruckLights build
## their polygons from these.
import Distance
import RoadAhead
import Fraction
import Geom
import EarthCurve
import Picture

TruckShape :: [].{

	## The box the truck fills, in the truck's own frame. Four offsets run
	## ahead of the trailer's centre, from the back of the trailer to the front
	## of the cab, so `rear` is negative. The two sides are offsets to the
	## right of the trailer's centre line, so `left` is negative. The cab's flat
	## roof ends at `roof_front`, where its windshield slopes down to the nose.
	TruckBox : {
		rear : Distance,
		trailer_front : Distance,
		roof_front : Distance,
		nose : Distance,
		left : Distance,
		right : Distance,
	}

	## What a truck is drawn from beyond its spot and the camera's lens: the road
	## its points are measured on, and the camera's vantage.
	TruckOnRoad : { road : RoadAhead.RoadView, vantage : Geom.Vantage }

	## A point on the truck, in the truck's own frame: how far ahead of the
	## trailer's centre and how far to the right of it, each negative the other
	## way, and how high above the road under the truck.
	TruckPoint : {
		ahead : Distance,
		rightward : Distance,
		height : Distance,
	}

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

	## Where the windshield meets the nose: half the truck's height.
	hood_height : Distance
	hood_height = truck_height.divided_by(2.0)

	## How tall the trailer is, from its floor to its roof.
	trailer_height : Distance
	trailer_height = truck_height.minus(trailer_bottom)

	## The box the truck fills, in its own frame, centred where its trailer
	## is; the cab is ahead of the trailer.
	truck_box : TruckShape.TruckBox
	truck_box = {
		trailer_front = trailer_length.divided_by(2.0)
		{
			rear: trailer_length.divided_by(2.0).opposite(),
			trailer_front,
			roof_front: trailer_front.plus(cab_length.times(cab_roof_fraction.to_f64())),
			nose: trailer_front.plus(cab_length),
			left: truck_width.divided_by(2.0).opposite(),
			right: truck_width.divided_by(2.0),
		}
	}

	## Where a point on the truck lands in the rider's view, raised as far as
	## the truck is off the ground. The point is carried from the truck's frame
	## onto the road at the truck's spot. The ground curves away from the rider,
	## so the point is lowered by how far the ground has dropped beneath it.
	raised_point_on_truck : TruckSetting, TruckShape.TruckPoint -> Geom.RaisedPoint
	raised_point_on_truck = |truck, { ahead, rightward, height }| {
		place = truck.spot.place()
		center = truck.spot.road_point()
		on_ground = RoadAhead.rider_point_at(
			truck.context.road,
			{
				vantage: truck.context.vantage,
				place,
				road_point: {
					along: center.along.plus(ahead),
					across: center.across.plus(rightward),
				},
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
	strip_corners : { left : Distance, right : Distance },
	{
		near : { ahead : Distance, height : Distance },
		far : { ahead : Distance, height : Distance },
	} -> List(TruckShape.TruckPoint)
	strip_corners = |{ left, right }, { near, far }| [
		{
			ahead: near.ahead,
			rightward: left,
			height: near.height,
		},
		{
			ahead: near.ahead,
			rightward: right,
			height: near.height,
		},
		{
			ahead: far.ahead,
			rightward: right,
			height: far.height,
		},
		{
			ahead: far.ahead,
			rightward: left,
			height: far.height,
		},
	]

	## The angles of the corners of a circle drawn as a polygon with `sides`
	## corners, going round from angle 0.
	circle_angles : I64 -> List(F64)
	circle_angles = |sides| List.from_iter(
		I64.until(0, sides),
	).map(|corner| corner.to_f64() / sides.to_f64() * F64.tau)
}

## How a truck is drawn: its spot, the camera's lens, and the road and vantage
## its points are seen from.
TruckSetting : Picture.Setting(TruckShape.TruckOnRoad)

trailer_length : Distance
trailer_length = Distance.metres(8.4)

## How far forward of the trailer the cab's flat roof reaches, as a fraction
## of the cab's length, a proportion chosen by eye.
cab_roof_fraction : Fraction
cab_roof_fraction = Fraction.of(0.3)

expect
	TruckShape.strip_corners(
		{ left: Distance.metres(-1.0), right: Distance.metres(1.0) },
		{
			near: { ahead: Distance.metres(2.0), height: Distance.metres(3.0) },
			far: { ahead: Distance.metres(5.0), height: Distance.metres(7.0) },
		},
	).map(
		|corner| (
			corner.ahead.to_metres(),
			corner.rightward.to_metres(),
			corner.height.to_metres(),
		),
	)
		== [
			(2.0, -1.0, 3.0),
			(2.0, 1.0, 3.0),
			(5.0, 1.0, 7.0),
			(5.0, -1.0, 7.0),
		]
