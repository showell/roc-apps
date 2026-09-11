# RenderSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CatPlan
import CritterPlan
import DepthSort
import Frame
import Grade
import Maybe
import Pose
import RailPlan
import Render
import Scenery
import TowerPlan
import TreePlan
import TruckPlan
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = seg_list(0)

seg_list : I64 -> List(World.Segment)
seg_list = |i| (if (i >= U64.to_i64_wrap(List.len(World.route))) { [] } else { List.concat([World.segment_at(i)], seg_list((i + 1))) })

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

frame : Render.Collected
frame = Render.collect(segs, 0, origin, 500.0, 0.0, Pose.v_base, 500.0)

prev_got : List(I64)
prev_got = [Render.prev_index(0), Render.prev_index(1), Render.prev_index(5)]

prev_want : List(I64)
prev_want = [0, 0, 4]

merge_got : List(I64)
merge_got = ({
	n = U64.to_i64_wrap(List.len(frame.order))
	parts = (U64.to_i64_wrap(List.len(TreePlan.tree_items(frame.trees, 0))) + U64.to_i64_wrap(List.len(TowerPlan.tower_items(frame.towers, 0))))
	more = (U64.to_i64_wrap(List.len(CritterPlan.cow_items(frame.cows, 0))) + U64.to_i64_wrap(List.len(CatPlan.cat_items(frame.cats, 0))))
	rest = (U64.to_i64_wrap(List.len(TruckPlan.truck_items(frame.truck))) + U64.to_i64_wrap(List.len(RailPlan.rail_items(frame.rails, 0))))
	[(n - ((parts + more) + rest))]
})

merge_want : List(I64)
merge_want = [0]

present_got : List(Bool)
present_got = [(U64.to_i64_wrap(List.len(frame.trees)) > 0), (U64.to_i64_wrap(List.len(frame.towers)) > 0), (U64.to_i64_wrap(List.len(frame.cows)) > 0), (U64.to_i64_wrap(List.len(frame.rails)) > 0), (U64.to_i64_wrap(List.len(frame.order)) > 0)]

present_want : List(Bool)
present_want = [True, True, True, True, True]

cap_got : List(Bool)
cap_got = [(U64.to_i64_wrap(List.len(frame.trees)) <= TreePlan.max_vis_trees), (U64.to_i64_wrap(List.len(frame.towers)) <= TowerPlan.max_vis_towers), (U64.to_i64_wrap(List.len(frame.cows)) <= CritterPlan.max_vis_critters), (U64.to_i64_wrap(List.len(frame.cats)) <= CatPlan.max_vis_cats)]

cap_want : List(Bool)
cap_want = [True, True, True, True]

cap_values_got : List(I64)
cap_values_got = [TreePlan.max_vis_trees, TowerPlan.max_vis_towers, CatPlan.max_vis_cats]

cap_values_want : List(I64)
cap_values_want = [640, 16, 8]

descending : List(DepthSort.Item), I64 -> Bool
descending = |xs, i| (if ((i + 1) >= U64.to_i64_wrap(List.len(xs))) { True } else { (if DepthSort.deeper_than((List.get(xs, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range")).fwd, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd) { False } else { descending(xs, (i + 1)) }) })

sorted_got : List(Bool)
sorted_got = [descending(frame.order, 0), descending([], 0)]

sorted_want : List(Bool)
sorted_want = [True, True]

cull_got : List(Bool)
cull_got = [(frame.cull_seg >= 0), (frame.cull_size >= 0), (frame.cull_seg > 0)]

cull_want : List(Bool)
cull_want = [True, True, True]

seg_cull_got : List(I64)
seg_cull_got = ({
	a = Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 3)
	b = (U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).cows)) + U64.to_i64_wrap(List.len((List.get(segs, I64.to_u64_wrap(3)) ?? crash("list-at out of range")).pigs)))
	[(a - b), Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 0), Render.seg_cull_count(segs, [0, 1, 2, 3, 4, 5], 2), Render.walk_seg_cull(segs, [], 0)]
})

seg_cull_want : List(I64)
seg_cull_want = [0, 0, 0, 0]

shrink_got : List(Bool)
shrink_got = ({
	long = Render.walk_seg_cull(segs, [0, 1, 2, 3, 4, 5], 0)
	short = Render.walk_seg_cull(segs, [0, 1, 2], 0)
	[(long > short), (short == 0)]
})

shrink_want : List(Bool)
shrink_want = [True, True]

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
	line!(Grade.grade_ints("rn-prev  ", prev_got, prev_want))
	line!(Grade.grade_ints("rn-merge ", merge_got, merge_want))
	line!(Grade.grade_bools("rn-presnt", present_got, present_want))
	line!(Grade.grade_bools("rn-cap   ", cap_got, cap_want))
	line!(Grade.grade_ints("rn-caps  ", cap_values_got, cap_values_want))
	line!(Grade.grade_bools("rn-sorted", sorted_got, sorted_want))
	line!(Grade.grade_bools("rn-cull  ", cull_got, cull_want))
	line!(Grade.grade_ints("rn-segcul", seg_cull_got, seg_cull_want))
	line!(Grade.grade_bools("rn-shrink", shrink_got, shrink_want))
	Ok({})
}
