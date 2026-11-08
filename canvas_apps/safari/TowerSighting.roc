## TowerSighting finds the radio towers in front of the rider in a frame. A tower
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. Each tower's beacon
## blinks on the ride's clock, and the sighting lights it for the frame.
## Unlike the trees and the critters, a tower has no size test: it is
## sighted however small it stands, until the earth's curve sinks it wholly
## below the horizon, and then it is refused.
import Across
import Along
import Angle
import Beacon
import Clock
import Distance
import RoadAhead
import SegmentFromRider
import Geom
import Pipeline
import Tower

TowerSighting :: [].{

	## The towers in view, in the order of `RoadAhead.segments_in_view`.
	towers_in_view : RoadAhead.RoadView,
	{
		camera : Pipeline.SightingCamera,
		clock : Clock,
	} -> List(Pipeline.Sighted(Tower))
	towers_in_view = |road, { camera, clock }|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_towers(road, { camera, in_view, clock }),
		)
}

## How far past the end of its segment a tower stands.
end_tower_beyond_end : Distance
end_tower_beyond_end = Distance.metres(160.0)

## How far right of the road's middle a tower past a segment's end stands.
end_tower_right_of_middle : Distance
end_tower_right_of_middle = Distance.metres(20.0)

## How far a tower past a segment's end is turned from square with the road.
end_tower_yaw : Angle.Turn
end_tower_yaw = Angle.Turn.degrees(30.0)

## A segment longer than this has a tower halfway along.
mid_tower_min_length : Distance
mid_tower_min_length = Distance.metres(1000.0)

## How far left of the road's middle a tower halfway along a segment stands.
mid_tower_left_of_middle : Distance
mid_tower_left_of_middle = Distance.metres(100.0)

## Where the tower halfway along a segment `segment_length` long stands, off
## to the left, if the segment is long enough to have one.
mid_tower_point : Distance -> Try(Geom.RoadPoint, [NoMidTower])
mid_tower_point = |segment_length|
	if segment_length > mid_tower_min_length {
		Ok({
			along: Along.at(segment_length.divided_by(2.0)),
			across: Across.left_of_middle(mid_tower_left_of_middle),
		})
	} else {
		Err(NoMidTower)
	}

# Only a segment longer than a kilometre has a tower halfway along.
expect mid_tower_point(Distance.metres(1000.0)) == Err(NoMidTower)
expect
	mid_tower_point(Distance.metres(1000.5))
		== Ok({ along: Along.metres(500.25), across: Across.metres(-100.0) })

## The towers in view of a segment in view: the one past its end, then the
## one halfway along.
segment_towers : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> List(Pipeline.Sighted(Tower))
segment_towers = |road, { camera, in_view, clock }|
	[
		end_tower(road, { camera, in_view, clock }),
		mid_tower(road, { camera, in_view, clock }),
	].keep_oks(|tower| tower)

## The tower past the end of a segment in view, if it is in front of the
## camera and above the horizon.
end_tower : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera, BelowHorizon])
end_tower = |road, { camera, in_view, clock }| {
	beacon = Beacon.at({ segment: in_view.index, place: AtEnd }, clock)
	tower_if_ahead(
		road,
		{
			camera,
			place: in_view.place,
			road_point: {
				along: Along.at(in_view.segment.length.plus(end_tower_beyond_end)),
				across: Across.right_of_middle(end_tower_right_of_middle),
			},
			tower: Tower.standing({ yaw: end_tower_yaw, beacon }),
		},
	)
}

## The tower halfway along a segment in view, if it has one and it is in
## front of the camera and above the horizon.
mid_tower : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera, BelowHorizon, NoMidTower])
mid_tower = |road, { camera, in_view, clock }| {
	road_point = mid_tower_point(in_view.segment.length)?
	beacon = Beacon.at({ segment: in_view.index, place: Midway }, clock)
	tower_if_ahead(
		road,
		{
			camera,
			place: in_view.place,
			road_point,
			tower: Tower.standing({ yaw: Angle.straight_ahead, beacon }),
		},
	)
}

## `tower` standing on the ground at `road_point` in the segment that `place`
## maps, if it is in front of `camera` and some of it shows above the horizon.
tower_if_ahead : RoadAhead.RoadView,
{
	camera : Pipeline.SightingCamera,
	place : SegmentFromRider,
	road_point : Geom.RoadPoint,
	tower : Tower,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera, BelowHorizon])
tower_if_ahead = |road, { camera, place, road_point, tower }| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = { road_point, lift: Distance.zero, kind: tower }
	Pipeline.sighting_above_horizon_of(placed_tower, { road, camera, place })
}
