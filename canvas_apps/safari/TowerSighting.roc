## TowerSighting finds the radio towers in front of the rider in a frame. A tower
## stands past the end of every segment, off to the right, and a long
## segment has one more halfway along, off to the left. The tower past the
## end of the segment behind the rider is seen too. Each tower's beacon blinks
## on the ride's clock, and the sighting says how bright it is in the frame.
import Across
import Along
import Angle
import Clock
import DepthSort
import Distance
import Fraction
import Chain
import Geom
import Steps
import lib.Trig
import World

## A tower to draw: how its segment maps to the rider's view, where it
## stands in that segment and how it is turned, how far ahead it is, and
## how bright its beacon is.
TowerSighting := {
	place : Chain.SegmentPlace,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	forward : F64,
	beacon_brightness : Fraction,
}.{

	## What the towers are seen from: the road in view, and the ride's clock.
	Viewpoint : { road : Chain.RoadView, clock : Clock }

	## How far past the end of its segment a tower stands.
	tower_beyond : Distance
	tower_beyond = Distance.metres(160.0)

	## How far right of the lane's middle a tower past a segment's end stands.
	tower_right : Distance
	tower_right = Distance.metres(20.0)

	## How far left of the lane's middle a tower halfway along a segment stands.
	mid_tower_left : Distance
	mid_tower_left = Distance.metres(100.0)

	## How far a tower past a segment's end is turned: 30 degrees.
	tower_yaw : Angle.Turn
	tower_yaw = Angle.Turn.degrees(30.0)

	## At most this many towers are drawn in a frame.
	max_vis_towers : I64
	max_vis_towers = 16

	## A beacon blinks once in this many steps of the ride.
	beacon_period : Steps
	beacon_period = Steps.of(120)

	## Each tower's blink starts this many steps past the last one's, a number
	## that shares no factor with the period, so neighbours blink apart.
	beacon_stagger : Steps
	beacon_stagger = Steps.of(37)

	## How far into its blink the tower with key `n` is when the ride's clock
	## is 0.
	beacon_offset_for : U32 -> Steps
	beacon_offset_for = |n| beacon_stagger.times(n).wrapped_to(beacon_period)

	## How bright a beacon is `phase` steps into its blink.
	beacon_brightness : Steps -> Fraction
	beacon_brightness = |phase| {
		wrapped = phase.wrapped_to(beacon_period).to_f64()
		angle = (((2.0 * Trig.pi) * wrapped) / beacon_period.to_f64())
		Fraction.of(((1.0 - Trig.r_cos(angle)) / 2.0))
	}

	## The towers in view: those along the chain, then the one past the end of
	## the segment behind the rider.
	in_view : TowerSighting.Viewpoint -> List(TowerSighting)
	in_view = |view|
		match Chain.segment_behind(view.road) {
			Previous(segment_behind) => along_chain(view).concat(tower_behind(view, segment_behind))
			AtRouteStart => along_chain(view)
		}

	## The towers in view along the chain, the nearest segment's first.
	along_chain : TowerSighting.Viewpoint -> List(TowerSighting)
	along_chain = |view| {
		positions = Chain.Position.all_in(view.road.chain)
		positions.join_map(|position| segment_towers(view, position))
	}

	## The towers in view on the segment at `position` in the chain: the one past
	## its end, then the one halfway along.
	segment_towers : TowerSighting.Viewpoint, Chain.Position -> List(TowerSighting)
	segment_towers = |view, position| {
		index = position.index_in(view.road.chain)
		segment = index.segment_in(view.road.route)
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
		end_tower.concat(mid_tower(view, position))
	}

	## The tower halfway along the segment at `position` in the chain, if it has
	## one and it is in view.
	mid_tower : TowerSighting.Viewpoint, Chain.Position -> List(TowerSighting)
	mid_tower = |view, position| {
		index = position.index_in(view.road.chain)
		segment = index.segment_in(view.road.route)
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
			NoMidTower => []
		}
	}

	## The tower past the end of the segment at `index`, the one behind the
	## rider, if it is in view.
	tower_behind : TowerSighting.Viewpoint, World.SegmentIndex -> List(TowerSighting)
	tower_behind = |view, index| {
		behind = index.segment_in(view.road.route)
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

	## The towers as the depth sort sees them: each one's distance ahead, and
	## its position in `towers`.
	depth_keys : List(TowerSighting) -> List(DepthSort.DepthKey)
	depth_keys = |towers| towers.map_with_index(
		|tower, i| { forward: tower.forward, subject: Tower(i.to_u32_wrap()) },
	)
}

