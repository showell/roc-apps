# TowerPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Grade
import Maybe
import Scenery
import Tower
import TowerPlan
import Tuple
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

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

eq_maybe : Maybe.Maybe(a), Maybe.Maybe(a) -> Bool
eq_maybe = |ex, ey| (match ex {
	Just(exf0) => (match ey {
		Just(eyf0) => (exf0 == eyf0)
		_ => False
	})
	None => (match ey {
		None => True
		_ => False
	})
})

eq_scheme : Scenery.Scheme, Scenery.Scheme -> Bool
eq_scheme = |ex, ey| (match ex {
	AllGreen => (match ey {
		AllGreen => True
		_ => False
	})
	YellowGreen => (match ey {
		YellowGreen => True
		_ => False
	})
	RedGreen => (match ey {
		RedGreen => True
		_ => False
	})
})

eq_creature : Scenery.Creature, Scenery.Creature -> Bool
eq_creature = |ex, ey| (match ex {
	NoCreature => (match ey {
		NoCreature => True
		_ => False
	})
	Elephant => (match ey {
		Elephant => True
		_ => False
	})
	Giraffe => (match ey {
		Giraffe => True
		_ => False
	})
	Zebra => (match ey {
		Zebra => True
		_ => False
	})
	Rhino => (match ey {
		Rhino => True
		_ => False
	})
	DuckPond => (match ey {
		DuckPond => True
		_ => False
	})
})

eq_kind : DepthSort.Kind, DepthSort.Kind -> Bool
eq_kind = |ex, ey| (match ex {
	KTree => (match ey {
		KTree => True
		_ => False
	})
	KTower => (match ey {
		KTower => True
		_ => False
	})
	KCow => (match ey {
		KCow => True
		_ => False
	})
	KCat => (match ey {
		KCat => True
		_ => False
	})
	KTruck => (match ey {
		KTruck => True
		_ => False
	})
	KRail => (match ey {
		KRail => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("tl-fixed ", fixed_got, fixed_want, 0.0))
	line!(Grade.grade_ints("tl-cap   ", cap_got, cap_want))
	line!(Grade.grade_ints("tl-short ", short_got, short_want))
	line!(Grade.grade_bools("tl-mid   ", mid_flags_got, mid_flags_want))
	line!(Grade.grade_reals("tl-where ", where_got, where_want, 0.0))
	line!(Grade.grade_ints("tl-long  ", long_got, long_want))
	line!(Grade.grade_reals("tl-lwhere", long_where_got, long_where_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_reals("tl-key   ", key_got, key_want, 0.0))
	line!(Grade.grade_reals("tl-spread", spread_got, spread_want, 0.0))
	line!(Grade.grade_ints("tl-behind", behind_got, behind_want))
	line!(Grade.grade_ints("tl-cull  ", cull_got, cull_want))
	line!(Grade.grade_ints("tl-items ", items_got, items_want))
	Ok({})
}
