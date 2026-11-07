## TowerSighting finds the radio towers in front of the rider in a frame. A tower
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. Each tower's beacon
## blinks on the ride's clock, and the sighting says how bright it is in the
## frame. Unlike the trees and the critters, a tower has no size test: it is
## drawn however small it stands, until the earth's curve sinks it.
import Across
import Along
import Angle
import Beacon
import Clock
import Distance
import RoadAhead
import Segment
import SegmentPlace
import Geom
import Pipeline
import Tower

TowerSighting :: [].{

	## The towers in view, in the order of `RoadAhead.segments_in_view`.
	towers_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, .. },
		clock : Clock,
	} -> List(Pipeline.Sighted(Tower))
	towers_in_view = |road, { camera, clock }|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_towers(road, { vantage: camera.vantage, in_view, clock }),
		)
}

## How far past the end of its segment a tower stands.
tower_beyond : Distance
tower_beyond = Distance.metres(160.0)

## How far right of the road's middle a tower past a segment's end stands.
tower_right : Distance
tower_right = Distance.metres(20.0)

## How far left of the road's middle a tower halfway along a segment stands.
mid_tower_left : Distance
mid_tower_left = Distance.metres(100.0)

## How far a tower past a segment's end is turned: 30 degrees.
tower_yaw : Angle.Turn
tower_yaw = Angle.Turn.degrees(30.0)

## The towers in view of a segment in view: the one past its end, then the
## one halfway along.
segment_towers : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> List(Pipeline.Sighted(Tower))
segment_towers = |road, { vantage, in_view, clock }|
	[
		end_tower(road, { vantage, in_view, clock }),
		mid_tower(road, { vantage, in_view, clock }),
	].keep_oks(|tower| tower)

## The tower past the end of a segment in view, if it is in front of the
## camera.
end_tower : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera])
end_tower = |road, { vantage, in_view, clock }| {
	beacon_brightness = Beacon.(in_view.index.to_u32()).brightness_at(clock)
	tower_if_ahead(
		road,
		{
			vantage,
			place: in_view.place,
			road_point: {
				along: Along.at(in_view.segment.length.plus(tower_beyond)),
				across: Across.right_of_middle(tower_right),
			},
			tower: { yaw: tower_yaw, beacon_brightness },
		},
	)
}

## The tower halfway along a segment in view, if it has one and it is in
## front of the camera.
mid_tower : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera, NoMidTower])
mid_tower = |road, { vantage, in_view, clock }|
	if Segment.has_mid_tower(in_view.segment) {
		beacon_brightness = Beacon.(in_view.index.to_u32()).opposite().brightness_at(clock)
		tower_if_ahead(
			road,
			{
				vantage,
				place: in_view.place,
				road_point: {
					along: Along.at(in_view.segment.length.divided_by(2.0)),
					across: Across.left_of_middle(mid_tower_left),
				},
				tower: { yaw: Angle.straight_ahead, beacon_brightness },
			},
		)
	} else {
		Err(NoMidTower)
	}

## `tower` standing on the ground at `road_point` in the segment that `place`
## maps, if it is in front of the camera at `vantage`.
tower_if_ahead : RoadAhead.RoadView,
{
	vantage : Geom.Vantage,
	place : SegmentPlace,
	road_point : Geom.RoadPoint,
	tower : Tower,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera])
tower_if_ahead = |road, { vantage, place, road_point, tower }| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = { road_point, lift: Distance.zero, kind: tower }
	Pipeline.sighting_of(placed_tower, { road, vantage, place })
}
