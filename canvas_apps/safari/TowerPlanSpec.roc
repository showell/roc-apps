## These are TowerPlan's checks: where the masts stand, which are in
## view, their beacons' offsets, and the keys the depth sort reads.
app [main!] {
	lib: "../lib/main.roc",
}

import DepthSort
import Frame
import Grade
import Tower
import TowerPlan
import World

fixed_got : List(F64)
fixed_got = [
	TowerPlan.tower_beyond,
	TowerPlan.tower_right,
	TowerPlan.mid_tower_left,
]

fixed_want : List(F64)
fixed_want = [160.0, 20.0, 100.0]

cap_got : List(I64)
cap_got = [TowerPlan.max_vis_towers]

cap_want : List(I64)
cap_want = [16]

segs : List(World.Segment)
segs = [
	World.segment_at(0),
	World.segment_at(1),
	World.segment_at(2),
]

origin : Frame.Pose
origin = {
	along: 0.0,
	across: 0.0,
	yaw: 0.0,
	hw: 2.0,
}

## The first three segments seen from the origin, the rider on segment
## `rider_segment`.
short_view : I64 -> TowerPlan.View
short_view = |rider_segment| {
	world: segs,
	chain: [0, 1, 2],
	pose: origin,
	rider_segment,
}

from_origin : TowerPlan.View
from_origin = short_view(0)

short_got : List(I64)
short_got = [
	TowerPlan.along_chain(from_origin).len().to_i64_wrap(),
	TowerPlan.segment_towers(from_origin, 0).len().to_i64_wrap(),
	TowerPlan.mid_tower(from_origin, 0).len().to_i64_wrap(),
	TowerPlan.in_view(from_origin).len().to_i64_wrap(),
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

## The first mast in view on the segment at `place` in the chain.
first_tower_on : I64 -> TowerPlan.TowerItem
first_tower_on = |place| TowerPlan.segment_towers(
	from_origin,
	place,
).first() ?? crash "TowerPlanSpec: the first two segments' masts are in view"

where_got : List(F64)
where_got = [
	first_tower_on(0).along,
	first_tower_on(0).across,
	first_tower_on(1).along,
	first_tower_on(1).across,
]

where_want : List(F64)
where_want = [660.0, 22.0, 480.0, 22.0]

## The 1200 m segment alone, seen from the origin.
long_view : TowerPlan.View
long_view = {
	world: [World.segment_at(6)],
	chain: [0],
	pose: origin,
	rider_segment: 0,
}

long_got : List(I64)
long_got = [
	TowerPlan.along_chain(long_view).len().to_i64_wrap(),
	TowerPlan.mid_tower(long_view, 0).len().to_i64_wrap(),
]

long_want : List(I64)
long_want = [2, 1]

long_towers : List(TowerPlan.TowerItem)
long_towers = TowerPlan.along_chain(long_view)

## The long segment's mast at `i`: its end mast, then its mid mast.
long_tower : U64 -> TowerPlan.TowerItem
long_tower = |i| long_towers.get(i) ?? crash "TowerPlanSpec: the long segment has two masts in view"

long_where_got : List(F64)
long_where_got = [
	long_tower(0).along,
	long_tower(0).across,
	long_tower(1).along,
	long_tower(1).across,
	long_tower(0).yaw,
	long_tower(1).yaw,
]

long_where_want : List(F64)
long_where_want = [
	1360.0,
	22.0,
	600.0,
	(-98.0),
	0.5235987750000001,
	0.0,
]

key_got : List(F64)
key_got = [
	long_tower(0).beacon_offset,
	long_tower(1).beacon_offset,
	Tower.beacon_offset_for(0),
	Tower.beacon_offset_for(60),
]

key_want : List(F64)
key_want = [0.0, 60.0, 0.0, 60.0]

spread_got : List(F64)
spread_got = TowerPlan.along_chain(from_origin).map(|tower| tower.beacon_offset)

spread_want : List(F64)
spread_want = [0.0, 37.0, 74.0]

behind_got : List(I64)
behind_got = [
	TowerPlan.in_view(short_view(0)).len().to_i64_wrap(),
	TowerPlan.in_view(short_view(1)).len().to_i64_wrap(),
	TowerPlan.in_view(short_view(2)).len().to_i64_wrap(),
	TowerPlan.tower_behind(short_view(1)).len().to_i64_wrap(),
]

behind_want : List(I64)
behind_want = [3, 4, 4, 1]

cull_got : List(I64)
cull_got = [
	TowerPlan.along_chain({
		..from_origin,
		pose: {
			along: 5000.0,
			across: 0.0,
			yaw: 0.0,
			hw: 2.0,
		},
	}).len().to_i64_wrap(),
	TowerPlan.along_chain({ ..from_origin, chain: [] }).len().to_i64_wrap(),
]

cull_want : List(I64)
cull_want = [0, 0]

keys : List(DepthSort.DepthKey)
keys = TowerPlan.depth_keys(TowerPlan.along_chain(from_origin))

## The depth key at `i`.
key_at : U64 -> DepthSort.DepthKey
key_at = |i| keys.get(i) ?? crash "TowerPlanSpec: three masts are in view"

## The place in the mast list that the key at `i` names.
tower_place_at : U64 -> I64
tower_place_at = |i|
	match key_at(i).subject {
		Tower(place) => place.to_i64_wrap()
		Tree(_) | Critter(_) | Cat(_) | Truck | Rail(_) | Bird(_) => crash "TowerPlanSpec: a mast's key names a mast"
	}

items_got : List(I64)
items_got = [
	keys.len().to_i64_wrap(),
	tower_place_at(0),
	tower_place_at(2),
	TowerPlan.depth_keys([]).len().to_i64_wrap(),
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
			name: "tl-key   ",
			got: key_got,
			want: key_want,
			tol: 0.0,
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
