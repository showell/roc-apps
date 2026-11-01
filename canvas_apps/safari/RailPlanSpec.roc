# RailPlanSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Frame
import Geom
import Grade
import GuardRail
import RailPlan
import World

steps_got : List(I64)
steps_got = [RailPlan.leg_steps(0.0), RailPlan.leg_steps(0.4), RailPlan.leg_steps(0.5), RailPlan.leg_steps(1.0), RailPlan.leg_steps(1.4), RailPlan.leg_steps(1.5), RailPlan.leg_steps(2.5), RailPlan.leg_steps(10.0), RailPlan.leg_steps(49.6), RailPlan.leg_steps(50.0)]

steps_want : List(I64)
steps_want = [1, 1, 1, 1, 1, 2, 3, 10, 50, 50]

origin_pt : Geom.RiderPt
origin_pt = { right: 0.0, forward: 0.0 }

straight : List(Geom.RiderPt)
straight = RailPlan.push_leg(origin_pt, { right: 0.0, forward: 10.0 })

straight_got : List(F64)
straight_got = [I64.to_f64(straight.len().to_i64_wrap()), (List.get(straight, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(4)) ?? crash ("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(9)) ?? crash ("list-at out of range")).forward, (List.get(straight, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right, (List.get(straight, I64.to_u64_wrap(9)) ?? crash ("list-at out of range")).right]

straight_want : List(F64)
straight_want = [10.0, 1.0, 5.0, 10.0, 0.0, 0.0]

diagonal : List(Geom.RiderPt)
diagonal = RailPlan.push_leg(origin_pt, { right: 30.0, forward: 40.0 })

diagonal_got : List(F64)
diagonal_got = [I64.to_f64(diagonal.len().to_i64_wrap()), (List.get(diagonal, I64.to_u64_wrap(49)) ?? crash ("list-at out of range")).right, (List.get(diagonal, I64.to_u64_wrap(49)) ?? crash ("list-at out of range")).forward, (List.get(diagonal, I64.to_u64_wrap(24)) ?? crash ("list-at out of range")).right, (List.get(diagonal, I64.to_u64_wrap(24)) ?? crash ("list-at out of range")).forward]

diagonal_want : List(F64)
diagonal_want = [50.0, 30.0, 40.0, 15.0, 20.0]

degenerate_got : List(F64)
degenerate_got = (
	{
		d = RailPlan.push_leg({ right: 3.0, forward: 4.0 }, { right: 3.0, forward: 4.0 })
		[I64.to_f64(d.len().to_i64_wrap()), (List.get(d, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).right, (List.get(d, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward]
	}
)

degenerate_want : List(F64)
degenerate_want = [1.0, 3.0, 4.0]

from_zero_got : List(F64)
from_zero_got = (
	{
		z = RailPlan.leg_points(origin_pt, 0.0, 10.0, 10, 0)
		[I64.to_f64(z.len().to_i64_wrap()), (List.get(z, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(z, I64.to_u64_wrap(10)) ?? crash ("list-at out of range")).forward]
	}
)

from_zero_want : List(F64)
from_zero_want = [11.0, 0.0, 10.0]

segs : List(World.Segment)
segs = [World.segment_at(0), World.segment_at(1), World.segment_at(2)]

chain : List(I64)
chain = [0, 1, 2]

origin : Frame.Pose
origin = { along: 0.0, across: 0.0, yaw: 0.0, hw: 2.0 }

runout_got : List(I64)
runout_got = [GuardRail.rail_runout, RailPlan.rail_run_out(segs, chain, origin, Frame.chain_map(0), 4.0, 0).len().to_i64_wrap(), RailPlan.rail_run_up(segs, chain, origin, Frame.chain_map(0), 500.0, 4.0, GuardRail.rail_runout).len().to_i64_wrap()]

runout_want : List(I64)
runout_want = [10, 11, 11]

runup_got : List(F64)
runup_got = (
	{
		u = RailPlan.rail_run_up(segs, chain, origin, Frame.chain_map(0), 500.0, 4.0, GuardRail.rail_runout)
		[(List.get(u, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).forward, (List.get(u, I64.to_u64_wrap(10)) ?? crash ("list-at out of range")).forward]
	}
)

runup_want : List(F64)
runup_want = [490.0, 500.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.ints({
			name: "rp-steps ",
			got: steps_got,
			want: steps_want,
		}),
		Grade.reals({
			name: "rp-straig",
			got: straight_got,
			want: straight_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "rp-diag  ",
			got: diagonal_got,
			want: diagonal_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "rp-degen ",
			got: degenerate_got,
			want: degenerate_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "rp-zero  ",
			got: from_zero_got,
			want: from_zero_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "rp-runout",
			got: runout_got,
			want: runout_want,
		}),
		Grade.reals({
			name: "rp-runup ",
			got: runup_got,
			want: runup_want,
			tol: 0.0001,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
