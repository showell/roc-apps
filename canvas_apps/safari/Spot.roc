## A Spot is where an object stands in one frame: its place on the road, its
## height off the ground, and where that puts its foot in the rider's view.
## `Pipeline.sighting_of` works one out for each object in view, and every
## picture is drawn from it.
##
## It has a module of its own because a kind's picture names it, and World,
## which holds the kinds, sits under RoadAhead and Pipeline.
import Distance
import Geom
import SegmentPlace

Spot :: {
	place : SegmentPlace,
	road_point : Geom.RoadPoint,
	lift : Distance,
	foot : Geom.LevelPoint,
}.{

	## The spot of an object standing at `road_point` on the segment at `place`,
	## `lift` off the ground, its foot at `foot` in the rider's view. A sighting
	## builds each spot in play from the road, so the foot follows from the
	## place. A kind's test or a widget builds one here, to draw from a foot it
	## chooses.
	at : {
		place : SegmentPlace,
		road_point : Geom.RoadPoint,
		lift : Distance,
		foot : Geom.LevelPoint,
	} -> Spot
	at = |parts| Spot.(parts)

	## The place of the object's segment, relative to the rider.
	place : Spot -> SegmentPlace
	place = |Spot.(spot)| spot.place

	## Where the object stands on its segment.
	road_point : Spot -> Geom.RoadPoint
	road_point = |Spot.(spot)| spot.road_point

	## How high off the ground the object is.
	lift : Spot -> Distance
	lift = |Spot.(spot)| spot.lift

	## Where the object's foot is in the rider's view, on the rider's level and
	## past the near plane.
	foot : Spot -> Geom.LevelPoint
	foot = |Spot.(spot)| spot.foot
}
