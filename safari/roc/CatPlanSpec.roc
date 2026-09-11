# CatPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CatPlan
import DepthSort
import Frame
import Grade
import Maybe
import Scenery
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

has_got : List(Bool)
has_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).has_cat, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).has_cat]

has_want : List(Bool)
has_want = [False, True, False]

gap_got : List(F64)
gap_got = [CatPlan.chain_gap(segs, chain, 0.0, 0), CatPlan.chain_gap(segs, chain, 0.0, 1), CatPlan.chain_gap(segs, chain, 0.0, 2), CatPlan.chain_gap(segs, chain, 120.0, 0), CatPlan.chain_gap(segs, chain, 120.0, 1), CatPlan.chain_gap(segs, chain, 120.0, 2)]

gap_want : List(F64)
gap_want = [0.0, 500.0, 820.0, (-120.0), 380.0, 700.0]

riding : F64 -> List(CatPlan.CatItem)
riding = |a| CatPlan.walk_cats(segs, chain, { along: a, across: 0.0, yaw: 0.0, hw: 2.0 }, 500.0, a, 1.0, 0)

seen : List(CatPlan.CatItem)
seen = riding(300.0)

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(seen)), U64.to_i64_wrap(List.len(CatPlan.seg_cat(segs, chain, origin, 0, 500.0, 0.0, 1.0))), U64.to_i64_wrap(List.len(CatPlan.seg_cat(segs, chain, origin, 2, 500.0, 0.0, 1.0))), CatPlan.max_vis_cats]

count_want : List(I64)
count_want = [1, 0, 0, 8]

place_got : List(F64)
place_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).height, (List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).lift]

place_want : List(F64)
place_want = [1.7, 0.0]

pose_got : List(I64)
pose_got = [(List.get(seen, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pose_idx]

pose_want : List(I64)
pose_want = [0]

closing_got : List(F64)
closing_got = ({
	a = (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	b = (List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	c = (List.get(riding(400.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd
	[(b - a), (c - b), ((List.get(riding(300.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right - (List.get(riding(200.0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right)]
})

closing_want : List(F64)
closing_want = [(-100.0), (-100.0), 0.0]

cull_got : List(I64)
cull_got = [U64.to_i64_wrap(List.len(riding(0.0))), U64.to_i64_wrap(List.len(riding(200.0))), U64.to_i64_wrap(List.len(riding(500.0))), U64.to_i64_wrap(List.len(riding(600.0))), U64.to_i64_wrap(List.len(CatPlan.walk_cats(segs, [], origin, 500.0, 0.0, 1.0, 0))), U64.to_i64_wrap(List.len(CatPlan.walk_cats(segs, [0], origin, 500.0, 0.0, 1.0, 0)))]

cull_want : List(I64)
cull_want = [0, 1, 1, 0, 0, 0]

items_got : List(I64)
items_got = [U64.to_i64_wrap(List.len(CatPlan.cat_items(seen, 0))), U64.to_i64_wrap(List.len(CatPlan.cat_items([], 0))), (List.get(CatPlan.cat_items(seen, 0), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i]

items_want : List(I64)
items_want = [1, 0, 0]

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
	line!(Grade.grade_bools("cp-has   ", has_got, has_want))
	line!(Grade.grade_reals("cp-gap   ", gap_got, gap_want, 0.0))
	line!(Grade.grade_ints("cp-count ", count_got, count_want))
	line!(Grade.grade_reals("cp-place ", place_got, place_want, 0.0))
	line!(Grade.grade_ints("cp-pose  ", pose_got, pose_want))
	line!(Grade.grade_reals("cp-close ", closing_got, closing_want, 0.0001))
	line!(Grade.grade_ints("cp-cull  ", cull_got, cull_want))
	line!(Grade.grade_ints("cp-items ", items_got, items_want))
	Ok({})
}
