# CritterPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CritterPlan
import DepthSort
import Frame
import Grade
import Maybe
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

reach_got : List(I64)
reach_got = [CritterPlan.farm_seg_reach, CritterPlan.safari_seg_reach]

reach_want : List(I64)
reach_want = [3, 5]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2), World.segment_at(3), World.segment_at(4), World.segment_at(5)]

chain : List(I64)
chain = [0, 1, 2, 3, 4, 5]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

farm_at : I64 -> I64
farm_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_farm(segs, chain, origin, d, 2.0)))

safari_at : I64 -> I64
safari_at = |d| U64.to_i64_wrap(List.len(CritterPlan.seg_safari(segs, chain, origin, d, 2.0)))

cutoff_got : List(Bool)
cutoff_got = [(farm_at(0) > 0), (farm_at(2) > 0), (farm_at(3) == 0), (farm_at(4) == 0), (farm_at(5) == 0), (safari_at(3) > 0), (safari_at(4) > 0), (safari_at(5) == 0)]

cutoff_want : List(Bool)
cutoff_want = [True, True, True, True, True, True, True, True]

term_got : List(I64)
term_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(18)], [0], origin, 0, 2.0)))]

term_want : List(I64)
term_want = [0]

term_flag_got : List(Bool)
term_flag_got = [(U64.to_i64_wrap(List.len(CritterPlan.seg_safari([World.segment_at(0)], [0], origin, 0, 2.0))) > 0)]

term_flag_want : List(Bool)
term_flag_want = [True]

duck_count : I64 -> I64
duck_count = |i| U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(i)], [0], origin, 0)))

duck_got : List(Bool)
duck_got = [(duck_count(12) > 0), (duck_count(0) == 0), (duck_count(4) == 0), (duck_count(18) == 0)]

duck_want : List(Bool)
duck_want = [True, True, True, True]

duck_reach_got : List(I64)
duck_reach_got = [U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 5))), U64.to_i64_wrap(List.len(CritterPlan.seg_ducks([World.segment_at(12)], [0], origin, 0)))]

duck_reach_want : List(I64)
duck_reach_want = [0, 6]

order_got : List(I64)
order_got = ({
	d0 = U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(segs, chain, origin, 0)))
	f0 = farm_at(0)
	s0 = safari_at(0)
	k0 = U64.to_i64_wrap(List.len(CritterPlan.seg_ducks(segs, chain, origin, 0)))
	[(d0 - ((f0 + s0) + k0))]
})

order_want : List(I64)
order_want = [0]

one_seg : List(World.Segment)
one_seg = [World.segment_at(0)]

walk_got : List(I64)
walk_got = [U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, [], origin, 0))), (U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(one_seg, [0], origin, 0))) - U64.to_i64_wrap(List.len(CritterPlan.seg_billboards(one_seg, [0], origin, 0)))), U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 6)))]

walk_want : List(I64)
walk_want = [0, 0, 0]

grow_got : List(Bool)
grow_got = ({
	a = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 0)))
	b = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 1)))
	c = U64.to_i64_wrap(List.len(CritterPlan.walk_billboards(segs, chain, origin, 2)))
	[(a >= b), (b >= c)]
})

grow_want : List(Bool)
grow_want = [True, True]

behind_got : List(Bool)
behind_got = [(U64.to_i64_wrap(List.len(CritterPlan.behind_billboards(segs, chain, origin, 0))) >= 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(12)))) > 0), (U64.to_i64_wrap(List.len(CritterPlan.behind_ducks(segs, chain, origin, World.segment_at(0)))) == 0)]

behind_want : List(Bool)
behind_want = [True, True, True]

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
	line!(Grade.grade_ints("cn-reach ", reach_got, reach_want))
	line!(Grade.grade_bools("cn-cutoff", cutoff_got, cutoff_want))
	line!(Grade.grade_ints("cn-term  ", term_got, term_want))
	line!(Grade.grade_bools("cn-tflag ", term_flag_got, term_flag_want))
	line!(Grade.grade_bools("cn-duck  ", duck_got, duck_want))
	line!(Grade.grade_ints("cn-dreach", duck_reach_got, duck_reach_want))
	line!(Grade.grade_ints("cn-order ", order_got, order_want))
	line!(Grade.grade_ints("cn-walk  ", walk_got, walk_want))
	line!(Grade.grade_bools("cn-grow  ", grow_got, grow_want))
	line!(Grade.grade_bools("cn-behind", behind_got, behind_want))
	Ok({})
}
