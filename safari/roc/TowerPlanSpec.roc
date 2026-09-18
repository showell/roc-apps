# TowerPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import Grade
import Text
import Tower
import TowerPlan
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

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
short_got = [U64.to_i64_wrap(List.len(TowerPlan.walk_towers(segs, chain, origin, 0))), U64.to_i64_wrap(List.len(TowerPlan.seg_towers(segs, chain, origin, 0))), U64.to_i64_wrap(List.len(TowerPlan.seg_mid_tower(segs, chain, origin, 0))), U64.to_i64_wrap(List.len(TowerPlan.all_towers(segs, chain, origin, 0)))]

short_want : List(I64)
short_want = [3, 1, 0, 3]

mid_flags_got : List(Bool)
mid_flags_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).has_mid_tower, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).has_mid_tower, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).has_mid_tower]

mid_flags_want : List(Bool)
mid_flags_want = [False, False, False]

where_got : List(F64)
where_got = ({
	t = (List.get(TowerPlan.seg_towers(segs, chain, origin, 0), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	u = (List.get(TowerPlan.seg_towers(segs, chain, origin, 1), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[t.a0, t.x0, u.a0, u.x0]
})

where_want : List(F64)
where_want = [660.0, 22.0, 480.0, 22.0]

long_segs : List(World.Segment)
long_segs = [World.segment_at(6)]

long_got : List(I64)
long_got = [U64.to_i64_wrap(List.len(TowerPlan.walk_towers(long_segs, [0], origin, 0))), U64.to_i64_wrap(List.len(TowerPlan.seg_mid_tower(long_segs, [0], origin, 0)))]

long_want : List(I64)
long_want = [2, 1]

long_where_got : List(F64)
long_where_got = ({
	ts = TowerPlan.walk_towers(long_segs, [0], origin, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).a0, (List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x0, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).a0, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).x0, (List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).yaw, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).yaw]
})

long_where_want : List(F64)
long_where_want = [1360.0, 22.0, 600.0, (-98.0), 0.5235987750000001, 0.0]

key_got : List(F64)
key_got = ({
	ts = TowerPlan.walk_towers(long_segs, [0], origin, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).off, Tower.beacon_offset_for(0), Tower.beacon_offset_for(60)]
})

key_want : List(F64)
key_want = [0.0, 60.0, 0.0, 60.0]

spread_got : List(F64)
spread_got = ({
	ts = TowerPlan.walk_towers(segs, chain, origin, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).off, (List.get(ts, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).off]
})

spread_want : List(F64)
spread_want = [0.0, 37.0, 74.0]

behind_got : List(I64)
behind_got = [U64.to_i64_wrap(List.len(TowerPlan.all_towers(segs, chain, origin, 0))), U64.to_i64_wrap(List.len(TowerPlan.all_towers(segs, chain, origin, 1))), U64.to_i64_wrap(List.len(TowerPlan.all_towers(segs, chain, origin, 2))), U64.to_i64_wrap(List.len(TowerPlan.behind_tower(segs, chain, origin, 0)))]

behind_want : List(I64)
behind_want = [3, 4, 4, 1]

cull_got : List(I64)
cull_got = [U64.to_i64_wrap(List.len(TowerPlan.walk_towers(segs, chain, { along: 5000.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0))), U64.to_i64_wrap(List.len(TowerPlan.walk_towers(segs, [], origin, 0)))]

cull_want : List(I64)
cull_want = [0, 0]

items_got : List(I64)
items_got = ({
	ts = TowerPlan.walk_towers(segs, chain, origin, 0)
	its = TowerPlan.tower_items(ts, 0)
	[U64.to_i64_wrap(List.len(its)), (List.get(its, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i, (List.get(its, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).i, U64.to_i64_wrap(List.len(TowerPlan.tower_items([], 0)))]
})

items_want : List(I64)
items_want = [3, 0, 2, 0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([14, 23, 73, 28, 17, 36, 13, 22, 2], fixed_got, fixed_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 24, 15, 31, 2, 2, 2], cap_got, cap_want)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 19, 20, 16, 21, 14, 2], short_got, short_want)))
	line!(Text.printed(Grade.grade_bools([14, 23, 73, 26, 17, 22, 2, 2, 2], mid_flags_got, mid_flags_want)))
	line!(Text.printed(Grade.grade_reals([14, 23, 73, 27, 20, 13, 21, 13, 2], where_got, where_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 23, 16, 18, 29, 2, 2], long_got, long_want)))
	line!(Text.printed(Grade.grade_reals([14, 23, 73, 23, 27, 20, 13, 21, 13], long_where_got, long_where_want, F64.from_bits(4427486594234968593))))
	line!(Text.printed(Grade.grade_reals([14, 23, 73, 34, 13, 30, 2, 2, 2], key_got, key_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 23, 73, 19, 31, 21, 13, 15, 22], spread_got, spread_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 32, 13, 20, 17, 18, 22], behind_got, behind_want)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 24, 25, 23, 23, 2, 2], cull_got, cull_want)))
	line!(Text.printed(Grade.grade_ints([14, 23, 73, 17, 14, 13, 26, 19, 2], items_got, items_want)))
	Ok({})
}
