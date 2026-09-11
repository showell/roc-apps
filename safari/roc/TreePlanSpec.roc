# TreePlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Grade
import Maybe
import Scenery
import TreePlan
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

up_road : Frame.Pose
up_road = { along: 100.0, across: 0.0, yaw: 0.0, hw: 2.0 }

planted_got : List(I64)
planted_got = [U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees)), U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).trees)), U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).trees)), TreePlan.max_vis_trees]

planted_want : List(I64)
planted_want = [28, 16, 22, 640]

one : List(TreePlan.TreeItem)
one = TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 120.0, across: 3.5, color: 1858082, height: 5.85 })

one_got : List(F64)
one_got = [(List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height]

one_want : List(F64)
one_want = [3.5, 120.0, 5.85]

one_colour_got : List(I64)
one_colour_got = [U64.to_i64_wrap(List.len(one)), (List.get(one, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color]

one_colour_want : List(I64)
one_colour_want = [1, 1858082]

cull_got : List(I64)
cull_got = [U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 0.4, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 0.5, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 1.0, 2.0, { along: 120.0, across: 3.5, color: 1858082, height: 5.85 }))), U64.to_i64_wrap(List.len(TreePlan.place_tree(segs, chain, origin, 0, 500.0, 2.0, { along: 2000.0, across: 3.5, color: 1858082, height: 5.85 })))]

cull_want : List(I64)
cull_want = [0, 1, 0, 0]

seg0_got : List(I64)
seg0_got = [U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0))), U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, up_road, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0))), U64.to_i64_wrap(List.len(TreePlan.seg_trees(segs, chain, origin, 0, 1.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)))]

seg0_want : List(I64)
seg0_want = [28, 20, 0]

order_got : List(F64)
order_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).fwd, (List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(ts, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).right]
})

order_want : List(F64)
order_want = [6.0, 6.0, 36.0, (-3.5), 3.5]

height_got : List(F64)
height_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	[(List.get(ts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(ts, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).height]
})

height_want : List(F64)
height_want = [5.85, 4.5]

items_got : List(I64)
items_got = ({
	ts = TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0)
	its = TreePlan.tree_items(ts, 0)
	[U64.to_i64_wrap(List.len(its)), (List.get(its, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i, (List.get(its, I64.to_u64_wrap(27)) ?? crash("list-at out of range")).i, U64.to_i64_wrap(List.len(TreePlan.tree_items([], 0)))]
})

items_want : List(I64)
items_want = [28, 0, 27, 0]

item_fwd_got : List(F64)
item_fwd_got = ({
	its = TreePlan.tree_items(TreePlan.seg_trees(segs, chain, origin, 0, 500.0, 2.0, (List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).trees, 0), 0)
	[(List.get(its, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd, (List.get(its, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).fwd]
})

item_fwd_want : List(F64)
item_fwd_want = [6.0, 36.0]

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
	line!(Grade.grade_ints("te-plant ", planted_got, planted_want))
	line!(Grade.grade_reals("te-one   ", one_got, one_want, 0.0001))
	line!(Grade.grade_ints("te-colour", one_colour_got, one_colour_want))
	line!(Grade.grade_ints("te-cull  ", cull_got, cull_want))
	line!(Grade.grade_ints("te-seg0  ", seg0_got, seg0_want))
	line!(Grade.grade_reals("te-order ", order_got, order_want, 0.0001))
	line!(Grade.grade_reals("te-height", height_got, height_want, F64.from_bits(4427486594234968593)))
	line!(Grade.grade_ints("te-items ", items_got, items_want))
	line!(Grade.grade_reals("te-ifwd  ", item_fwd_got, item_fwd_want, 0.0001))
	Ok({})
}