## A tower halfway along a segment takes its beacon's blink from a key this
## far past its segment's. That many staggers come to half a period past a
## whole number of periods, so it blinks exactly opposite the tower at the
## segment's end.
mid_tower_key_offset : U32
mid_tower_key_offset = 60

## A tower standing at `along` and `across` in the segment that `place` maps,
## if it is in front of the camera: one item, or none.
tower_if_ahead : TowerSighting.Viewpoint,
{
	place : Chain.SegmentPlace,
	along : Along,
	across : Across,
	yaw : Angle.Turn,
	beacon_key : U32,
} -> List(TowerSighting)
tower_if_ahead = |view, { place, along, across, yaw, beacon_key }| {
	center = Chain.rider_point_at(view.road, { place: place, along, across })
	if center.forward <= Geom.near_plane {
		[]
	} else {
		[
			{
				place,
				along,
				across,
				yaw,
				forward: center.forward,
				beacon_brightness: TowerSighting.beacon_brightness(
					view.clock.minus(Clock.start).plus(TowerSighting.beacon_offset_for(beacon_key)),
				),
			},
		]
	}
}

expect TowerSighting.tower_beyond.to_metres() == 160.0
expect TowerSighting.tower_right.to_metres() == 20.0
expect TowerSighting.mid_tower_left.to_metres() == 100.0
expect TowerSighting.beacon_period.to_f64() == 120.0
expect TowerSighting.beacon_stagger.to_f64() == 37.0
expect TowerSighting.max_vis_towers == 16

route : List(World.Segment)
route = [
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
		route: [0, 1, 2, 3, 4].map(World.route_segment),
		chain: [rider_number, rider_number + 1, rider_number + 2].map(World.SegmentIndex.number),
		vantage: origin,
	},
	clock: Clock.start,
}

from_origin : TowerSighting.Viewpoint
from_origin = short_view(0)

expect TowerSighting.along_chain(from_origin).len() == 3
expect TowerSighting.segment_towers(from_origin, Chain.Position.first).len() == 1
expect TowerSighting.mid_tower(from_origin, Chain.Position.first).len() == 0
expect TowerSighting.in_view(from_origin).len() == 3
expect route.all(|seg| !(has_mid_tower(seg)))

## Whether a segment has a tower halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |seg|
	match seg.mid_tower {
		MidTower => True
		NoMidTower => False
	}

## The first tower in view on the segment at `position` in the chain.
first_tower_on : U32 -> TowerSighting
first_tower_on = |number| TowerSighting.segment_towers(
	from_origin,
	Chain.Position.number(number),
).first() ?? crash "TowerSighting: the first two segments' towers are in view"

expect first_tower_on(0).along.to_metres() == 660.0
expect first_tower_on(0).across.to_metres() == 20.0
expect first_tower_on(1).along.to_metres() == 480.0
expect first_tower_on(1).across.to_metres() == 20.0

## The 1200 m segment alone, seen from the origin.
long_view : TowerSighting.Viewpoint
long_view = {
	road: {
		route: [World.route_segment(6)],
		chain: [0].map(World.SegmentIndex.number),
		vantage: origin,
	},
	clock: Clock.start,
}

expect TowerSighting.along_chain(long_view).len() == 2
expect TowerSighting.mid_tower(long_view, Chain.Position.first).len() == 1

long_towers : List(TowerSighting)
long_towers = TowerSighting.along_chain(long_view)

## The long segment's tower at `i`: its end tower, then its mid tower.
long_tower : U64 -> TowerSighting
long_tower = |i|
	long_towers.get(i) ?? crash "TowerSighting: the long segment has two towers in view"

