## A Spot is where an object stands in one frame: its height off the ground,
## where its foot is in the rider's view, and which way the road runs there.
## `Pipeline.sighting_of` works one out for each object in view from its place
## on the road, and every picture is drawn from it.
##
## Every object stands on the road through its spot. A card, which faces the
## camera, stands at its foot (`base`). A solid thing stands each of its points
## with `standing_point`, turned the way it faces against the road.
##
## It has a module of its own because a kind's picture names it, and Segment
## and Trees, which hold the kinds, sit under RoadAhead and Pipeline.
import Angle
import Distance
import EarthCurve
import RiderView

Spot :: {
	lift : Distance,
	foot : RiderView.RiderPointAhead,
	road_heading : Angle.Turn,
}.{

	## The spot of an object `lift` off the ground, its foot at `foot` in the
	## rider's view, where the road runs `road_heading`. A sighting builds each
	## spot in play from the road, so the foot and the heading follow from
	## where the object stands. A kind's test builds one here, to draw from a
	## foot it chooses.
	at : {
		lift : Distance,
		foot : RiderView.RiderPointAhead,
		road_heading : Angle.Turn,
	} -> Spot
	at = |parts| Spot.(parts)

	## How high off the ground the object is.
	lift : Spot -> Distance
	lift = |Spot.(spot)| spot.lift

	## Where the object's foot is in the rider's view, on the rider's level and
	## past the near plane.
	foot : Spot -> RiderView.RiderPointAhead
	foot = |Spot.(spot)| spot.foot

	## Which way the road runs at the spot, seen from the camera: zero straight
	## away from it, positive to the right.
	road_heading : Spot -> Angle.Turn
	road_heading = |Spot.(spot)| spot.road_heading

	## How far the ground has curved away below the rider's level beneath the
	## object's foot. Every part of an object is lowered by this one drop: it
	## changes by a few centimetres at most across anything we draw, well under
	## a pixel, so working it out once per object is enough.
	drop : Spot -> Distance
	drop = |spot| EarthCurve.ground_drop(spot.foot().to_rider())

	## The middle of the object's foot, raised as high off the ground as the
	## object is, on the ground as it curves away: where an upright object
	## stands.
	base : Spot -> RiderView.RaisedPointAhead
	base = |spot| spot.foot().at_height(spot.lift().minus(spot.drop()))

	## Where a point of a solid thing standing at the spot lands in the rider's
	## view. `offset` is the point in the thing's own frame: how far ahead of
	## its foot, how far to the right, and how high above the ground under it.
	## `facing` is how the thing is turned against the road: zero along the
	## road, positive to the right. The offset is turned by the road's heading
	## and the facing, carried out from the foot, raised by the lift, and
	## lowered by the ground's drop.
	standing_point : Spot,
	{
		facing : Angle.Turn,
		offset : {
			ahead : Distance,
			rightward : Distance,
			height : Distance,
		},
	} -> RiderView.RaisedPoint
	standing_point = |spot, { facing, offset }| {
		turn = spot.road_heading().plus(facing).to_radians()
		ahead_metres = offset.ahead.to_metres()
		rightward_metres = offset.rightward.to_metres()
		{
			forward: spot.foot().forward().plus(
				Distance.metres(ahead_metres * turn.cos() - rightward_metres * turn.sin()),
			),
			right: spot.foot().right().plus(
				Distance.metres(ahead_metres * turn.sin() + rightward_metres * turn.cos()),
			),
			height: spot.lift().plus(offset.height).minus(spot.drop()),
		}
	}
}
