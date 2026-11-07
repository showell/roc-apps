## TowerSighting finds the radio towers in front of the rider in a frame. A tower
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. The tower past the
## end of the segment behind the rider is seen too. Each tower's beacon blinks
## on the ride's clock, and the sighting says how bright it is in the frame.
import Across
import Along
import Angle
import Beacon
import Clock
import Distance
import Chain
import Geom
import Pipeline
import Tower
import World

TowerSighting :: [].{

	## What the towers are seen from: the road in view, and the ride's clock.
	Viewpoint : { road : Chain.RoadView, clock : Clock }

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

	## At most this many towers are drawn in a frame.
	max_visible_towers : I64
	max_visible_towers = 16

	## The towers in view: those along the chain, then the one past the end of
	## the segment behind the rider.
	towers_in_view : TowerSighting.Viewpoint -> List(Pipeline.Sighted(Tower))
	towers_in_view = |view|
		match Chain.segment_behind(view.road) {
			Previous(segment_behind) =>
				towers_along_chain(view).concat(
					[tower_behind(view, segment_behind)].keep_oks(|tower| tower),
				)
			AtRouteStart => towers_along_chain(view)
		}

	## The towers in view along the chain, the nearest segment's first.
	towers_along_chain : TowerSighting.Viewpoint -> List(Pipeline.Sighted(Tower))
	towers_along_chain = |view| {
		positions = Chain.Position.positions_in(view.road.chain_indices)
		positions.join_map(|position| segment_towers(view, position))
	}

	## The towers in view on the segment at `position` in the chain: the one past
	## its end, then the one halfway along.
	segment_towers : TowerSighting.Viewpoint, Chain.Position -> List(Pipeline.Sighted(Tower))
	segment_towers = |view, position| {
		index = position.index_in(view.road.chain_indices)
		segment = index.segment_in(view.road.route_segments)
		end_tower = tower_if_ahead(
			view,
			{
				place: InChain(position),
				along: Along.at(segment.length.plus(tower_beyond)),
				across: Across.right_of_middle(tower_right),
				yaw: tower_yaw,
				beacon_key: index.to_u32(),
			},
		)
		[end_tower, mid_tower(view, position)].keep_oks(|tower| tower)
	}

	## The tower halfway along the segment at `position` in the chain, if it has
	## one and it is in view.
	mid_tower : TowerSighting.Viewpoint,
	Chain.Position -> Try(
		Pipeline.Sighted(Tower),
		[BehindCamera, NoMidTower],
	)
	mid_tower = |view, position| {
		index = position.index_in(view.road.chain_indices)
		segment = index.segment_in(view.road.route_segments)
		match segment.mid_tower {
			MidTower =>
				tower_if_ahead(
					view,
					{
						place: InChain(position),
						along: Along.at(segment.length.divided_by(2.0)),
						across: Across.left_of_middle(mid_tower_left),
						yaw: Angle.straight_ahead,
						beacon_key: index.to_u32() + mid_tower_key_offset,
					},
				)
			NoMidTower => Err(NoMidTower)
		}
	}

	## The tower past the end of the segment at `index`, the one behind the
	## rider, if it is in view.
	tower_behind :
		TowerSighting.Viewpoint, World.SegmentIndex -> Try(Pipeline.Sighted(Tower), [BehindCamera])
	tower_behind = |view, index| {
		behind = index.segment_in(view.road.route_segments)
		tower_if_ahead(
			view,
			{
				place: Chain.place_behind(behind),
				along: Along.at(behind.length.plus(tower_beyond)),
				across: Across.right_of_middle(tower_right),
				yaw: tower_yaw,
				beacon_key: index.to_u32(),
			},
		)
	}
}

## A tower halfway along a segment takes its beacon's blink from a key this
## far past its segment's. That many staggers come to half a period past a
## whole number of periods, so it blinks exactly opposite the tower at the
## segment's end.
mid_tower_key_offset : U32
mid_tower_key_offset = 60

## A tower standing at `along` and `across` in the segment that `place` maps,
## if it is in front of the camera.
tower_if_ahead : TowerSighting.Viewpoint,
{
	place : Chain.SegmentPlace,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	beacon_key : U32,
} -> Try(Pipeline.Sighted(Tower), [BehindCamera])
tower_if_ahead = |view, { place, along, across, yaw, beacon_key }| {
	placed_tower : Geom.Placed(Tower)
	placed_tower = {
		along,
		across,
		kind: {
			yaw,
			beacon_brightness: Beacon.beacon_brightness(
				view.clock.minus(Clock.start).plus(Beacon.beacon_offset_for(beacon_key)),
			),
		},
	}
	Pipeline.sighting_of(placed_tower, { road: view.road, place })
}

expect TowerSighting.tower_beyond.to_metres() == 160.0
expect TowerSighting.tower_right.to_metres() == 20.0
expect TowerSighting.mid_tower_left.to_metres() == 100.0
expect TowerSighting.max_visible_towers == 16

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
	half_width: Distance.metres(2.0),
}

