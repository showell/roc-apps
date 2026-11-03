# TowerPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Frame
import Grade
import Tower
import TowerPlan
import World

fixed_got : List(F64)
fixed_got = [TowerPlan.tower_beyond, TowerPlan.tower_right, TowerPlan.seg_tower_left]

fixed_want : List(F64)
fixed_want = [160.0, 20.0, 100.0]

cap_got : List(I64)
cap_got = [TowerPlan.max_vis_towers]

cap_want : List(I64)
cap_want = [16]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

short_got : List(I64)
short_got = [TowerPlan.walk_towers(segs, chain, origin).len().to_i64_wrap(), TowerPlan.seg_towers(segs, chain, origin, 0).len().to_i64_wrap(), TowerPlan.seg_mid_tower(segs, chain, origin, 0).len().to_i64_wrap(), TowerPlan.all_towers(segs, chain, origin, 0).len().to_i64_wrap()]

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

where_got : List(F64)
where_got = (
	{
		t = (List.get(TowerPlan.seg_towers(segs, chain, origin, 0), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		u = (List.get(TowerPlan.seg_towers(segs, chain, origin, 1), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[t.a0, t.x0, u.a0, u.x0]
	}
)

where_want : List(F64)
where_want = [660.0, 22.0, 480.0, 22.0]

long_segs : List(World.Segment)
long_segs = [World.segment_at(6)]

long_got : List(I64)
long_got = [TowerPlan.walk_towers(long_segs, [0], origin).len().to_i64_wrap(), TowerPlan.seg_mid_tower(long_segs, [0], origin, 0).len().to_i64_wrap()]

long_want : List(I64)
long_want = [2, 1]

long_where_got : List(F64)
long_where_got = (
	{
		ts = TowerPlan.walk_towers(long_segs, [0], origin)
		[(List.get(ts, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).a0, (List.get(ts, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).x0, (List.get(ts, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).a0, (List.get(ts, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).x0, (List.get(ts, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).yaw, (List.get(ts, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).yaw]
	}
)

long_where_want : List(F64)
long_where_want = [1360.0, 22.0, 600.0, (-98.0), 0.5235987750000001, 0.0]

key_got : List(F64)
key_got = (
	{
		ts = TowerPlan.walk_towers(long_segs, [0], origin)
		[(List.get(ts, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).off, Tower.beacon_offset_for(0), Tower.beacon_offset_for(60)]
	}
)

key_want : List(F64)
key_want = [0.0, 60.0, 0.0, 60.0]

spread_got : List(F64)
spread_got = (
	{
		ts = TowerPlan.walk_towers(segs, chain, origin)
		[(List.get(ts, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).off]
	}
)

spread_want : List(F64)
spread_want = [0.0, 37.0, 74.0]

behind_got : List(I64)
behind_got = [TowerPlan.all_towers(segs, chain, origin, 0).len().to_i64_wrap(), TowerPlan.all_towers(segs, chain, origin, 1).len().to_i64_wrap(), TowerPlan.all_towers(segs, chain, origin, 2).len().to_i64_wrap(), TowerPlan.behind_tower(segs, chain, origin, 0).len().to_i64_wrap()]

behind_want : List(I64)
behind_want = [3, 4, 4, 1]

cull_got : List(I64)
cull_got = [TowerPlan.walk_towers(segs, chain, { along: 5000.0, across: 0.0, yaw: 0.0, hw: 2.0 }).len().to_i64_wrap(), TowerPlan.walk_towers(segs, [], origin).len().to_i64_wrap()]

cull_want : List(I64)
cull_want = [0, 0]

items_got : List(I64)
items_got = (
	{
		ts = TowerPlan.walk_towers(segs, chain, origin)
		its = TowerPlan.tower_items(ts)
		[its.len().to_i64_wrap(), (List.get(its, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).i, (List.get(its, I64.to_u64_wrap(2)) ?? crash ("list-at out of range")).i, TowerPlan.tower_items([]).len().to_i64_wrap()]
	}
)

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
