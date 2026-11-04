## These are RailPlan's checks: how many steps a leg of rail takes, the
## points along a leg, and the rail's run up to a bend and out of it.
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
steps_got = [0.0, 0.4, 0.5, 1.0, 1.4, 1.5, 2.5, 10.0, 49.6, 50.0].map(RailPlan.leg_steps)

steps_want : List(I64)
steps_want = [1, 1, 1, 1, 1, 2, 3, 10, 50, 50]

origin_pt : Geom.RiderPt
origin_pt = { right: 0.0, forward: 0.0 }

point_at : List(Geom.RiderPt), U64 -> Geom.RiderPt
point_at = |points, i| points.get(i) ?? crash "RailPlanSpec: an index past the leg's end"

straight : List(Geom.RiderPt)
straight = RailPlan.leg({ from: origin_pt, to: { right: 0.0, forward: 10.0 } })

straight_got : List(F64)
straight_got = [
	straight.len().to_f64(),
	point_at(straight, 0).forward,
	point_at(straight, 4).forward,
	point_at(straight, 9).forward,
	point_at(straight, 0).right,
	point_at(straight, 9).right,
]

straight_want : List(F64)
straight_want = [10.0, 1.0, 5.0, 10.0, 0.0, 0.0]

diagonal : List(Geom.RiderPt)
diagonal = RailPlan.leg({ from: origin_pt, to: { right: 30.0, forward: 40.0 } })

diagonal_got : List(F64)
diagonal_got = [
	diagonal.len().to_f64(),
	point_at(diagonal, 49).right,
	point_at(diagonal, 49).forward,
	point_at(diagonal, 24).right,
	point_at(diagonal, 24).forward,
]

diagonal_want : List(F64)
diagonal_want = [50.0, 30.0, 40.0, 15.0, 20.0]

degenerate_got : List(F64)
degenerate_got = {
	in_place = RailPlan.leg({
		from: { right: 3.0, forward: 4.0 },
		to: { right: 3.0, forward: 4.0 },
	})
	[
		in_place.len().to_f64(),
		point_at(in_place, 0).right,
		point_at(in_place, 0).forward,
	]
}

degenerate_want : List(F64)
degenerate_want = [1.0, 3.0, 4.0]

from_zero_got : List(F64)
from_zero_got = {
	spaced = RailPlan.evenly_spaced({
		from: origin_pt,
		to: { right: 0.0, forward: 10.0 },
		steps: 10,
	})
	[
		spaced.len().to_f64(),
		point_at(spaced, 0).forward,
		point_at(spaced, 10).forward,
	]
}

from_zero_want : List(F64)
from_zero_want = [11.0, 0.0, 10.0]

road : RailPlan.Road
road = {
	world: [
		World.segment_at(0),
		World.segment_at(1),
		World.segment_at(2),
	],
	chain: [0, 1, 2],
	pose: {
		along: 0.0,
		across: 0.0,
		yaw: 0.0,
		hw: 2.0,
	},
}

run_up : List(Geom.RiderPt)
run_up = RailPlan.run_up(
	road,
	{
		place: Frame.chain_map(0),
		length: 500.0,
		across: 4.0,
	},
)

runout_got : List(I64)
runout_got = [
	GuardRail.rail_runout,
	RailPlan.run_out(road, { place: Frame.chain_map(0), across: 4.0 }).len().to_i64_wrap(),
	run_up.len().to_i64_wrap(),
]

runout_want : List(I64)
runout_want = [10, 10, 11]

runup_got : List(F64)
runup_got = [point_at(run_up, 0).forward, point_at(run_up, 10).forward]

runup_want : List(F64)
runup_want = [490.0, 500.0]

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