## Three segments seen from the origin, the rider on the first of them, the
## route's segment `rider_number`.
short_view : U32 -> TowerSighting.Viewpoint
short_view = |rider_number| {
	road: {
		route_segments: [0, 1, 2, 3, 4].map(World.route_segment),
		chain_indices: [
			rider_number,
			rider_number + 1,
			rider_number + 2,
		].map(World.SegmentIndex.number),
		vantage: origin,
	},
	clock: Clock.start,
}

from_origin : TowerSighting.Viewpoint
from_origin = short_view(0)

expect TowerSighting.towers_along_chain(from_origin).len() == 3
expect TowerSighting.segment_towers(from_origin, Chain.Position.first).len() == 1
expect TowerSighting.mid_tower(from_origin, Chain.Position.first).is_err()
expect TowerSighting.towers_in_view(from_origin).len() == 3
expect route_segments.all(|seg| !has_mid_tower(seg))

## Whether a segment has a tower halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |seg|
	match seg.mid_tower {
		MidTower => True
		NoMidTower => False
	}

## The first tower in view on the segment at `position` in the chain.
first_tower_on : U32 -> Pipeline.Sighted(Tower)
first_tower_on = |number| TowerSighting.segment_towers(
	from_origin,
	Chain.Position.number(number),
).first() ?? crash "TowerSighting: the first two segments' towers are in view"

expect first_tower_on(0).along.to_metres() == 660.0
expect first_tower_on(0).across.to_metres() == 20.0
expect first_tower_on(1).along.to_metres() == 480.0
expect first_tower_on(1).across.to_metres() == 20.0
expect
	[
		(first_tower_on(0).right.to_metres(), 20.0),
		(first_tower_on(0).forward.to_metres(), 660.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

## The 1200 m segment alone, seen from the origin.
long_view : TowerSighting.Viewpoint
long_view = {
	road: {
		route_segments: [World.route_segment(6)],
		chain_indices: [0].map(World.SegmentIndex.number),
		vantage: origin,
	},
	clock: Clock.start,
}

expect TowerSighting.towers_along_chain(long_view).len() == 2
expect TowerSighting.mid_tower(long_view, Chain.Position.first).is_ok()

long_towers : List(Pipeline.Sighted(Tower))
long_towers = TowerSighting.towers_along_chain(long_view)

## The long segment's tower at `i`: its end tower, then its mid tower.
long_tower : U64 -> Pipeline.Sighted(Tower)
long_tower = |i|
	long_towers.get(i) ?? crash "TowerSighting: the long segment has two towers in view"

expect
	[
		(long_tower(0).along.to_metres(), 1360.0),
		(long_tower(0).across.to_metres(), 20.0),
		(long_tower(1).along.to_metres(), 600.0),
		(long_tower(1).across.to_metres(), -100.0),
		(long_tower(0).kind.yaw.to_radians(), 0.5235987755982988),
		(long_tower(1).kind.yaw.to_radians(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

## How bright the towers on the long segment are at `clock`: its end tower,
## then its mid tower.
long_brightnesses_at : Clock -> List(F64)
long_brightnesses_at = |clock|
	TowerSighting.towers_along_chain({
		..long_view,
		clock,
	}).map(|tower| tower.kind.beacon_brightness.to_f64())

expect {
	got = long_brightnesses_at(Clock.start).concat(long_brightnesses_at(Clock.at_step(60)))
	wanted_list = [0.0, 1.0, 1.0, 0.0]
	closeness = got.map2(wanted_list, |one, wanted| (one - wanted).abs() <= 0.0000001)
	got.len() == wanted_list.len() and closeness.all(|is_close| is_close)
}

## How bright the first three segments' towers are at `clock`.
brightnesses_at : Clock -> List(F64)
brightnesses_at = |clock| {
	towers = TowerSighting.towers_along_chain({ ..from_origin, clock })
	towers.map(|tower| tower.kind.beacon_brightness.to_f64())
}

expect
	brightnesses_at(Clock.start).concat(brightnesses_at(Clock.at_step(30)))
		== [0, 37, 74, 30, 67, 104].map(brightness_at)

brightness_at : U32 -> F64
brightness_at = |phase| Beacon.beacon_brightness(Clock.at_step(phase).minus(Clock.start)).to_f64()

expect TowerSighting.towers_in_view(short_view(0)).len() == 3
expect TowerSighting.towers_in_view(short_view(1)).len() == 4
expect TowerSighting.towers_in_view(short_view(2)).len() == 4
expect TowerSighting.tower_behind(short_view(1), World.SegmentIndex.first).is_ok()
expect TowerSighting.towers_along_chain({
	..from_origin,
	road: { ..from_origin.road, vantage: { ..origin, along: Along.metres(5000.0) } },
}).len() == 0
expect TowerSighting.towers_along_chain({
	..from_origin,
	road: { ..from_origin.road, chain_indices: [] },
}).len() == 0
expect TowerSighting.towers_along_chain(from_origin).len() == 3
