## These are TowerSighting's checks: where the masts stand, which are in
## view, how their beacons blink, and the keys the depth sort reads.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Clock
import DepthSort
import Frame
import Across
import Along
import Distance
import Grade
import Steps
import TowerSighting
import World

fixed_got : List(F64)
fixed_got = [
	TowerSighting.tower_beyond.to_metres(),
	TowerSighting.tower_right.to_metres(),
	TowerSighting.mid_tower_left.to_metres(),
	TowerSighting.beacon_period.to_f64(),
	TowerSighting.beacon_stagger.to_f64(),
]

fixed_want : List(F64)
fixed_want = [160.0, 20.0, 100.0, 120.0, 37.0]

cap_got : List(I64)
cap_got = [TowerSighting.max_vis_towers]

cap_want : List(I64)
cap_want = [16]

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

origin : Frame.Pose
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

## Three segments seen from the origin, the rider on the first of them, the
## route's segment `rider_number`.
short_view : U32 -> TowerSighting.View
short_view = |rider_number| {
	road: {
		world: [0, 1, 2, 3, 4].map(World.route_segment),
		chain: [
			rider_number,
			rider_number + 1,
			rider_number + 2,
		].map(World.SegmentIndex.number),
		pose: origin,
	},
	clock: Clock.start,
}

from_origin : TowerSighting.View
from_origin = short_view(0)

short_got : List(I64)
short_got = [
	TowerSighting.along_chain(from_origin).len().to_i64_wrap(),
	TowerSighting.segment_towers(from_origin, Frame.ChainPosition.first).len().to_i64_wrap(),
	TowerSighting.mid_tower(from_origin, Frame.ChainPosition.first).len().to_i64_wrap(),
	TowerSighting.in_view(from_origin).len().to_i64_wrap(),
]

short_want : List(I64)
short_want = [3, 1, 0, 3]

mid_flags_got : List(Bool)
mid_flags_got = segs.map(has_mid_tower)

## Whether a segment has a mast halfway along.
has_mid_tower : World.Segment -> Bool
has_mid_tower = |seg|
	match seg.mid_tower {
		MidTower => True
		NoMidTower => False
	}

mid_flags_want : List(Bool)
mid_flags_want = [False, False, False]

## The first mast in view on the segment at `position` in the chain.
first_tower_on : U32 -> TowerSighting.TowerItem
first_tower_on = |number| TowerSighting.segment_towers(
	from_origin,
	Frame.ChainPosition.number(number),
).first() ?? crash "TowerSightingSpec: the first two segments' masts are in view"

where_got : List(F64)
where_got = [
	first_tower_on(0).along.to_metres(),
	first_tower_on(0).across.to_metres(),
	first_tower_on(1).along.to_metres(),
	first_tower_on(1).across.to_metres(),
]

where_want : List(F64)
where_want = [660.0, 20.0, 480.0, 20.0]

## The 1200 m segment alone, seen from the origin.
long_view : TowerSighting.View
long_view = {
	road: {
		world: [World.route_segment(6)],
		chain: [0].map(World.SegmentIndex.number),
		pose: origin,
	},
	clock: Clock.start,
}

long_got : List(I64)
long_got = [
	TowerSighting.along_chain(long_view).len().to_i64_wrap(),
	TowerSighting.mid_tower(long_view, Frame.ChainPosition.first).len().to_i64_wrap(),
]

long_want : List(I64)
long_want = [2, 1]

long_towers : List(TowerSighting.TowerItem)
long_towers = TowerSighting.along_chain(long_view)

## The long segment's mast at `i`: its end mast, then its mid mast.
long_tower : U64 -> TowerSighting.TowerItem
long_tower = |i| long_towers.get(i) ?? crash "TowerSightingSpec: the long segment has two masts in view"

long_where_got : List(F64)
long_where_got = [
	long_tower(0).along.to_metres(),
	long_tower(0).across.to_metres(),
	long_tower(1).along.to_metres(),
	long_tower(1).across.to_metres(),
	long_tower(0).yaw.to_radians(),
	long_tower(1).yaw.to_radians(),
]

long_where_want : List(F64)
long_where_want = [
	1360.0,
	20.0,
	600.0,
	(-100.0),
	0.5235987750000001,
	0.0,
]

offsets_got : List(F64)
offsets_got = [
	TowerSighting.beacon_offset_for(0).to_f64(),
	TowerSighting.beacon_offset_for(1).to_f64(),
	TowerSighting.beacon_offset_for(2).to_f64(),
	TowerSighting.beacon_offset_for(3).to_f64(),
	TowerSighting.beacon_offset_for(4).to_f64(),
	TowerSighting.beacon_offset_for(5).to_f64(),
	TowerSighting.beacon_offset_for(10).to_f64(),
	TowerSighting.beacon_offset_for(60).to_f64(),
	TowerSighting.beacon_offset_for(120).to_f64(),
]

