# TruckPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Grade
import Maybe
import Scenery
import TruckPlan
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

here : Frame.Pose
here = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

lengths_got : List(F64)
lengths_got = [(List.get(segs, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).length, (List.get(segs, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).length]

lengths_want : List(F64)
lengths_want = [500.0, 320.0, 400.0]

lead_of : F64 -> TruckPlan.TruckAt
lead_of = |lead| TruckPlan.truck_at(segs, chain, here, 0.0, lead)

present_got : List(Bool)
present_got = [lead_of(100.0).present, lead_of(499.0).present, lead_of(600.0).present, lead_of(900.0).present, lead_of(2000.0).present, lead_of(0.0).present, lead_of((0.0 - 50.0)).present]

present_want : List(Bool)
present_want = [True, True, True, True, False, False, False]

landed_got : List(I64)
landed_got = [lead_of(100.0).d, lead_of(499.0).d, lead_of(600.0).d, lead_of(900.0).d]

landed_want : List(I64)
landed_want = [0, 0, 1, 2]

along_got : List(F64)
along_got = [lead_of(100.0).along, lead_of(499.0).along, lead_of(600.0).along, lead_of(900.0).along]

along_want : List(F64)
along_want = [100.0, 499.0, 100.0, 80.0]

fwd_got : List(F64)
fwd_got = [lead_of(100.0).fwd, lead_of(499.0).fwd]

fwd_want : List(F64)
fwd_want = [100.0, 499.0]

none_got : List(F64)
none_got = ({
	n = lead_of(2000.0)
	[n.along, n.fwd, I64.to_f64(n.d), TruckPlan.no_truck.along, TruckPlan.no_truck.fwd, I64.to_f64(TruckPlan.no_truck.d)]
})

none_want : List(F64)
none_want = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

none_flag_got : List(Bool)
none_flag_got = [TruckPlan.no_truck.present, lead_of(2000.0).present]

none_flag_want : List(Bool)
none_flag_want = [False, False]

behind : TruckPlan.TruckAt
behind = TruckPlan.truck_at(segs, chain, { along: 100.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0)

behind_got : List(Bool)
behind_got = [behind.present, TruckPlan.truck_at(segs, chain, { along: 99.0, across: 0.0, yaw: 0.0, hw: 2.0 }, 0.0, 100.0).present]

behind_want : List(Bool)
behind_want = [False, True]

items_got : List(I64)
items_got = [U64.to_i64_wrap(List.len(TruckPlan.truck_items(lead_of(100.0)))), U64.to_i64_wrap(List.len(TruckPlan.truck_items(lead_of(2000.0)))), U64.to_i64_wrap(List.len(TruckPlan.truck_items(TruckPlan.no_truck))), (List.get(TruckPlan.truck_items(lead_of(100.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).i]

items_want : List(I64)
items_want = [1, 0, 0, 0]

item_fwd_got : List(F64)
item_fwd_got = [(List.get(TruckPlan.truck_items(lead_of(499.0)), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).fwd]

item_fwd_want : List(F64)
item_fwd_want = [499.0]

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
	line!(Grade.grade_reals("tp-length", lengths_got, lengths_want, 0.0))
	line!(Grade.grade_bools("tp-presnt", present_got, present_want))
	line!(Grade.grade_ints("tp-landed", landed_got, landed_want))
	line!(Grade.grade_reals("tp-along ", along_got, along_want, 0.0))
	line!(Grade.grade_reals("tp-fwd   ", fwd_got, fwd_want, 0.0001))
	line!(Grade.grade_reals("tp-none  ", none_got, none_want, 0.0))
	line!(Grade.grade_bools("tp-nflag ", none_flag_got, none_flag_want))
	line!(Grade.grade_bools("tp-behind", behind_got, behind_want))
	line!(Grade.grade_ints("tp-items ", items_got, items_want))
	line!(Grade.grade_reals("tp-ifwd  ", item_fwd_got, item_fwd_want, 0.0001))
	Ok({})
}
