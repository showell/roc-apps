# ItemDrawSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Grade
import ItemDraw
import Maybe
import SceneLimits
import Scenery
import TowerPlan
import TreePlan
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fixed_got : List(F64)
fixed_got = [SceneLimits.crown_shade_dist, SceneLimits.detail_dist]

fixed_want : List(F64)
fixed_want = [80.0, 200.0]

tree_at : F64 -> TreePlan.TreeItem
tree_at = |fwd| { right: 0.0, fwd: fwd, height: 5.85, color: 1858082 }

spread : List(TreePlan.TreeItem)
spread = [tree_at(10.0), tree_at(20.0), tree_at(30.0), tree_at(40.0), tree_at(50.0)]

count_got : List(I64)
count_got = [ItemDraw.closer_count(spread, 10.0, 0), ItemDraw.closer_count(spread, 30.0, 0), ItemDraw.closer_count(spread, 50.0, 0), ItemDraw.closer_count(spread, 60.0, 0), ItemDraw.closer_count(spread, 5.0, 0), ItemDraw.closer_count([], 10.0, 0)]

count_want : List(I64)
count_want = [0, 2, 4, 5, 0, (6 - 6)]

tied : List(TreePlan.TreeItem)
tied = [tree_at(20.0), tree_at(20.0), tree_at(20.0), tree_at(20.0)]

tie_got : List(I64)
tie_got = [ItemDraw.closer_count(tied, 20.0, 0), ItemDraw.closer_count(tied, 20.1, 0), ItemDraw.closer_count(tied, 19.9, 0)]

tie_want : List(I64)
tie_want = [0, 4, 0]

shade_got : List(F64)
shade_got = [ItemDraw.crown_shade_of(0.0), ItemDraw.crown_shade_of(20.0), ItemDraw.crown_shade_of(40.0), ItemDraw.crown_shade_of(80.0), ItemDraw.crown_shade_of(200.0), ItemDraw.crown_shade_of((0.0 - 50.0))]

shade_want : List(F64)
shade_want = [1.0, 0.75, 0.5, 0.0, 0.0, 1.0]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

a_tower : TowerPlan.TowerItem
a_tower = { map: Frame.chain_map(0), a0: 200.0, x0: 22.0, yaw: 0.0, fwd: 200.0, off: 0.0 }

base_got : List(I64)
base_got = [U64.to_i64_wrap(List.len(ItemDraw.tower_base(segs, chain, origin, a_tower, 0))), U64.to_i64_wrap(List.len(ItemDraw.tower_base(segs, chain, origin, { map: Frame.chain_map(0), a0: 200.0, x0: 22.0, yaw: 1.0, fwd: 200.0, off: 0.0 }, 0)))]

base_want : List(I64)
base_want = [4, 4]

corner_got : List(F64)
corner_got = ({
	b = ItemDraw.tower_base(segs, chain, origin, a_tower, 0)
	[(List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(b, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).forward, (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(b, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right]
})

corner_want : List(F64)
corner_want = [194.0, 206.0, 14.0, 26.0]

drawn : F64 -> I64
drawn = |a0| U64.to_i64_wrap(List.len(ItemDraw.draw_one_tower(segs, chain, origin, { map: Frame.chain_map(0), a0: a0, x0: 22.0, yaw: 0.0, fwd: a0, off: 0.0 }, 500.0, 0.0)))

tower_got : List(Bool)
tower_got = [(drawn(200.0) > 0), (drawn(1000.0) > 0), (drawn((0.0 - 100.0)) == 0)]

tower_want : List(Bool)
tower_want = [True, True, True]

cluster : List(TreePlan.TreeItem)
cluster = [tree_at(10.0), tree_at(11.0), tree_at(12.0), tree_at(13.0), tree_at(14.0)]

tree_got : List(Bool)
tree_got = ({
	near = ItemDraw.draw_one_tree(cluster, 0, 500.0)
	far = ItemDraw.draw_one_tree(cluster, 4, 500.0)
	near_tier = U64.to_i64_wrap(List.len((List.get(near, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).pts))
	far_tier = U64.to_i64_wrap(List.len((List.get(far, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).pts))
	[(U64.to_i64_wrap(List.len(near)) > 0), (U64.to_i64_wrap(List.len(far)) > 0), (near_tier > far_tier), (far_tier >= 6)]
})

tree_want : List(Bool)
tree_want = [True, True, True, True]

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
	line!(Grade.grade_reals("id-fixed ", fixed_got, fixed_want, 0.0))
	line!(Grade.grade_ints("id-count ", count_got, count_want))
	line!(Grade.grade_ints("id-tie   ", tie_got, tie_want))
	line!(Grade.grade_reals("id-shade ", shade_got, shade_want, 0.0))
	line!(Grade.grade_ints("id-base  ", base_got, base_want))
	line!(Grade.grade_reals("id-corner", corner_got, corner_want, 0.0001))
	line!(Grade.grade_bools("id-tower ", tower_got, tower_want))
	line!(Grade.grade_bools("id-tree  ", tree_got, tree_want))
	Ok({})
}