offsets_want : List(F64)
offsets_want = [0.0, 37.0, 74.0, 111.0, 28.0, 65.0, 10.0, 60.0, 0.0]

bright_got : List(F64)
bright_got = [
	TowerSighting.beacon_brightness(Steps.of(0)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(60)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(30)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(90)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(120)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(180)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(300)).to_f64(),
	TowerSighting.beacon_brightness(Steps.of(240)).to_f64(),
]

bright_want : List(F64)
bright_want = [0.0, 1.0, 0.5, 0.5, 0.0, 1.0, 1.0, 0.0]

## How bright the masts on the long segment are at `clock`: its end mast,
## then its mid mast.
long_brightness_at : Clock -> List(F64)
long_brightness_at = |clock|
	TowerSighting.along_chain({ ..long_view, clock }).map(|tower| tower.beacon_brightness.to_f64())

opposite_got : List(F64)
opposite_got = List.concat(long_brightness_at(Clock.start), long_brightness_at(Clock.at_step(60)))

opposite_want : List(F64)
opposite_want = [0.0, 1.0, 1.0, 0.0]

## How bright the first three segments' masts are at `clock`.
spread_at : Clock -> List(F64)
spread_at = |clock| {
	towers = TowerSighting.along_chain({ ..from_origin, clock })
	towers.map(|tower| tower.beacon_brightness.to_f64())
}

spread_got : List(F64)
spread_got = List.concat(spread_at(Clock.start), spread_at(Clock.at_step(30)))

brightness_at : U32 -> F64
brightness_at = |phase| TowerSighting.beacon_brightness(Steps.of(phase)).to_f64()

spread_want : List(F64)
spread_want = [0, 37, 74, 30, 67, 104].map(brightness_at)

behind_got : List(I64)
behind_got = [
	TowerSighting.in_view(short_view(0)).len().to_i64_wrap(),
	TowerSighting.in_view(short_view(1)).len().to_i64_wrap(),
	TowerSighting.in_view(short_view(2)).len().to_i64_wrap(),
	TowerSighting.tower_behind(short_view(1), World.SegmentIndex.first).len().to_i64_wrap(),
]

behind_want : List(I64)
behind_want = [3, 4, 4, 1]

cull_got : List(I64)
cull_got = [
	TowerSighting.along_chain({
		..from_origin,
		road: { ..from_origin.road, pose: { ..origin, along: Along.metres(5000.0) } },
	}).len().to_i64_wrap(),
	TowerSighting.along_chain({
		..from_origin,
		road: { ..from_origin.road, chain: [] },
	}).len().to_i64_wrap(),
]

cull_want : List(I64)
cull_want = [0, 0]

keys : List(DepthSort.DepthKey)
keys = TowerSighting.depth_keys(TowerSighting.along_chain(from_origin))

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "TowerSightingSpec: three masts are in view"

## The position in the mast list that the key at `i` names.
tower_place_at : U64 -> I64
tower_place_at = |i|
	match key_at(i).subject {
		Tower(position) => position.to_i64()
		Tree(_) | Critter(_) | Cat(_) | Truck | Rail(_) | Bird(_) =>
			crash "TowerSightingSpec: a mast's key names a mast"
	}

items_got : List(I64)
items_got = [
	keys.len().to_i64_wrap(),
	tower_place_at(0),
	tower_place_at(2),
	TowerSighting.depth_keys([]).len().to_i64_wrap(),
]

items_want : List(I64)
items_want = [3, 0, 2, 0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tl-fixed ",
			got: fixed_got,
			want: fixed_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tl-cap   ",
			got: cap_got,
			want: cap_want,
		}),
		Grade.ints({
			name: "tl-short ",
			got: short_got,
			want: short_want,
		}),
		Grade.bools({
			name: "tl-mid   ",
			got: mid_flags_got,
			want: mid_flags_want,
		}),
		Grade.reals({
			name: "tl-where ",
			got: where_got,
			want: where_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tl-long  ",
			got: long_got,
			want: long_want,
		}),
		Grade.reals({
			name: "tl-lwhere",
			got: long_where_got,
			want: long_where_want,
			tol: F64.from_bits(4427486594234968593),
		}),
		Grade.reals({
			name: "tl-offset",
			got: offsets_got,
			want: offsets_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tl-bright",
			got: bright_got,
			want: bright_want,
			tol: F64.from_bits(4502148214488346440),
		}),
		Grade.reals({
			name: "tl-oppose",
			got: opposite_got,
			want: opposite_want,
			tol: F64.from_bits(4502148214488346440),
		}),
		Grade.reals({
			name: "tl-spread",
			got: spread_got,
			want: spread_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "tl-behind",
			got: behind_got,
			want: behind_want,
		}),
		Grade.ints({
			name: "tl-cull  ",
			got: cull_got,
			want: cull_want,
		}),
		Grade.ints({
			name: "tl-items ",
			got: items_got,
			want: items_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
