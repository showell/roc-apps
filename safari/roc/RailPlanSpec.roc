# RailPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Frame
import Geom
import Grade
import GuardRail
import Maybe
import RailPlan
import Scenery
import Tuple
import World

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

steps_got : List(I64)
steps_got = [RailPlan.leg_steps(0.0), RailPlan.leg_steps(0.4), RailPlan.leg_steps(0.5), RailPlan.leg_steps(1.0), RailPlan.leg_steps(1.4), RailPlan.leg_steps(1.5), RailPlan.leg_steps(2.5), RailPlan.leg_steps(10.0), RailPlan.leg_steps(49.6), RailPlan.leg_steps(50.0)]

steps_want : List(I64)
steps_want = [1, 1, 1, 1, 1, 2, 3, 10, 50, 50]

origin_pt : Geom.RiderPt
origin_pt = { right: 0.0, forward: 0.0 }

straight : List(Geom.RiderPt)
straight = RailPlan.push_leg(origin_pt, { right: 0.0, forward: 10.0 })

straight_got : List(F64)
straight_got = [I64.to_f64(U64.to_i64_wrap(List.len(straight))), (List.get(straight, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(4)) ?? crash("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(9)) ?? crash("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(straight, I64.to_u64_wrap(9)) ?? crash("list-at out of range")).right]

straight_want : List(F64)
straight_want = [10.0, 1.0, 5.0, 10.0, 0.0, 0.0]

diagonal : List(Geom.RiderPt)
diagonal = RailPlan.push_leg(origin_pt, { right: 30.0, forward: 40.0 })

diagonal_got : List(F64)
diagonal_got = [I64.to_f64(U64.to_i64_wrap(List.len(diagonal))), (List.get(diagonal, I64.to_u64_wrap(49)) ?? crash("list-at out of range")).right, (List.get(diagonal, I64.to_u64_wrap(49)) ?? crash("list-at out of range")).forward, (List.get(diagonal, I64.to_u64_wrap(24)) ?? crash("list-at out of range")).right, (List.get(diagonal, I64.to_u64_wrap(24)) ?? crash("list-at out of range")).forward]

diagonal_want : List(F64)
diagonal_want = [50.0, 30.0, 40.0, 15.0, 20.0]

degenerate_got : List(F64)
degenerate_got = ({
	d = RailPlan.push_leg({ right: 3.0, forward: 4.0 }, { right: 3.0, forward: 4.0 })
	[I64.to_f64(U64.to_i64_wrap(List.len(d))), (List.get(d, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).right, (List.get(d, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward]
})

degenerate_want : List(F64)
degenerate_want = [1.0, 3.0, 4.0]

from_zero_got : List(F64)
from_zero_got = ({
	z = RailPlan.leg_points(origin_pt, 0.0, 10.0, 10, 0)
	[I64.to_f64(U64.to_i64_wrap(List.len(z))), (List.get(z, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(z, I64.to_u64_wrap(10)) ?? crash("list-at out of range")).forward]
})

from_zero_want : List(F64)
from_zero_want = [11.0, 0.0, 10.0]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

runout_got : List(I64)
runout_got = [GuardRail.rail_runout, U64.to_i64_wrap(List.len(RailPlan.rail_run_out(segs, chain, origin, Frame.chain_map(0), 4.0, 0))), U64.to_i64_wrap(List.len(RailPlan.rail_run_up(segs, chain, origin, Frame.chain_map(0), 500.0, 4.0, GuardRail.rail_runout)))]

runout_want : List(I64)
runout_want = [10, 11, 11]

runup_got : List(F64)
runup_got = ({
	u = RailPlan.rail_run_up(segs, chain, origin, Frame.chain_map(0), 500.0, 4.0, GuardRail.rail_runout)
	[(List.get(u, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).forward, (List.get(u, I64.to_u64_wrap(10)) ?? crash("list-at out of range")).forward]
})

runup_want : List(F64)
runup_want = [490.0, 500.0]

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
	line!(Grade.grade_ints("rp-steps ", steps_got, steps_want))
	line!(Grade.grade_reals("rp-straig", straight_got, straight_want, 0.0))
	line!(Grade.grade_reals("rp-diag  ", diagonal_got, diagonal_want, 0.0))
	line!(Grade.grade_reals("rp-degen ", degenerate_got, degenerate_want, 0.0))
	line!(Grade.grade_reals("rp-zero  ", from_zero_got, from_zero_want, 0.0))
	line!(Grade.grade_ints("rp-runout", runout_got, runout_want))
	line!(Grade.grade_reals("rp-runup ", runup_got, runup_want, 0.0001))
	Ok({})
}
