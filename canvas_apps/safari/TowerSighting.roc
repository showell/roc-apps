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
import Route
import Segment
import SegmentPlace
import Geom
import Pipeline
import Pixels
import Tower
import World

TowerSighting :: [].{

	## The towers in view, in the order of `RoadAhead.segments_in_view`.
	towers_in_view : RoadAhead.RoadView,
	{
		camera : { vantage : Geom.Vantage, cam_focal : Pixels, .. },
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

route_segments : List(Segment)
route_segments = [
	World.route.segment_at(Route.SegmentIndex.number(0)),
	World.route.segment_at(Route.SegmentIndex.number(1)),
	World.route.segment_at(Route.SegmentIndex.number(2)),
]

origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The road ahead of a rider on the route's segment `rider_number`, on a route
## that ends three segments on, so the road ahead holds three.
short_road : U32 -> RoadAhead.RoadView
short_road = |rider_number| {
	kept_count = rider_number.to_u64() + 3
	kept_segments = World.route.route_segments().take_first(kept_count)
	route = Route.from_segments(
		kept_segments.map_with_index(
			|segment, at|
				if at + 1 == kept_count {
					{ ..segment, ending: RouteEnds }
				} else {
					segment
				},
		),
	)
	RoadAhead.RoadView.ahead_of(route, Route.SegmentIndex.number(rider_number))
}

## The camera at the origin.
origin_camera : { vantage : Geom.Vantage, cam_focal : Pixels }
origin_camera = { vantage: origin, cam_focal: Pixels.of(500.0) }

origin_road : RoadAhead.RoadView
origin_road = short_road(0)

## The start of the ride on `road`, on the rider's own segment, seen from the
## origin.
ride_start : RoadAhead.RoadView -> {
	vantage : Geom.Vantage,
	in_view : RoadAhead.SegmentInView,
	clock : Clock,
}
ride_start = |road| {
	vantage: origin,
	in_view: RoadAhead.segment_in_view_at(road, SegmentPlace.Position.first),
	clock: Clock.start,
}

## The towers in view from the origin on `road` at `clock`.
towers_on : RoadAhead.RoadView, Clock -> List(Pipeline.Sighted(Tower))
towers_on = |road, clock| TowerSighting.towers_in_view(road, { camera: origin_camera, clock })

expect segment_towers(origin_road, ride_start(origin_road)).len() == 1
expect mid_tower(origin_road, ride_start(origin_road)).is_err()
expect towers_on(origin_road, Clock.start).len() == 3
expect route_segments.all(|seg| !seg.has_mid_tower())

## The first tower in view on the segment at `position` on the road ahead.
first_tower_on : U32 -> Pipeline.Sighted(Tower)
first_tower_on = |number| segment_towers(
	origin_road,
	{
		vantage: origin,
		in_view: RoadAhead.segment_in_view_at(origin_road, SegmentPlace.Position.number(number)),
		clock: Clock.start,
	},
).first() ?? crash "TowerSighting: the first two segments' towers are in view"

expect first_tower_on(0).spot.road_point().along.to_metres() == 660.0
expect first_tower_on(0).spot.road_point().across.to_metres() == 20.0
expect first_tower_on(1).spot.road_point().along.to_metres() == 480.0
expect first_tower_on(1).spot.road_point().across.to_metres() == 20.0
expect
	[
		(first_tower_on(0).spot.foot().right().to_metres(), 20.0),
		(first_tower_on(0).spot.foot().forward().to_metres(), 660.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

## The 1200 m segment alone, a route of its own, seen from the origin.
long_road : RoadAhead.RoadView
long_road = RoadAhead.RoadView.ahead_of(
	Route.from_segments([
		{ ..World.route.segment_at(Route.SegmentIndex.number(6)), ending: RouteEnds },
	]),
	Route.SegmentIndex.first,
)

expect towers_on(long_road, Clock.start).len() == 2
expect mid_tower(long_road, ride_start(long_road)).is_ok()

long_towers : List(Pipeline.Sighted(Tower))
long_towers = towers_on(long_road, Clock.start)

## The long segment's tower at `i`: its end tower, then its mid tower.
long_tower : U64 -> Pipeline.Sighted(Tower)
long_tower = |i|
	long_towers.get(i) ?? crash "TowerSighting: the long segment has two towers in view"

expect
	[
		(long_tower(0).spot.road_point().along.to_metres(), 1360.0),
		(long_tower(0).spot.road_point().across.to_metres(), 20.0),
		(long_tower(1).spot.road_point().along.to_metres(), 600.0),
		(long_tower(1).spot.road_point().across.to_metres(), -100.0),
		(long_tower(0).kind.yaw.to_radians(), 0.5235987755982988),
		(long_tower(1).kind.yaw.to_radians(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

## How bright the towers on the long segment are at `clock`: its end tower,
## then its mid tower.
long_brightnesses_at : Clock -> List(F64)
long_brightnesses_at = |clock|
	towers_on(long_road, clock)
		.map(|tower| tower.kind.beacon_brightness.to_f64())

expect {
	got = long_brightnesses_at(Clock.start).concat(long_brightnesses_at(Clock.at_step(60)))
	wanted_list = [0.0, 1.0, 1.0, 0.0]
	closeness = got.map2(wanted_list, |one, wanted| (one - wanted).abs() <= 0.0000001)
	got.len() == wanted_list.len() and closeness.all(|is_close| is_close)
}

## How bright the first three segments' towers are at `clock`.
brightnesses_at : Clock -> List(F64)
brightnesses_at = |clock| {
	towers = towers_on(origin_road, clock)
	towers.map(|tower| tower.kind.beacon_brightness.to_f64())
}

expect
	brightnesses_at(Clock.start).concat(brightnesses_at(Clock.at_step(30)))
		== [0, 37, 74, 30, 67, 104].map(brightness_at)

brightness_at : U32 -> F64
brightness_at = |phase| Beacon.(0).brightness_at(Clock.at_step(phase)).to_f64()

expect towers_on(short_road(0), Clock.start).len() == 3
expect towers_on(short_road(1), Clock.start).len() == 4
expect towers_on(short_road(2), Clock.start).len() == 4
expect
	towers_on(short_road(1), Clock.start).map(|tower| tower.spot.place())
		== [
			Ahead(SegmentPlace.Position.number(0)),
			Ahead(SegmentPlace.Position.number(1)),
			Ahead(SegmentPlace.Position.number(2)),
			JustBehind,
		]
expect TowerSighting.towers_in_view(
	origin_road,
	{
		camera: { ..origin_camera, vantage: { ..origin, along: Along.metres(5000.0) } },
		clock: Clock.start,
	},
).len() == 0