expect
	[
		(long_tower(0).along.to_metres(), 1360.0),
		(long_tower(0).across.to_metres(), 20.0),
		(long_tower(1).along.to_metres(), 600.0),
		(long_tower(1).across.to_metres(), -100.0),
		(long_tower(0).yaw.to_radians(), 0.5235987755982988),
		(long_tower(1).yaw.to_radians(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect TowerSighting.beacon_offset_for(0).to_f64() == 0.0
expect TowerSighting.beacon_offset_for(1).to_f64() == 37.0
expect TowerSighting.beacon_offset_for(2).to_f64() == 74.0
expect TowerSighting.beacon_offset_for(3).to_f64() == 111.0
expect TowerSighting.beacon_offset_for(4).to_f64() == 28.0
expect TowerSighting.beacon_offset_for(5).to_f64() == 65.0
expect TowerSighting.beacon_offset_for(10).to_f64() == 10.0
expect TowerSighting.beacon_offset_for(60).to_f64() == 60.0
expect TowerSighting.beacon_offset_for(120).to_f64() == 0.0
expect
	[
		(TowerSighting.beacon_brightness(Steps.of(0)).to_f64(), 0.0),
		(TowerSighting.beacon_brightness(Steps.of(60)).to_f64(), 1.0),
		(TowerSighting.beacon_brightness(Steps.of(30)).to_f64(), 0.5),
		(TowerSighting.beacon_brightness(Steps.of(90)).to_f64(), 0.5),
		(TowerSighting.beacon_brightness(Steps.of(120)).to_f64(), 0.0),
		(TowerSighting.beacon_brightness(Steps.of(180)).to_f64(), 1.0),
		(TowerSighting.beacon_brightness(Steps.of(300)).to_f64(), 1.0),
		(TowerSighting.beacon_brightness(Steps.of(240)).to_f64(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0000001)

## How bright the towers on the long segment are at `clock`: its end tower,
## then its mid tower.
long_brightness_at : Clock -> List(F64)
long_brightness_at = |clock|
	TowerSighting.along_chain({ ..long_view, clock }).map(|tower| tower.beacon_brightness.to_f64())

expect {
	got = List.concat(long_brightness_at(Clock.start), long_brightness_at(Clock.at_step(60)))
	wanted_list = [0.0, 1.0, 1.0, 0.0]
	closeness = got.map2(wanted_list, |one, wanted| (one - wanted).abs() <= 0.0000001)
	got.len() == wanted_list.len() and closeness.all(|is_close| is_close)
}

## How bright the first three segments' towers are at `clock`.
spread_at : Clock -> List(F64)
spread_at = |clock| {
	towers = TowerSighting.along_chain({ ..from_origin, clock })
	towers.map(|tower| tower.beacon_brightness.to_f64())
}

expect
	List.concat(spread_at(Clock.start), spread_at(Clock.at_step(30)))
		== [0, 37, 74, 30, 67, 104].map(brightness_at)

brightness_at : U32 -> F64
brightness_at = |phase| TowerSighting.beacon_brightness(Steps.of(phase)).to_f64()

expect TowerSighting.in_view(short_view(0)).len() == 3
expect TowerSighting.in_view(short_view(1)).len() == 4
expect TowerSighting.in_view(short_view(2)).len() == 4
expect TowerSighting.tower_behind(short_view(1), World.SegmentIndex.first).len() == 1
expect TowerSighting.along_chain({
	..from_origin,
	road: { ..from_origin.road, vantage: { ..origin, along: Along.metres(5000.0) } },
}).len() == 0
expect TowerSighting.along_chain({
	..from_origin,
	road: { ..from_origin.road, chain: [] },
}).len() == 0
keys : List(DepthSort.DepthKey)
keys = TowerSighting.depth_keys(TowerSighting.along_chain(from_origin))

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "TowerSighting: three towers are in view"

## The position in the tower list that the key at `i` names.
tower_place_at : U64 -> I64
tower_place_at = |i|
	match key_at(i).subject {
		Tower(position) => position.to_i64()
		Tree(_) | Cutout(_) | Cat(_) | Truck | Rail(_) | Bird(_) =>
			crash "TowerSighting: a tower's key names a tower"
	}

expect keys.len() == 3
expect tower_place_at(0) == 0
expect tower_place_at(2) == 2
expect TowerSighting.depth_keys([]).len() == 0
