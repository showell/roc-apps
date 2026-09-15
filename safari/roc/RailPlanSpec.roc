# RailPlanSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Geom
import Grade
import GuardRail
import RailPlan
import Text
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

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_ints([21, 31, 73, 19, 14, 13, 31, 19, 2], steps_got, steps_want)))
	line!(Text.printed(Grade.grade_reals([21, 31, 73, 19, 14, 21, 15, 17, 29], straight_got, straight_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([21, 31, 73, 22, 17, 15, 29, 2, 2], diagonal_got, diagonal_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([21, 31, 73, 22, 13, 29, 13, 18, 2], degenerate_got, degenerate_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([21, 31, 73, 38, 13, 21, 16, 2, 2], from_zero_got, from_zero_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([21, 31, 73, 21, 25, 18, 16, 25, 14], runout_got, runout_want)))
	line!(Text.printed(Grade.grade_reals([21, 31, 73, 21, 25, 18, 25, 31, 2], runup_got, runup_want, 0.0001)))
	Ok({})
}
