## A Spot is where an object stands in one frame: its place on the road, its
## height off the ground, and where that puts its foot in the rider's view.
## `Pipeline.sighting_of` works one out for each object in view, and every
## picture is drawn from it.
##
## It has a module of its own because a kind's picture names it, and Segment
## and Trees, which hold the kinds, sit under RoadAhead and Pipeline.
import Distance
import EarthCurve
import Geom
import RiderView
import SegmentFromRider

Spot :: {
	from_rider : SegmentFromRider,
	road_point : Geom.RoadPoint,
	lift : Distance,
	foot : RiderView.RiderPointAhead,
}.{

	## The spot of an object standing at `road_point` on the segment that lies
	## at `from_rider`, `lift` off the ground, its foot at `foot` in the rider's
	## view. A sighting builds each spot in play from the road, so the foot
	## follows from where the object stands. A kind's test builds one here, to
	## draw from a foot it chooses.
	at : {
		from_rider : SegmentFromRider,
		road_point : Geom.RoadPoint,
		lift : Distance,
		foot : RiderView.RiderPointAhead,
	} -> Spot
	at = |parts| Spot.(parts)

	## Where the object's segment lies, seen from the rider.
	from_rider : Spot -> SegmentFromRider
	from_rider = |Spot.(spot)| spot.from_rider

	## Where the object stands on its segment.
	road_point : Spot -> Geom.RoadPoint
	road_point = |Spot.(spot)| spot.road_point

	## How high off the ground the object is.
	lift : Spot -> Distance
	lift = |Spot.(spot)| spot.lift

	## Where the object's foot is in the rider's view, on the rider's level and
	## past the near plane.
	foot : Spot -> RiderView.RiderPointAhead
	foot = |Spot.(spot)| spot.foot

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
}
