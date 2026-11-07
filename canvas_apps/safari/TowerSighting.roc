## TowerSighting finds the radio towers in front of the rider in a frame. A tower
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. Each tower's beacon
## blinks on the ride's clock, and the sighting says how bright it is in the
## frame.
import Across
import Along
import Angle
import Beacon
import Clock
import Distance
import RoadAhead
import SegmentPlace
import Steps
import Geom
import Pipeline
import Tower
import World

TowerSighting :: [].{

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

	## The towers in view, in the order of `RoadAhead.segments_in_view`.
	towers_in_view : RoadAhead.RoadView, Clock -> List(Pipeline.Sighted(Tower))
	towers_in_view = |road, clock|
		RoadAhead.segments_in_view(road).join_map(
			|in_view| segment_towers(road, { in_view, clock }),
		)

	## The towers in view of a segment in view: the one past its end, then the
	## one halfway along.
	segment_towers : RoadAhead.RoadView,
	{
		in_view : RoadAhead.SegmentInView,
		clock : Clock,
	} -> List(Pipeline.Sighted(Tower))
	segment_towers = |road, { in_view, clock }|
		[
			end_tower_of(road, { in_view, clock }),
			mid_tower(road, { in_view, clock }),
		].keep_oks(|tower| tower)

	## The tower past the end of a segment in view, if it is in front of the
	## camera.
	end_tower_of : RoadAhead.RoadView,
	{
		in_view : RoadAhead.SegmentInView,
		clock : Clock,
	} -> Try(Pipeline.Sighted(Tower), [BehindCamera])
	end_tower_of = |road, { in_view, clock }|
		tower_if_ahead(
			road,
			{
				clock,
				place: in_view.place,
				along: Along.at(in_view.segment.length.plus(tower_beyond)),
				across: Across.right_of_middle(tower_right),
				yaw: tower_yaw,
				beacon_key: in_view.index.to_u32(),
			},
		)

	## The tower halfway along a segment in view, if it has one and it is in
	## front of the camera.
	mid_tower : RoadAhead.RoadView,
	{ in_view : RoadAhead.SegmentInView, clock : Clock } -> Try(
		Pipeline.Sighted(Tower),
		[BehindCamera, NoMidTower],
	)
	mid_tower = |road, { in_view, clock }|
		match in_view.segment.mid_tower {
			MidTower =>
				tower_if_ahead(
					road,
					{
						clock,
						place: in_view.place,
						along: Along.at(in_view.segment.length.divided_by(2.0)),
						across: Across.left_of_middle(mid_tower_left),
						yaw: Angle.straight_ahead,
						beacon_key: in_view.index.to_u32() + mid_tower_key_offset,
					},
				)
			NoMidTower => Err(NoMidTower)
		}
}

## A tower halfway along a segment takes its beacon's blink from a key this
## far past its segment's. That many staggers come to half a period past a
## whole number of periods, so it blinks exactly opposite the tower at the
## segment's end.
mid_tower_key_offset : U32
mid_tower_key_offset = 60

## A tower standing at `along` and `across` in the segment that `place` maps,
## if it is in front of the camera, its beacon as bright as `clock` says.
tower_if_ahead : RoadAhead.RoadView,
{
	clock : Clock,
	place : SegmentPlace,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	beacon_key : U32,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera])
tower_if_ahead = |
	road,
	{
		clock,
		place,
		along,
		across,
		yaw,
		beacon_key,
	},
| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = {
		along,
		across,
		lift: Distance.zero,
		kind: {
			yaw,
			beacon_brightness: Beacon.beacon_brightness(
				clock.steps_since(Clock.start).plus(Beacon.beacon_offset_for(beacon_key)),
			),
		},
	}
	Pipeline.sighting_of(placed_tower, { road, place })
}

expect TowerSighting.tower_beyond.to_metres() == 160.0
expect TowerSighting.tower_right.to_metres() == 20.0
expect TowerSighting.mid_tower_left.to_metres() == 100.0

route_segments : List(World.Segment)
route_segments = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## Three segments seen from the origin, the rider on the first of them, the
## route's segment `rider_number`.
short_road : U32 -> RoadAhead.RoadView
short_road = |rider_number| {
	route_segments: [0, 1, 2, 3, 4].map(World.route_segment),
	segments_ahead: [
		rider_number,
		rider_number + 1,
		rider_number + 2,
	].map(World.SegmentIndex.number),
	vantage: origin,
}

origin_road : RoadAhead.RoadView
origin_road = short_road(0)

## The start of the ride on `road`, on the rider's own segment.
ride_start : RoadAhead.RoadView -> { in_view : RoadAhead.SegmentInView, clock : Clock }
ride_start = |road| {
	in_view: RoadAhead.segment_in_view_at(road, SegmentPlace.Position.first),
	clock: Clock.start,
}

expect TowerSighting.segment_towers(origin_road, ride_start(origin_road)).len() == 1
expect TowerSighting.mid_tower(origin_road, ride_start(origin_road)).is_err()
expect TowerSighting.towers_in_view(origin_road, Clock.start).len() == 3
expect route_segments.all(|seg| !has_mid_tower(seg))

## Whether a segment has a tower halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |seg|
	match seg.mid_tower {
		MidTower => True
		NoMidTower => False
	}

## The first tower in view on the segment at `position` on the road ahead.
first_tower_on : U32 -> Pipeline.Sighted(Tower)
first_tower_on = |number| TowerSighting.segment_towers(
	origin_road,
	{
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

## The 1200 m segment alone, seen from the origin.
long_road : RoadAhead.RoadView
long_road = {
	route_segments: [World.route_segment(6)],
	segments_ahead: [0].map(World.SegmentIndex.number),
	vantage: origin,
}

expect TowerSighting.towers_in_view(long_road, Clock.start).len() == 2
expect TowerSighting.mid_tower(long_road, ride_start(long_road)).is_ok()

long_towers : List(Pipeline.Sighted(Tower))
long_towers = TowerSighting.towers_in_view(long_road, Clock.start)

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
	TowerSighting.towers_in_view(long_road, clock)
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
	towers = TowerSighting.towers_in_view(origin_road, clock)
	towers.map(|tower| tower.kind.beacon_brightness.to_f64())
}

expect
	brightnesses_at(Clock.start).concat(brightnesses_at(Clock.at_step(30)))
		== [0, 37, 74, 30, 67, 104].map(brightness_at)

brightness_at : U32 -> F64
brightness_at = |phase| Beacon.beacon_brightness(Steps.of(phase)).to_f64()

expect TowerSighting.towers_in_view(short_road(0), Clock.start).len() == 3
expect TowerSighting.towers_in_view(short_road(1), Clock.start).len() == 4
expect TowerSighting.towers_in_view(short_road(2), Clock.start).len() == 4
expect
	TowerSighting.towers_in_view(short_road(1), Clock.start).map(|tower| tower.spot.place())
		== [
			Ahead(SegmentPlace.Position.number(0)),
			Ahead(SegmentPlace.Position.number(1)),
			Ahead(SegmentPlace.Position.number(2)),
			RoadAhead.place_behind(World.route_segment(0)),
		]
expect TowerSighting.towers_in_view(
	{ ..origin_road, vantage: { ..origin, along: Along.metres(5000.0) } },
	Clock.start,
).len() == 0
