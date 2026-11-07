## A Spot is where an object stands in one frame: its place on the road, its
## height off the ground, and where that puts its foot in the rider's view.
## `Pipeline.sighting_of` works one out for each object in view, and every
## picture is drawn from it.
##
## It has a module of its own because a kind's picture names it, and Segment
## and Trees, which hold the kinds, sit under RoadAhead and Pipeline.
import Across
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
	## place. A kind's test builds one here, to draw from a foot it chooses.
	at : {
		place : SegmentPlace,
		road_point : Geom.RoadPoint,
		lift : Distance,
		foot : Geom.LevelPoint,
	} -> Spot
	at = |parts| Spot.(parts)

	## The spot of an object on a straight road that runs ahead from under the
	## camera: standing at `road_point` on the first segment ahead, `lift` off
	## the ground, and `forward` ahead of the camera. A widget that draws a
	## straight road builds its spots here.
	straight_ahead : {
		road_point : Geom.RoadPoint,
		lift : Distance,
		forward : Distance,
	} -> Try(Spot, [BehindCamera])
	straight_ahead = |{ road_point, lift, forward }| {
		right = road_point.across.distance_from(Across.middle)
		Geom.ahead_on_level({ right, forward }).map_ok(
			|foot| Spot.(
				{
					place: Ahead(SegmentPlace.Position.first),
					road_point,
					lift,
					foot,
				},
			),
		)
	}

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

	## The middle of the object's foot, raised as high off the ground as the
	## object is: where an upright object stands.
	base : Spot -> Geom.AheadPoint
	base = |spot| spot.foot().at_height(spot.lift())
}
